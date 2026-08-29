#!/usr/bin/env bash
# test-gen-keymap.sh — fixture test for gen-keymap.sh
#
# Feeds a canned `hyprctl binds -j` payload via BINDS_JSON so the test never
# needs a running compositor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="$SCRIPT_DIR/gen-keymap.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# modmask: SHIFT=1 CTRL=4 ALT=8 SUPER=64
cat > "$tmp/binds.json" <<'EOF'
[
 {"modmask":64,"key":"RETURN","dispatcher":"exec","arg":"kitty","submap":"","mouse":false,
  "description":"Apps: Open terminal"},
 {"modmask":64,"key":"Q","dispatcher":"killactive","arg":"","submap":"","mouse":false,
  "description":""},
 {"modmask":65,"key":"S","dispatcher":"exec","arg":"hyprshot","submap":"","mouse":false,
  "description":"Screenshot: Region screenshot"},
 {"modmask":0,"key":"XF86AudioMute","dispatcher":"exec","arg":"wpctl","submap":"","mouse":false,
  "description":"Media: Mute audio"},
 {"modmask":64,"key":"R","dispatcher":"submap","arg":"resize","submap":"","mouse":false,
  "description":"Window: Resize mode (h/j/k/l)"},
 {"modmask":0,"key":"l","dispatcher":"resizeactive","arg":"30 0","submap":"resize","mouse":false,
  "description":""},
 {"modmask":0,"key":"Return","dispatcher":"submap","arg":"reset","submap":"resize","mouse":false,
  "description":""},
 {"modmask":64,"key":"mouse:272","dispatcher":"mouse","arg":"movewindow","submap":"","mouse":true,
  "description":""},
 {"modmask":72,"key":"Tab","dispatcher":"global","arg":"quickshell:x","submap":"altTab","mouse":false,
  "description":""},
 {"modmask":64,"key":"P","dispatcher":"exec","arg":"x","submap":"","mouse":false,
  "description":"Weird: colon: in desc"}
]
EOF

out="$(BINDS_JSON="$tmp/binds.json" $GEN -)"

fail=0
assert_contains() {
  if ! grep -qF "$1" <<<"$out"; then
    echo "FAIL: expected to find: $1" >&2
    fail=1
  fi
}
assert_absent() {
  if grep -qF "$1" <<<"$out"; then
    echo "FAIL: did NOT expect to find: $1" >&2
    fail=1
  fi
}

# Described bind: category + desc split out of .description
assert_contains '"key": "RETURN", "mods": ["SUPER"], "category": "Apps", "desc": "Open terminal"'
# Undescribed bind: dispatcher fallback label
assert_contains '"key": "Q", "mods": ["SUPER"], "category": "", "desc": "Close active window"'
# Multiple modifiers, in SUPER-first order
assert_contains '"mods": ["SUPER", "SHIFT"], "category": "Screenshot", "desc": "Region screenshot"'
# Media key with no modifiers
assert_contains '"key": "XF86AudioMute", "mods": [], "category": "Media", "desc": "Mute audio"'
# A description containing a further colon keeps the remainder in desc
assert_contains '"category": "Weird", "desc": "colon: in desc"'
# Submap inner binds are skipped (resize mode and altTab mode)
assert_absent 'resizeactive'
assert_absent 'quickshell:x'
# Mouse bind is skipped
assert_absent 'mouse'

# Output must be valid JSON
if command -v python3 >/dev/null 2>&1; then
  if ! python3 -m json.tool <<<"$out" >/dev/null 2>&1; then
    echo "FAIL: output is not valid JSON" >&2
    fail=1
  fi
fi

if [[ $fail -eq 0 ]]; then
  echo "PASS: gen-keymap.sh"
else
  echo "TESTS FAILED" >&2
  exit 1
fi
