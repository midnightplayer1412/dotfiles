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

# --- is_cached matches ANY pixel format (format token must not be hard-coded) ---
cd_dir="$(awww_cache_dir)"
: > "$cd_dir/_x_y.gif__800x600_fit_Bgr"
if awww_is_cached /x/y.gif 800x600 fit; then :; else
  echo "FAIL: is_cached should match _Bgr suffix" >&2; fail=1
fi
if awww_is_cached /x/nope.gif 800x600 fit; then
  echo "FAIL: is_cached should be false for absent entry" >&2; fail=1
fi

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

if [[ $fail -eq 0 ]]; then echo "PASS: awww-cache-lib.sh"; else echo "TESTS FAILED" >&2; exit 1; fi
