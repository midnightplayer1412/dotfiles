#!/usr/bin/env bash
# test-awww-reap.sh — fixture tests for awww-reap.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAP="$SCRIPT_DIR/awww-reap.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export XDG_CACHE_HOME="$tmp/cache"
export AWWW_JOURNAL="$tmp/usage.tsv"
# Fixtures are kilobyte-scale, so lower the reaper's 1 GiB sanity floor.
# The floor itself is exercised deliberately further down, with this unset.
export AWWW_REAP_MIN_CAP=1
# Pin the daemon pixel format so these tests never depend on what is running
# on the developer's machine.
export AWWW_FORMAT=argb
cd_dir="$XDG_CACHE_HOME/awww/0.12.0"
mkdir -p "$cd_dir"

fail=0
mk() {  # mk <name> <size_bytes> <journal_epoch|->
    dd if=/dev/zero of="$cd_dir/$1" bs=1 count="$2" status=none
    [[ "$3" == "-" ]] || printf '%s\t%s\n' "$3" "$1" >> "$AWWW_JOURNAL"
}

# Three 1000-byte entries with increasing recency, plus a restore file.
mk "_w_old.gif__100x100_crop_Argb"   1000 1000
mk "_w_mid.gif__100x100_crop_Argb"   1000 2000
mk "_w_new.gif__100x100_crop_Argb"   1000 3000
mk "eDP-2" 54 -

# Cap of 2500 bytes must evict exactly the oldest entry.
"$REAP" 2500 >/dev/null 2>&1

[[ -f "$cd_dir/_w_old.gif__100x100_crop_Argb" ]] && { echo "FAIL: oldest not evicted" >&2; fail=1; }
[[ -f "$cd_dir/_w_mid.gif__100x100_crop_Argb" ]] || { echo "FAIL: mid wrongly evicted" >&2; fail=1; }
[[ -f "$cd_dir/_w_new.gif__100x100_crop_Argb" ]] || { echo "FAIL: newest wrongly evicted" >&2; fail=1; }
[[ -f "$cd_dir/eDP-2" ]] || { echo "FAIL: restore file must never be touched" >&2; fail=1; }

# Protect list wins even when the entry is oldest.
mk "_w_prot.gif__100x100_crop_Argb" 1000 500
"$REAP" 1000 /w/prot.gif >/dev/null 2>&1
[[ -f "$cd_dir/_w_prot.gif__100x100_crop_Argb" ]] || { echo "FAIL: protected entry was evicted" >&2; fail=1; }

