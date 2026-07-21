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
cleanup() {
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

for wxh in "${resolutions[@]}"; do
    if awww_is_cached "$path" "$wxh"; then
        log "already cached: $(basename "$path") @ $wxh"
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
    hyprctl keyword monitor "$name,${wxh}@60,auto,1" >/dev/null 2>&1 || true
    sleep 1

    log "warming $(basename "$path") @ $wxh via $name"
    if awww img "$path" -o "$name" >/dev/null 2>&1; then
        log "warmed $(basename "$path") @ $wxh"
    else
        log "WARN: awww img failed for $(basename "$path") @ $wxh"
    fi

    remove_err=""
    if ! remove_err="$(hyprctl output remove "$name" 2>&1 >/dev/null)"; then
        # Not retried here: the EXIT/INT/TERM trap unconditionally sweeps
        # every attached headless output, so this one gets removed when the
        # script exits regardless of how this call failed. Logged so a
        # transient hyprctl error is still visible.
        log "WARN: failed to remove $name for $wxh (${remove_err:-no output}); will be swept at exit"
    fi
done
