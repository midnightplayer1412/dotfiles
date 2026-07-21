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
# hard-coded — always derive it from the RUNNING daemon (awww_current_format)
# or glob it.
set -euo pipefail

# Pixel-format token used by the RUNNING awww-daemon, e.g. Argb / Bgr.
#
# Why this must be derived and not globbed: the question callers actually ask
# is "will the running daemon HIT this cache entry?", and the daemon only ever
# reads the entry whose token matches its own --format. A leftover _Argb entry
# is dead weight to a --format bgr daemon, so a permissive glob answers
# false-yes and the prefetcher silently no-ops across the whole rotation.
#
# Derived from the daemon's own argv (/proc/<pid>/cmdline) rather than from a
# literal here or from autostart.conf, both of which can disagree with what is
# actually running (e.g. autostart edited but the session not yet restarted).
#
# Exit status is the contract: 0 + token on stdout when the daemon was probed
# successfully; NONZERO when it could not be probed (daemon down, /proc
# unreadable, unrecognized --format value). Callers must fall back to the
# permissive glob on nonzero — fail open, never fail closed, so a missing
# daemon can never make us delete or re-decode a cache that is in fact fine.
#
# A daemon running with NO --format flag maps to Argb: awww's documented
# default ("By default, awww-daemon will use argb" — awww-daemon --help).
#
# AWWW_FORMAT overrides the probe; it exists so the test-suite can pin a
# format deterministically without a daemon. Nothing in the real config sets it.
awww_current_format() {
    local fmt="" found=0

    if [[ -n "${AWWW_FORMAT:-}" ]]; then
        fmt="$AWWW_FORMAT"
        found=1
    else
        local pd argv0
        local -a argv=()
        # AWWW_PROC_ROOT overrides the /proc root the scan globs under; it
        # exists so the test-suite can fabricate cmdline fixtures under a temp
        # dir and exercise this argv parser deterministically, without a real
        # daemon. Nothing in the real config sets it.
        for pd in "${AWWW_PROC_ROOT:-/proc}"/[0-9]*; do
            [[ -r "$pd/cmdline" ]] || continue
            argv=()
            # `mapfile -d ''` splits the NUL-separated cmdline into argv.
            # A process exiting between the glob and the read makes this fail;
            # that is routine, not an error, hence the guard (this file is
            # sourced into `set -euo pipefail` scripts). stderr is silenced
            # BEFORE the input redirect is attempted (redirections apply
            # left-to-right), so a process that exits in the TOCTOU window
            # between the `-r` test and this read can't leak bash's
            # "No such file or directory" onto the caller's stderr.
            mapfile -d '' -t argv 2>/dev/null < "$pd/cmdline" || continue
            (( ${#argv[@]} > 0 )) || continue
            argv0="${argv[0]##*/}"
            [[ "$argv0" == "awww-daemon" ]] || continue
            found=1
            local i
            for ((i = 1; i < ${#argv[@]}; i++)); do
                case "${argv[i]}" in
                    -f|--format) fmt="${argv[i+1]:-}"; break ;;
                    --format=*)  fmt="${argv[i]#--format=}"; break ;;
                    -f=*)        fmt="${argv[i]#-f=}"; break ;;
                esac
            done
            break
        done
    fi

    (( found )) || return 1

    case "${fmt,,}" in
        bgr)     printf 'Bgr'  ;;
        abgr)    printf 'Abgr' ;;
        rgb)     printf 'Rgb'  ;;
        argb|'') printf 'Argb' ;;   # no flag == awww's documented default
        # An unrecognized value means our mapping is out of date with awww.
        # Report "cannot determine" so callers fall back to the permissive
        # glob, rather than confidently asserting a token that is wrong.
        *)       return 1 ;;
    esac
}

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

