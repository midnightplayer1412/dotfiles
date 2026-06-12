#!/usr/bin/env bash
# test-gen-keymap.sh — fixture test for gen-keymap.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="$SCRIPT_DIR/gen-keymap.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/binds.conf" <<'EOF'
$mainMod = SUPER
bind = $mainMod, RETURN, exec, $terminal  # @cheat Apps: Open terminal
bind = $mainMod, Q, killactive,
bind = $mainMod SHIFT, S, exec, hyprshot  # @cheat Screenshot: Region screenshot
bind = $mainMod, R, submap, resize
submap = resize
bind = , l, resizeactive, 30 0
bind = , Return, submap, reset
submap = reset
bindm = $mainMod, mouse:272, movewindow
bindel = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle  # @cheat Media: Mute audio
EOF

out="$($GEN "$tmp/binds.conf" -)"

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

# Annotated bind: category + desc parsed from @cheat
assert_contains '"key": "RETURN", "mods": ["SUPER"], "category": "Apps", "desc": "Open terminal"'
# Unannotated bind: dispatcher fallback label
assert_contains '"key": "Q", "mods": ["SUPER"], "category": "", "desc": "Close active window"'
# Multiple modifiers
assert_contains '"mods": ["SUPER", "SHIFT"], "category": "Screenshot", "desc": "Region screenshot"'
# Media key with no modifiers
assert_contains '"key": "XF86AudioMute", "mods": [], "category": "Media", "desc": "Mute audio"'
# Submap inner bind is skipped (resizeactive on "l" must not appear)
assert_absent 'resizeactive'
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
