#!/usr/bin/env bash
# awww-cache-lib.sh — shared helpers for inspecting and managing the awww
# frame cache. Sourced by awww-prefetch.sh and awww-reap.sh; not executable
# on its own.
#
# Cache layout (awww 0.12.0), verified 2026-07-21:
#   ~/.cache/awww/<version>/<abs-path-with-/-as-_>__<WxH>_<resize>_<Format>
#   e.g. _home_jp_dotfiles_wallpapers_live-16.gif__2560x1440_crop_Argb
# File body is [u32 LE frame_count][LZ4 frames].
#
# The <Format> token depends on awww-daemon --format and must never be
# hard-coded — always glob it.
set -euo pipefail

# Absolute path of the versioned cache dir. Picks the newest if several
# versions coexist (an awww upgrade leaves the old dir behind).
awww_cache_dir() {
    local root="${XDG_CACHE_HOME:-$HOME/.cache}/awww"
    [[ -d "$root" ]] || return 1
    local newest
    newest="$(find "$root" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)"
    [[ -n "$newest" ]] || return 1
    printf '%s' "$newest"
}

# Cache key WITHOUT the trailing _<Format> segment, so callers can glob it.
# Usage: awww_cache_key <abs-path> <WxH> [resize=crop]
awww_cache_key() {
    local path="$1" wxh="$2" resize="${3:-crop}"
    printf '%s__%s_%s' "${path//\//_}" "$wxh" "$resize"
}

# Exit 0 if a cache entry exists for this wallpaper at this resolution,
# regardless of pixel format.
# Usage: awww_is_cached <abs-path> <WxH> [resize=crop]
awww_is_cached() {
    local dir key
    dir="$(awww_cache_dir)" || return 1
    key="$(awww_cache_key "$1" "$2" "${3:-crop}")"
    compgen -G "${dir}/${key}_*" > /dev/null || return 1
}

# Every frame-cache entry, absolute paths, one per line.
# Entries containing "__" are frame caches; the small per-output files
# (eDP-2, HDMI-A-1) are awww's restore cache and MUST NOT be touched.
awww_frame_entries() {
    local dir
    dir="$(awww_cache_dir)" || return 0
    find "$dir" -maxdepth 1 -type f -name '*__*' 2>/dev/null
}

# Distinct resolutions of the REAL outputs, one WxH per line.
# Headless outputs are excluded — they are our own scratch surfaces.
awww_active_resolutions() {
    awww query 2>/dev/null \
        | grep -v 'HEADLESS' \
        | sed -n 's/.*: \([0-9]\+x[0-9]\+\), scale.*/\1/p' \
        | sort -u
}