# Exit 0 if a cache entry exists that the RUNNING daemon will actually hit
# for this wallpaper at this resolution.
#
# Format-exact by design: an entry in a foreign pixel format is unreadable to
# the current daemon, so reporting it as "cached" would make the prefetcher
# skip a wallpaper that still cold-decodes on display. When the daemon cannot
# be probed at all we fall back to the old permissive glob — fail open.
# Usage: awww_is_cached <abs-path> <WxH> [resize=crop]
awww_is_cached() {
    local dir key fmt
    dir="$(awww_cache_dir)" || return 1
    key="$(awww_cache_key "$1" "$2" "${3:-crop}")"
    if fmt="$(awww_current_format)"; then
        [[ -f "${dir}/${key}_${fmt}" ]]
    else
        compgen -G "${dir}/${key}_*" > /dev/null
    fi
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
#
# The read-filter-append-rename cycle is serialized with `flock` on a
# sidecar lock file: `mv -f` only makes the final swap atomic, not the
# read+filter that precedes it, so two concurrent callers could otherwise
# both read the same prior state and the second `mv -f` would silently
# discard the first's update (lost-update race). The lock is scoped to a
# subshell so it is released the instant that subshell exits, even on
# error — nothing here can deadlock (single non-reentrant lock, never
# taken recursively: awww_journal_touch_wallpaper calls this in a plain
# sequential loop, one touch fully completing before the next begins) or
# leak (no lock is held past the subshell's lifetime).
#
# Matching uses awk on the exact second TSV field, not `grep -F`, because
# a substring match would also hit any OTHER key that contains this key as
# a substring (e.g. touching "key-one" must never filter out or attribute
# its timestamp to "key-one-two") — see awww_journal_age for the same
# concern on the read side.
awww_journal_touch() {
    local key="$1" jp now tmpf lockf
    jp="$(awww_journal_path)"
    now="$(date +%s)"
    mkdir -p "$(dirname "$jp")"
    tmpf="$jp.tmp.$$"
    lockf="$jp.lock"
    (
        flock -x 200
        { [[ -f "$jp" ]] && awk -F'\t' -v k="$key" '$2 != k' "$jp" || true; } > "$tmpf"
        printf '%s\t%s\n' "$now" "$key" >> "$tmpf"
        mv -f "$tmpf" "$jp"
    ) 200>"$lockf"
}

# Epoch seconds this key was last used, or 0 when unknown. Unknown entries
# sort oldest, so pre-existing cache files are evicted before tracked ones.
#
# Matching uses awk on the exact second TSV field (see awww_journal_touch)
# so a key that is a PREFIX of another key's line is never confused with
# it via substring matching. The `awk | tail` pipeline always exits 0 even
# when zero lines match (awk simply prints nothing; tail on empty input is
# still success), so this is safe to call directly under `set -e` without
# wrapping it in `$(...)` — unlike `grep -F`, which exits 1 on no match and
# would abort the calling shell under `pipefail` on the unknown-key path.
awww_journal_age() {
    local key="$1" jp
    jp="$(awww_journal_path)"
    [[ -f "$jp" ]] || { printf '0'; return; }
    local ts
    ts="$(awk -F'\t' -v k="$key" '$2 == k { print $1 }' "$jp" | tail -1)"
    printf '%s' "${ts:-0}"
}

# Touch every CURRENT-FORMAT cache entry belonging to one wallpaper, across
# all resolutions. Keys are the entries' REAL on-disk basenames (which include
# the pixel-format token), because that is exactly what awww-reap.sh looks up.
# The token is derived from the running daemon, never constructed by hand.
#
# Restricted to the current format on purpose: an unrestricted glob stamps
# `now` on foreign-format entries too, which are pure dead weight. That would
# sort them MOST-recently-used and evict them LAST, so the reaper would drop
# live entries of less-recently-shown wallpapers first and converge on a cache
# that is roughly half unusable — a permanently halved effective cap. When the
# daemon can't be probed we touch everything, as before (fail open).
awww_journal_touch_wallpaper() {
    local path="$1" dir f fmt suffix=""
    dir="$(awww_cache_dir)" || return 0
    if fmt="$(awww_current_format)"; then suffix="_$fmt"; fi
    for f in "$dir/${path//\//_}__"*"$suffix"; do
        [[ -f "$f" ]] || continue
        awww_journal_touch "$(basename "$f")"
    done
}
