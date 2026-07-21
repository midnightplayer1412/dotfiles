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

# A crash mid-prefetch leaves a headless output attached. Remove any that
# exist at startup — we never keep one across invocations.
reap_orphans() {
    local n
    for n in $(headless_names); do
        log "removing orphan headless output $n"
        hyprctl output remove "$n" >/dev/null 2>&1 || true
    done
}

if [[ "${1:-}" == "--reap-orphans" ]]; then reap_orphans; exit 0; fi

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
    hyprctl output create headless >/dev/null 2>&1 || { log "output create failed"; continue; }
    sleep 1
    after="$(headless_names)"
    # hyprctl output create prints only "ok" — recover the name by diffing
    # the headless set before/after. A plain diff (not a substring match)
    # so a stray already-attached HEADLESS-N is never mistaken for ours.
    name="$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | head -1)"
    if [[ -z "$name" ]]; then
        log "could not determine new headless output name; aborting this warm"
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

    hyprctl output remove "$name" >/dev/null 2>&1 || log "WARN: failed to remove $name"
done
