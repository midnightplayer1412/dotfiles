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

if [[ $fail -eq 0 ]]; then echo "PASS: awww-reap.sh"; else echo "TESTS FAILED" >&2; exit 1; fi
