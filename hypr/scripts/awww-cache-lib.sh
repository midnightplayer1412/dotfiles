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
    compgen -G "${dir}/${key}_*" > /dev/null
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
# No active (non-headless) output, or awww query failing/producing nothing
# (daemon down, transient), is a legitimate empty result: this must always
# exit 0 with empty output, never abort a `set -e` caller. `grep -v` exits 1
# when it selects zero lines, so both the query and the grep stage are
# wrapped to neutralize that under `pipefail`.
awww_active_resolutions() {
    { awww query 2>/dev/null || true; } \
        | { grep -v 'HEADLESS' || true; } \
        | sed -n 's/.*: \([0-9]\+x[0-9]\+\), scale.*/\1/p' \
        | sort -u
}

# ─── Usage journal ────────────────────────────────────────────────────
# Root is mounted relatime and reads do NOT bump atime (verified 2026-07-21),
# so the reaper cannot use atime for LRU. We keep our own journal instead:
# TSV, one "<epoch>\t<key>" line per cache entry, rewritten atomically.

awww_journal_path() {
    printf '%s' "${AWWW_JOURNAL:-${XDG_CACHE_HOME:-$HOME/.cache}/awww-usage.tsv}"
}

# Record "key was used now", replacing any previous line for that key.
awww_journal_touch() {
    local key="$1" jp now tmpf
    jp="$(awww_journal_path)"
    now="$(date +%s)"
    mkdir -p "$(dirname "$jp")"
    tmpf="$jp.tmp.$$"
    { [[ -f "$jp" ]] && grep -vF -- "	$key" "$jp" || true; } > "$tmpf"
    printf '%s\t%s\n' "$now" "$key" >> "$tmpf"
    mv -f "$tmpf" "$jp"
}

# Epoch seconds this key was last used, or 0 when unknown. Unknown entries
# sort oldest, so pre-existing cache files are evicted before tracked ones.
awww_journal_age() {
    local key="$1" jp
    jp="$(awww_journal_path)"
    [[ -f "$jp" ]] || { printf '0'; return; }
    local ts
    ts="$(grep -F -- "	$key" "$jp" | tail -1 | cut -f1)"
    printf '%s' "${ts:-0}"
}

# Touch every existing cache entry belonging to one wallpaper, across all
# resolutions. Keys are the entries' REAL on-disk basenames (which include the
# pixel-format token), because that is exactly what awww-reap.sh looks up.
# Never construct the format token by hand — glob it.
awww_journal_touch_wallpaper() {
    local path="$1" dir f
    dir="$(awww_cache_dir)" || return 0
    for f in "$dir/${path//\//_}__"*; do
        [[ -f "$f" ]] || continue
        awww_journal_touch "$(basename "$f")"
    done
}
