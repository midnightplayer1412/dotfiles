#!/usr/bin/env bash
# awww-reap.sh — bound the awww frame cache to a byte cap using LRU order
# from our own usage journal (atime is unusable: root is relatime).
#
# Usage: awww-reap.sh <cap_bytes> [protect_abs_path ...]
#
# Protected paths are the currently-displayed wallpaper and everything in the
# lookahead queue — evicting those would guarantee the stall we are trying to
# avoid. The cap may legitimately be exceeded if protected entries alone
# exceed it; that is logged, not thrashed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/awww-cache-lib.sh"

cap="${1:-0}"
shift || true

# Build the protected-key prefix list: an entry is protected if its filename
# starts with the slash-mangled wallpaper path.
protected=()
for p in "$@"; do protected+=("${p//\//_}__"); done

is_protected() {
    local base="$1" pref
    for pref in "${protected[@]:-}"; do
        [[ -n "$pref" && "$base" == "$pref"* ]] && return 0
    done
    return 1
}

total=0
declare -a rows=()
while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    sz=$(stat -c %s "$f")
    total=$((total + sz))
    base="$(basename "$f")"
    rows+=("$(awww_journal_age "$base")	$sz	$f")
done < <(awww_frame_entries)

if (( total <= cap )); then
    printf 'awww-reap: %d bytes ≤ cap %d, nothing to do\n' "$total" "$cap" >&2
    exit 0
fi

freed=0; removed=0; skipped=0
# Oldest first; ties broken by largest, so a big stale entry goes before a
# small one of the same age.
while IFS=$'\t' read -r _ts sz f; do
    (( total <= cap )) && break
    if is_protected "$(basename "$f")"; then skipped=$((skipped + 1)); continue; fi
    rm -f "$f" && total=$((total - sz)) && freed=$((freed + sz)) && removed=$((removed + 1))
done < <(printf '%s\n' "${rows[@]}" | sort -t$'\t' -k1,1n -k2,2nr)

printf 'awww-reap: removed %d entries, freed %d bytes, %d protected, now %d (cap %d)\n' \
    "$removed" "$freed" "$skipped" "$total" "$cap" >&2

(( total > cap )) && printf 'awww-reap: WARNING still over cap — protected entries exceed it\n' >&2
exit 0