# Untracked entries (absent from journal) are evicted before tracked ones.
rm -f "$cd_dir"/*__* ; : > "$AWWW_JOURNAL"
mk "_w_untracked.gif__100x100_crop_Argb" 1000 -
mk "_w_tracked.gif__100x100_crop_Argb"   1000 1000
"$REAP" 1000 >/dev/null 2>&1
[[ -f "$cd_dir/_w_untracked.gif__100x100_crop_Argb" ]] && { echo "FAIL: untracked should evict first" >&2; fail=1; }
[[ -f "$cd_dir/_w_tracked.gif__100x100_crop_Argb" ]] || { echo "FAIL: tracked wrongly evicted" >&2; fail=1; }

# Regression for Finding 1: a file that vanishes between the `-f` check and
# the `stat` call (concurrent reap/prefetch/daemon touching the live cache)
# must be skipped, not abort the whole script. Shim `stat` to delete its
# target right before actually running it, reproducing the TOCTOU race.
rm -f "$cd_dir"/*__* ; : > "$AWWW_JOURNAL"
mk "_w_vanish.gif__100x100_crop_Argb" 1000 1000
mk "_w_keep.gif__100x100_crop_Argb"   1000 5000
victim="$cd_dir/_w_vanish.gif__100x100_crop_Argb"
stat_shim_dir="$tmp/stat-shim"
mkdir -p "$stat_shim_dir"
cat > "$stat_shim_dir/stat" <<EOF
#!/usr/bin/env bash
if [[ "\$*" == *"$victim"* ]]; then
    rm -f "$victim"
fi
exec /usr/bin/stat "\$@"
EOF
chmod +x "$stat_shim_dir/stat"
set +e
PATH="$stat_shim_dir:$PATH" "$REAP" 1500 >/dev/null 2>&1
rc=$?
set -e
[[ $rc -eq 0 ]] || { echo "FAIL: vanishing file mid-stat must not abort the script (rc=$rc)" >&2; fail=1; }
[[ -f "$cd_dir/_w_keep.gif__100x100_crop_Argb" ]] || { echo "FAIL: keep entry wrongly evicted after vanished-file race" >&2; fail=1; }

# All-protected-over-cap: protected entries alone exceed the cap. Must warn
# and stop, never delete a protected entry, and still exit 0 (Finding 2).
rm -f "$cd_dir"/*__* ; : > "$AWWW_JOURNAL"
mk "_w_protA.gif__100x100_crop_Argb" 1000 1000
mk "_w_protB.gif__100x100_crop_Argb" 1000 2000
set +e
out="$("$REAP" 500 /w/protA.gif /w/protB.gif 2>&1 >/dev/null)"
rc=$?
set -e
[[ $rc -eq 0 ]] || { echo "FAIL: all-protected-over-cap must exit 0 (got $rc)" >&2; fail=1; }
[[ -f "$cd_dir/_w_protA.gif__100x100_crop_Argb" ]] || { echo "FAIL: protA wrongly evicted while fully protected" >&2; fail=1; }
[[ -f "$cd_dir/_w_protB.gif__100x100_crop_Argb" ]] || { echo "FAIL: protB wrongly evicted while fully protected" >&2; fail=1; }
printf '%s\n' "$out" | grep -q 'WARNING still over cap' || { echo "FAIL: expected still-over-cap warning when protected entries alone exceed it" >&2; fail=1; }

# Tie-break ordering: identical journal age must evict largest-first
# (sort -t$'\t' -k1,1n -k2,2nr). Cap chosen so evicting the larger entry
# alone clears the cap, but evicting the smaller alone would not.
rm -f "$cd_dir"/*__* ; : > "$AWWW_JOURNAL"
mk "_w_tie_small.gif__100x100_crop_Argb" 1000 5000
mk "_w_tie_large.gif__100x100_crop_Argb" 2000 5000
"$REAP" 1500 >/dev/null 2>&1
[[ -f "$cd_dir/_w_tie_small.gif__100x100_crop_Argb" ]] || { echo "FAIL: tie-break evicted the smaller same-age entry first" >&2; fail=1; }
[[ -f "$cd_dir/_w_tie_large.gif__100x100_crop_Argb" ]] && { echo "FAIL: tie-break should evict the larger same-age entry first" >&2; fail=1; }

# ── Fix 2 regression: foreign-format entries are evicted before journaled
#    current-format ones. `_w_stale` is in the WRONG format but has the most
#    recent journal timestamp there is; `_w_live` is in the daemon's format
#    and is journalled much older. Plain LRU would evict _w_live and keep the
#    unusable _w_stale forever — the "cache half dead weight, effective cap
#    permanently halved" failure. Format-forced age 0 must invert that. ──
rm -f "$cd_dir"/*__* ; : > "$AWWW_JOURNAL"
mk "_w_stale.gif__100x100_crop_Bgr"  1000 9999
mk "_w_live.gif__100x100_crop_Argb"  1000 1000
"$REAP" 1000 >/dev/null 2>&1
[[ -f "$cd_dir/_w_stale.gif__100x100_crop_Bgr" ]] && { echo "FAIL: foreign-format entry survived despite being most-recently-journaled — it must always evict first" >&2; fail=1; }
[[ -f "$cd_dir/_w_live.gif__100x100_crop_Argb" ]] || { echo "FAIL: current-format entry evicted before a foreign-format one" >&2; fail=1; }

# Same shape, opposite daemon format, to prove the rule follows the daemon
# rather than favouring the literal string "Argb".
rm -f "$cd_dir"/*__* ; : > "$AWWW_JOURNAL"
mk "_w_stale.gif__100x100_crop_Argb" 1000 9999
mk "_w_live.gif__100x100_crop_Bgr"   1000 1000
AWWW_FORMAT=bgr "$REAP" 1000 >/dev/null 2>&1
[[ -f "$cd_dir/_w_stale.gif__100x100_crop_Argb" ]] && { echo "FAIL: Argb entry survived under a bgr daemon" >&2; fail=1; }
[[ -f "$cd_dir/_w_live.gif__100x100_crop_Bgr" ]] || { echo "FAIL: Bgr entry evicted under a bgr daemon" >&2; fail=1; }

# Unprobeable daemon: make no format judgements at all, fall back to pure
# journal LRU. Guards against fixing the stale-entry bug by failing closed.
rm -f "$cd_dir"/*__* ; : > "$AWWW_JOURNAL"
mk "_w_recent.gif__100x100_crop_Bgr" 1000 9999
mk "_w_older.gif__100x100_crop_Argb" 1000 1000
# An unrecognized format value makes awww_current_format report "cannot
# determine", which is the same code path as a daemon that isn't running.
AWWW_FORMAT=zzz-not-a-format "$REAP" 1000 >/dev/null 2>&1
[[ -f "$cd_dir/_w_recent.gif__100x100_crop_Bgr" ]] || { echo "FAIL: unprobeable daemon must fall back to journal LRU and keep the most recent entry" >&2; fail=1; }
[[ -f "$cd_dir/_w_older.gif__100x100_crop_Argb" ]] && { echo "FAIL: unprobeable daemon must evict the journal-oldest entry" >&2; fail=1; }

# ── Fix 8 regression: an invalid cap must delete NOTHING and exit nonzero.
#    Each of these previously either deleted the whole cache (0, from a
#    truncated 0.5 GB) or died with a bare `unbound variable`. ──
check_cap_rejected() {  # check_cap_rejected <label> <env-min-cap|-> <cap-arg>
    local label="$1" minc="$2" capv="$3" rc out
    rm -f "$cd_dir"/*__* ; : > "$AWWW_JOURNAL"
    mk "_w_keepme.gif__100x100_crop_Argb" 1000 1000
    set +e
    if [[ "$minc" == "-" ]]; then
        out="$(env -u AWWW_REAP_MIN_CAP "$REAP" "$capv" 2>&1 >/dev/null)"
    else
        out="$(AWWW_REAP_MIN_CAP="$minc" "$REAP" "$capv" 2>&1 >/dev/null)"
    fi
    rc=$?
    set -e
    (( rc != 0 )) || { echo "FAIL: $label cap [$capv] must exit nonzero, got 0" >&2; fail=1; }
    [[ -f "$cd_dir/_w_keepme.gif__100x100_crop_Argb" ]] \
        || { echo "FAIL: $label cap [$capv] deleted cache entries — validation must precede any rm" >&2; fail=1; }
    printf '%s\n' "$out" | grep -q 'FATAL' \
        || { echo "FAIL: $label cap [$capv] must say so loudly on stderr, got [$out]" >&2; fail=1; }
}

# A QML `property int` receiving cacheCapGb: 0.5 truncates to 0, and 0 bytes
# reaches us as a well-formed instruction to delete everything unprotected.
check_cap_rejected "zero"         1 0
# Fractional byte counts are never legitimate.
check_cap_rejected "fractional"   1 0.5
# Previously died with `abc: unbound variable` — fail-safe but silent.
check_cap_rejected "non-numeric"  1 abc
check_cap_rejected "empty"        1 ""
check_cap_rejected "negative"     1 -5
# And with the real production floor in force, a sub-1-GiB cap is refused
# even though it is a perfectly well-formed integer.
check_cap_rejected "below-floor"  - 1000

# A cap at or above the floor still works normally (the floor must not have
# broken the happy path).
rm -f "$cd_dir"/*__* ; : > "$AWWW_JOURNAL"
mk "_w_small.gif__100x100_crop_Argb" 1000 1000
set +e
env -u AWWW_REAP_MIN_CAP "$REAP" $((1024 * 1024 * 1024)) >/dev/null 2>&1
rc=$?
set -e
[[ $rc -eq 0 ]] || { echo "FAIL: a 1 GiB cap must be accepted (got rc=$rc)" >&2; fail=1; }
[[ -f "$cd_dir/_w_small.gif__100x100_crop_Argb" ]] || { echo "FAIL: under-cap entry wrongly evicted" >&2; fail=1; }

if [[ $fail -eq 0 ]]; then echo "PASS: awww-reap.sh"; else echo "TESTS FAILED" >&2; exit 1; fi
