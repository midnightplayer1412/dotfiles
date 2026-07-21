#!/usr/bin/env bash
# awww-prefetch.sh — warm the awww frame cache for a wallpaper WITHOUT
# displaying it, by decoding against a transient Hyprland headless output.
#
# Usage:
#   awww-prefetch.sh <wallpaper_abs_path> [WxH ...]
#   awww-prefetch.sh --reap-orphans
#
# Why this exists: awww has no `precache` subcommand, and applying to a
# nonexistent output fails BEFORE decoding ("none of the requested outputs
# are valid"), so it writes nothing. A headless output is a real output as
# far as awww is concerned, but has no panel behind it — decoding against it
# populates the cache invisibly. Its resolution is declared, not detected,
# so we can warm 2560x1440 entries while only 1080p monitors are attached.
#
# Decoding is CPU-bound (~16 frames/sec, i.e. 74s for a 1201-frame GIF), so
# callers must serialize: never run two of these at once.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/awww-cache-lib.sh"

log() { printf 'awww-prefetch: %s\n' "$*" >&2; }

# Names of currently attached headless outputs, one per line, sorted.
# No headless outputs attached (the common case) means the inner grep
# selects zero lines and exits 1; under `pipefail` that would propagate and,
# because callers use this in a plain assignment (`x="$(headless_names)"`),
# `set -e` would abort the whole script on the very first run. The trailing
# `|| true` neutralizes that — an empty result is not a failure here.
headless_names() {
    hyprctl monitors -j 2>/dev/null \
        | grep -oE '"name": "HEADLESS-[0-9]+"' \
        | grep -oE 'HEADLESS-[0-9]+' \
        | sort -u || true
}

# A crash, an interrupted signal, or any error mid-prefetch can leave a
# headless output attached. Called automatically at the start of every
# invocation (below) and again via the EXIT/INT/TERM trap (below), so a
# leaked output is removed within the run that leaked it — or, in the
# SIGKILL case that no trap can catch, self-heals on the very next
# invocation — instead of persisting until someone manually runs
# --reap-orphans.
reap_orphans() {
    local n
    for n in $(headless_names); do
        log "removing orphan headless output $n"
        hyprctl output remove "$n" >/dev/null 2>&1 || true
    done
}

# Unconditional sweep of every attached headless output, regardless of why
# we're exiting: normal completion, an uncaught error under `set -e`,
# Ctrl-C (INT), or a caller's timeout/logout (TERM). This is what actually
# closes the create->remove window described in the file header, including
# the narrow gap before we've even determined the new output's name.
#
# Safe to sweep ALL headless outputs (not just "ours"): this script's own
# contract is "callers must serialize: never run two of these at once" (see
# header), so nothing else can legitimately have a headless output attached
# while this process is alive. A concurrent second instance is excluded by
# contract, not merely assumed — if it happened, the before/after name
# diffing below would already be broken by the race, independent of this
# trap.
# Cache key of a decode that is in flight right now, or "" when none is.
# awww writes its cache entry IN PLACE — there is no .tmp/.part convention —
# so an interrupted decode leaves a truncated file that awww_is_cached happily
# reports as a hit forever after. That wallpaper would then stall on every
# single display and prefetch would never re-warm it. Discarding the partial
# entry is what keeps "cached" meaning "complete".
inflight_key=""

# Remove every cache entry for one key (all pixel formats — we are deleting
# OUR OWN wreckage here, so the permissive glob is correct: whatever awww
# managed to write under this key is suspect regardless of its format token).
discard_partial() {
    local key="$1" dir f
    [[ -n "$key" ]] || return 0
    dir="$(awww_cache_dir)" || return 0
    for f in "$dir/${key}_"*; do
        # Empty globs expand to the literal pattern; the -f test filters that.
        # Written as a full `if` rather than `[[ ... ]] && rm`, because a
        # trailing failed && list is the loop body's exit status and would
        # abort this script under `set -e`.
        if [[ -f "$f" ]]; then
            log "discarding partial cache entry $(basename "$f")"
            rm -f "$f" || true
        fi
    done
}

cleanup() {
    # Ctrl-C / SIGTERM / an errexit abort mid-`awww img` all land here with a
    # half-written entry on disk. Reachable in normal use: quickshell being
    # reloaded mid-decode is routine on this machine, and a 300s decode is a
    # wide window to be reloaded in.
    discard_partial "$inflight_key"
    reap_orphans
}
trap cleanup EXIT
# EXIT trap above still fires when a trapped signal calls `exit` — that's
# the whole point, so cleanup runs exactly once no matter which path out.
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ "${1:-}" == "--reap-orphans" ]]; then reap_orphans; exit 0; fi

