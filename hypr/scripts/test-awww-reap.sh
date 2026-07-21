#!/usr/bin/env bash
# test-awww-reap.sh — fixture tests for awww-reap.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAP="$SCRIPT_DIR/awww-reap.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export XDG_CACHE_HOME="$tmp/cache"
export AWWW_JOURNAL="$tmp/usage.tsv"
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

if [[ $fail -eq 0 ]]; then echo "PASS: awww-reap.sh"; else echo "TESTS FAILED" >&2; exit 1; fi
