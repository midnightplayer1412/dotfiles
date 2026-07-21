#!/usr/bin/env bash
# test-awww-cache.sh — fixture tests for awww-cache-lib.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/awww-cache-lib.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail=0
assert_eq() {
  if [[ "$1" != "$2" ]]; then
    echo "FAIL: expected [$2] got [$1]" >&2
    fail=1
  fi
}

# --- key derivation: slashes become underscores, hyphens preserved ---
assert_eq "$(awww_cache_key /home/jp/dotfiles/wallpapers/live-16.gif 2560x1440)" \
          "_home_jp_dotfiles_wallpapers_live-16.gif__2560x1440_crop"
assert_eq "$(awww_cache_key /tmp/a-b/c.gif 1920x1080)" \
          "_tmp_a-b_c.gif__1920x1080_crop"
# --- non-default resize mode ---
assert_eq "$(awww_cache_key /x/y.gif 800x600 fit)" "_x_y.gif__800x600_fit"

# --- cache dir discovery picks the versioned subdir ---
export XDG_CACHE_HOME="$tmp/cache"
mkdir -p "$XDG_CACHE_HOME/awww/0.12.0"
assert_eq "$(awww_cache_dir)" "$XDG_CACHE_HOME/awww/0.12.0"

# --- multi-version discovery: lexicographic vs semantic versioning ---
# Create versions where sort -V differs from plain sort (0.9.0 sorts last
# lexicographically, but 0.12.0 is the semantic newest)
rm -rf "$XDG_CACHE_HOME/awww"
mkdir -p "$XDG_CACHE_HOME/awww"/{0.2.1,0.9.0,0.12.0}
assert_eq "$(awww_cache_dir)" "$XDG_CACHE_HOME/awww/0.12.0"

# --- current_format is DERIVED, never hard-coded ---
# A daemon started with no --format flag uses awww's documented default.
assert_eq "$(AWWW_FORMAT='' awww_current_format || echo UNPROBEABLE)" "Argb"
assert_eq "$(AWWW_FORMAT=bgr  awww_current_format)" "Bgr"
assert_eq "$(AWWW_FORMAT=abgr awww_current_format)" "Abgr"
assert_eq "$(AWWW_FORMAT=rgb  awww_current_format)" "Rgb"
assert_eq "$(AWWW_FORMAT=argb awww_current_format)" "Argb"
# An unrecognized value must report "cannot determine" (nonzero), not guess.
if AWWW_FORMAT=weirdfmt awww_current_format >/dev/null 2>&1; then
  echo "FAIL: current_format must fail on an unrecognized format value" >&2; fail=1
fi

# --- is_cached is FORMAT-EXACT (Critical fix 1) ---
# The question is "will the RUNNING daemon hit this entry?". A leftover entry
# in a foreign pixel format is unreadable to it, so answering yes makes the
# prefetcher skip a wallpaper that still cold-decodes on display — turning the
# prefetcher into a no-op across the whole rotation after a format change.
cd_dir="$(awww_cache_dir)"
: > "$cd_dir/_x_y.gif__800x600_fit_Bgr"

if AWWW_FORMAT=bgr awww_is_cached /x/y.gif 800x600 fit; then :; else
  echo "FAIL: is_cached must be TRUE for an entry in the daemon's own format" >&2; fail=1
fi
if AWWW_FORMAT=argb awww_is_cached /x/y.gif 800x600 fit; then
  echo "FAIL: is_cached must be FALSE when only a foreign-format (_Bgr) entry exists for an argb daemon" >&2; fail=1
fi
# Symmetric case, so the test cannot pass by favouring one literal token.
: > "$cd_dir/_x_z.gif__800x600_fit_Argb"
if AWWW_FORMAT=argb awww_is_cached /x/z.gif 800x600 fit; then :; else
  echo "FAIL: is_cached must be TRUE for an _Argb entry under an argb daemon" >&2; fail=1
fi
if AWWW_FORMAT=bgr awww_is_cached /x/z.gif 800x600 fit; then
  echo "FAIL: is_cached must be FALSE when only an _Argb entry exists for a bgr daemon" >&2; fail=1
fi
# Unprobeable daemon: fall back to the permissive glob (fail OPEN). Failing
# closed here would make a missing daemon trigger a full re-decode of the cache.
if AWWW_FORMAT=weirdfmt awww_is_cached /x/y.gif 800x600 fit; then :; else
  echo "FAIL: is_cached must fall back to the permissive glob when the daemon can't be probed" >&2; fail=1
fi

if awww_is_cached /x/nope.gif 800x600 fit; then
  echo "FAIL: is_cached should be false for absent entry" >&2; fail=1
fi
rm -f "$cd_dir/_x_z.gif__800x600_fit_Argb"