# Self-heal: sweep any output left by a previous run that couldn't clean up
# after itself (e.g. SIGKILL, which no trap can catch). Safe under the same
# serialization contract as the trap above.
reap_orphans

path="${1:-}"
[[ -n "$path" && -f "$path" ]] || { log "usage: awww-prefetch.sh <abs-path> [WxH ...]"; exit 2; }
# Only GIFs are ever cached by awww — static images cost nothing (verified:
# 69 GIF entries, 0 jpg/png entries).
[[ "${path,,}" == *.gif ]] || exit 0

shift || true
resolutions=("$@")
if (( ${#resolutions[@]} == 0 )); then
    mapfile -t resolutions < <(awww_active_resolutions)
fi
(( ${#resolutions[@]} > 0 )) || { log "no active resolutions, nothing to warm"; exit 0; }

# Set once any resolution ends up with a complete, usable entry — whether we
# warmed it just now or found it already cached. Drives the journal touch at
# the end; see there for why.
have_usable=0

for wxh in "${resolutions[@]}"; do
    if awww_is_cached "$path" "$wxh"; then
        log "already cached: $(basename "$path") @ $wxh"
        have_usable=1
        continue
    fi

    before="$(headless_names)"
    create_err=""
    if ! create_err="$(hyprctl output create headless 2>&1 >/dev/null)"; then
        log "output create failed for $wxh (${create_err:-no output})"
        continue
    fi
    sleep 1
    after="$(headless_names)"
    # hyprctl output create prints only "ok" — recover the name by diffing
    # the headless set before/after. A plain diff (not a substring match)
    # so a stray already-attached HEADLESS-N is never mistaken for ours.
    name="$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | head -1)"
    if [[ -z "$name" ]]; then
        # The output WAS created (we passed the `output create` check above)
        # but we failed to identify its name, so we cannot target a removal
        # at it specifically. Sweep every attached headless output instead —
        # under the caller's one-at-a-time serialization guarantee, nothing
        # else should legitimately be using one right now — so we never
        # leave the output we just created stranded.
        log "could not determine new headless output name; sweeping headless outputs"
        reap_orphans
        continue
    fi

    # Force the resolution — the headless default is 1920x1080. This keyword
    # is runtime-only and is not written to hyprland.conf.
    #
    # NOT swallowed: if this fails, awww decodes at 1920x1080 while we log
    # that we warmed at $wxh. That burns 74-300s of CPU producing an entry
    # under the WRONG resolution key — which then also satisfies
    # awww_is_cached for that wrong resolution, so we never revisit it.
    # Skipping the resolution loudly is strictly better than caching a lie.
    # hyprctl prints "ok" on success and a message on failure, and does not
    # always signal failure through its exit status, so we check both.
    kw_out=""
    if ! kw_out="$(hyprctl keyword monitor "$name,${wxh}@60,auto,1" 2>&1)" \
       || [[ "$kw_out" != *ok* ]]; then
        log "WARN: could not force $name to $wxh (${kw_out:-no output}); skipping $wxh rather than caching a wrong-resolution entry"
        hyprctl output remove "$name" >/dev/null 2>&1 || true
        continue
    fi
    sleep 1

    log "warming $(basename "$path") @ $wxh via $name"
    # Publish the key BEFORE decoding starts, so an INT/TERM/errexit exit
    # mid-decode finds it in the trap and discards the truncated entry.
    inflight_key="$(awww_cache_key "$path" "$wxh")"
    if awww img "$path" -o "$name" >/dev/null 2>&1; then
        log "warmed $(basename "$path") @ $wxh"
        have_usable=1
    else
        log "WARN: awww img failed for $(basename "$path") @ $wxh"
        discard_partial "$inflight_key"
    fi
    inflight_key=""

    remove_err=""
    if ! remove_err="$(hyprctl output remove "$name" 2>&1 >/dev/null)"; then
        # Not retried here: the EXIT/INT/TERM trap unconditionally sweeps
        # every attached headless output, so this one gets removed when the
        # script exits regardless of how this call failed. Logged so a
        # transient hyprctl error is still visible.
        log "WARN: failed to remove $name for $wxh (${remove_err:-no output}); will be swept at exit"
    fi
done

# Journal the entries we just confirmed usable.
#
# Without this, an entry that cost up to 300s to decode carries journal age 0
# — the OLDEST possible — and so is the reaper's very first victim. It used to
# survive only by sitting in the QML _queue's protect list, but it leaves that
# list on setCycleOrder() and on every quickshell restart (the queue is not
# persisted), so each reload silently discarded up to four wallpapers of
# prefetch work. Touching here makes "we just spent CPU on this" the LRU fact
# it always should have been.
if (( have_usable )); then
    awww_journal_touch_wallpaper "$path"
fi