# --- frame_entries includes __ entries and EXCLUDES per-output restore files ---
: > "$cd_dir/eDP-2"
: > "$cd_dir/HDMI-A-1"
entries="$(awww_frame_entries)"
if grep -q "eDP-2" <<<"$entries"; then
  echo "FAIL: frame_entries must exclude per-output restore files" >&2; fail=1
fi
assert_eq "$(wc -l <<<"$entries" | tr -d ' ')" "1"


# --- active_resolutions must never abort a set -e caller, even when the
# pipeline's intermediate `grep -v` stage matches nothing (all-HEADLESS
# output, or awww query producing nothing at all) ---
stub_dir="$tmp/stubbin"
mkdir -p "$stub_dir"
stub_awww="$stub_dir/awww"

write_stub() {
  # $1: exact stdout for the stub to produce. Uses printf '%s' (no forced
  # trailing newline) so an empty argument yields truly zero bytes of
  # output, not a single blank line — the two are different pipeline cases.
  {
    printf '#!/usr/bin/env bash\n'
    printf 'printf %%s %q\n' "$1"
  } > "$stub_awww"
  chmod +x "$stub_awww"
}

# normal multi-output text: expect distinct WxH values, HEADLESS excluded
write_stub 'eDP-2: 1920x1080, scale: 1
HDMI-A-1: 2560x1440, scale: 1
HEADLESS-1: 1920x1080, scale: 1'
resolutions="$(PATH="$stub_dir:$PATH" awww_active_resolutions)"
after_call_1="reached"
assert_eq "$resolutions" "$(printf '1920x1080\n2560x1440')"
assert_eq "$after_call_1" "reached"

# only HEADLESS lines: grep -v matches zero lines -> must still exit 0, empty output
write_stub 'HEADLESS-1: 1920x1080, scale: 1
HEADLESS-2: 2560x1440, scale: 1'
resolutions="$(PATH="$stub_dir:$PATH" awww_active_resolutions)"
after_call_2="reached"
assert_eq "$resolutions" ""
assert_eq "$after_call_2" "reached"

# awww query emits nothing at all -> must still exit 0, empty output
write_stub ''
resolutions="$(PATH="$stub_dir:$PATH" awww_active_resolutions)"
after_call_3="reached"
assert_eq "$resolutions" ""
assert_eq "$after_call_3" "reached"

# --- journal: touch records a timestamp, age reads it back ---
export AWWW_JOURNAL="$tmp/usage.tsv"
awww_journal_touch "key-one"
ts="$(awww_journal_age "key-one")"
if [[ ! "$ts" =~ ^[0-9]+$ ]] || (( ts <= 0 )); then
  echo "FAIL: journal_age should return a positive epoch, got [$ts]" >&2; fail=1
fi

# --- unknown key reports 0 (sorts oldest → evicted first) ---
assert_eq "$(awww_journal_age "never-seen")" "0"

# --- journal file does not exist at all -> age still reports 0, exit 0 ---
fresh_journal="$tmp/does-not-exist.tsv"
assert_eq "$(AWWW_JOURNAL="$fresh_journal" awww_journal_age "whatever")" "0"

# --- default journal path (no AWWW_JOURNAL override) resolves under
#     XDG_CACHE_HOME, matching the documented fallback ---
assert_eq "$(env -u AWWW_JOURNAL XDG_CACHE_HOME="$tmp/xdgcache" bash -c '
  source "'"$SCRIPT_DIR"'/awww-cache-lib.sh"
  awww_journal_path
')" "$tmp/xdgcache/awww-usage.tsv"

# --- re-touch updates in place, never duplicates the key ---
awww_journal_touch "key-one"
assert_eq "$(grep -c 'key-one' "$AWWW_JOURNAL")" "1"

# --- distinct keys coexist ---
awww_journal_touch "key-two"
assert_eq "$(wc -l < "$AWWW_JOURNAL" | tr -d ' ')" "2"

# --- Finding 1 regression: awww_journal_age on an unknown key must NOT
#     abort a `set -e` caller when called directly (not wrapped in
#     $(...)). Bash disables errexit propagation inside command
#     substitution (inherit_errexit is off), which is exactly why every
#     other call in this suite going through $(...) would never catch
#     this — so this check deliberately avoids that shape.
#
#     The whole probe runs in a NESTED bash -c so a regression here can't
#     abort this test file's own `set -e` shell before later assertions
#     run; `set +e`/`set -e` around the capture turns "nested shell died"
#     into a normal FAIL rather than an uncaught abort of this suite. ---
set +e
finding1_out="$(bash -c '
  set -euo pipefail
  source "'"$SCRIPT_DIR"'/awww-cache-lib.sh"
  export AWWW_JOURNAL="'"$tmp"'/finding1.tsv"
  awww_journal_touch "some-key"
  awww_journal_age "never-seen-key-f1"
  echo "after"
')"
finding1_exit=$?
set -e
if [[ $finding1_exit -ne 0 ]]; then
  echo "FAIL: awww_journal_age on an unknown key aborted its (unwrapped) caller under set -e (exit $finding1_exit) — 'after' never ran" >&2
  fail=1
else
  assert_eq "$finding1_out" "0after"
fi

# --- Finding 2 regression (data loss): touching a key must never delete
#     or blank the journal line of a DIFFERENT key that merely has this
#     key as a text prefix. With substring matching, touching "k" wipes
#     out "k-longer"'s line entirely, so its age wrongly reads back as 0
#     (indistinguishable from "never journaled"). ---
: > "$AWWW_JOURNAL"
awww_journal_touch "k-longer"
awww_journal_touch "k"
if [[ "$(awww_journal_age "k-longer")" == "0" ]]; then
  echo "FAIL: touching prefix key 'k' wiped out 'k-longer' (substring match data loss)" >&2
  fail=1
fi

# --- Finding 2 regression (wrong attribution): with both a key and a
#     longer key sharing it as a prefix present, looking up the SHORTER
#     key must return its OWN timestamp, not the other's. Substring
#     matching (grep -F) matches both lines; `tail -1` then returns
#     whichever happens to sort last in the file, not the correct one. ---
: > "$AWWW_JOURNAL"
printf '222\tk\n' >> "$AWWW_JOURNAL"
printf '111\tk-longer\n' >> "$AWWW_JOURNAL"
assert_eq "$(awww_journal_age "k")" "222"

# --- touch_wallpaper records the REAL on-disk filenames, across resolutions
#     and whatever pixel-format token happens to be in use ---
: > "$AWWW_JOURNAL"
: > "$cd_dir/_w_x.gif__1920x1080_crop_Bgr"
: > "$cd_dir/_w_x.gif__2560x1440_crop_Bgr"
: > "$cd_dir/_w_other.gif__1920x1080_crop_Bgr"
AWWW_FORMAT=bgr awww_journal_touch_wallpaper "/w/x.gif"
assert_eq "$(grep -c '_w_x.gif__' "$AWWW_JOURNAL")" "2"
assert_eq "$(grep -c '_w_other.gif__' "$AWWW_JOURNAL")" "0"

# --- Critical fix 2: touch_wallpaper must NOT stamp foreign-format entries.
#     Stamping them makes dead weight sort most-recently-used, so the reaper
#     evicts it LAST and the cache converges on ~half unusable entries — a
#     permanently halved effective cap. _w_x now has entries in BOTH formats;
#     an argb daemon must journal only the _Argb one. ---
: > "$AWWW_JOURNAL"
: > "$cd_dir/_w_x.gif__1920x1080_crop_Argb"
AWWW_FORMAT=argb awww_journal_touch_wallpaper "/w/x.gif"
assert_eq "$(grep -c '_Argb' "$AWWW_JOURNAL")" "1"
if grep -q '_Bgr' "$AWWW_JOURNAL"; then
  echo "FAIL: touch_wallpaper stamped foreign-format (_Bgr) entries under an argb daemon — they would become LRU-immortal" >&2
  fail=1
fi

# Symmetric: a bgr daemon journals only the two _Bgr entries, not the _Argb one.
: > "$AWWW_JOURNAL"
AWWW_FORMAT=bgr awww_journal_touch_wallpaper "/w/x.gif"
assert_eq "$(grep -c '_Bgr' "$AWWW_JOURNAL")" "2"
if grep -q '_Argb' "$AWWW_JOURNAL"; then
  echo "FAIL: touch_wallpaper stamped foreign-format (_Argb) entries under a bgr daemon" >&2
  fail=1
fi

# Unprobeable daemon: touch everything, as before (fail open).
: > "$AWWW_JOURNAL"
AWWW_FORMAT=weirdfmt awww_journal_touch_wallpaper "/w/x.gif"
assert_eq "$(wc -l < "$AWWW_JOURNAL" | tr -d ' ')" "3"

# A wallpaper with no cache entries at all must be a silent no-op, not an
# abort: the empty glob path runs on every prefetch of an uncached wallpaper.
: > "$AWWW_JOURNAL"
awww_journal_touch_wallpaper "/w/has-no-entries-at-all.gif"
after_empty_touch="reached"
assert_eq "$after_empty_touch" "reached"
assert_eq "$(wc -c < "$AWWW_JOURNAL" | tr -d ' ')" "0"

if [[ $fail -eq 0 ]]; then echo "PASS: awww-cache-lib.sh"; else echo "TESTS FAILED" >&2; exit 1; fi
