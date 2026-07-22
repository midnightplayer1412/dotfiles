#!/usr/bin/env bash
# test-touchpad-toggle.sh — fixture tests for toggle-touchpad.sh + apply-touchpad.sh
#
# Both scripts honour TOUCHPAD_CONFIG / TOUCHPAD_APPLY env overrides so the real
# ~/.config state is never touched. hyprctl and notify-send are stubbed on PATH,
# so this is safe to run on a machine with no Hyprland session.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOGGLE="$SCRIPT_DIR/toggle-touchpad.sh"
APPLY="$SCRIPT_DIR/apply-touchpad.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cfg="$tmp/touchpad-config.json"
calls="$tmp/hyprctl-calls"
: > "$calls"

# ── Stubs ────────────────────────────────────────────────────────────────
mkdir -p "$tmp/bin"

# hyprctl stub: `-j devices` returns a fixture device list; every other
# invocation (i.e. the `keyword device[...]` calls) is appended to $calls.
cat > "$tmp/bin/hyprctl" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "-j" && "\$2" == "devices" ]]; then
  cat "\$TOUCHPAD_FIXTURE"
  exit 0
fi
echo "\$*" >> "$calls"
EOF

cat > "$tmp/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "$tmp/bin/hyprctl" "$tmp/bin/notify-send"
export PATH="$tmp/bin:$PATH"

# Device fixtures.
cat > "$tmp/devices.json" <<'EOF'
{ "mice": [
  { "name": "logitech-g502-hero-gaming-mouse" },
  { "name": "asup1205:00-093a:2008-touchpad" }
] }
EOF
cat > "$tmp/devices-nopad.json" <<'EOF'
{ "mice": [ { "name": "logitech-g502-hero-gaming-mouse" } ] }
EOF

export TOUCHPAD_CONFIG="$cfg"
export TOUCHPAD_APPLY="$APPLY"
export TOUCHPAD_FIXTURE="$tmp/devices.json"

fail=0
check() {   # check <description> <expected> <actual>
  if [[ "$2" != "$3" ]]; then
    echo "FAIL: $1 — expected '$2', got '$3'" >&2
    fail=1
  fi
}

enabled_now() { jq -r '.enabled' "$cfg"; }

# ── toggle-touchpad.sh ───────────────────────────────────────────────────

# Missing config is created, and the first toggle turns the touchpad OFF
# (default state is on).
rm -f "$cfg"
"$TOGGLE"
check "missing config -> created" "true" "$([[ -f $cfg ]] && echo true || echo false)"
check "first toggle disables" "false" "$(enabled_now)"

# Second toggle flips it back on.
"$TOGGLE"
check "second toggle enables" "true" "$(enabled_now)"

# The toggle delegates to the applier, which must have issued a keyword call
# carrying the new state.
check "applier ran with new state" "true" \
  "$(grep -q 'keyword device\[asup1205:00-093a:2008-touchpad\]:enabled true' "$calls" && echo true || echo false)"

# Corrupt config must not crash the toggle, and must leave valid JSON behind.
echo 'not json at all {{{' > "$cfg"
"$TOGGLE" || true
check "corrupt config -> still valid JSON" "true" \
  "$(jq -e . "$cfg" >/dev/null 2>&1 && echo true || echo false)"

# ── apply-touchpad.sh ────────────────────────────────────────────────────

# Only touchpads are targeted — the mouse must never be disabled.
: > "$calls"
printf '{"enabled": false}\n' > "$cfg"
"$APPLY"
check "applies to touchpad" "true" \
  "$(grep -q 'keyword device\[asup1205:00-093a:2008-touchpad\]:enabled false' "$calls" && echo true || echo false)"
check "leaves the mouse alone" "false" \
  "$(grep -q 'g502' "$calls" && echo true || echo false)"

# A non-boolean `enabled` is a corrupt config: fail safe by enabling, never
# strand the user without a pointer.
: > "$calls"
printf '{"enabled": "banana"}\n' > "$cfg"
"$APPLY"
check "corrupt value fails safe to enabled" "true" \
  "$(grep -q ':enabled true' "$calls" && echo true || echo false)"

# No touchpad present -> no keyword calls at all, clean exit.
: > "$calls"
printf '{"enabled": false}\n' > "$cfg"
TOUCHPAD_FIXTURE="$tmp/devices-nopad.json" "$APPLY"
check "no touchpad -> no-op" "0" "$(wc -l < "$calls" | tr -d ' ')"

# Missing config -> no-op rather than an error.
: > "$calls"
rm -f "$cfg"
"$APPLY"
check "missing config -> no-op" "0" "$(wc -l < "$calls" | tr -d ' ')"

# Applying twice in a row is idempotent (same call, no state drift).
: > "$calls"
printf '{"enabled": false}\n' > "$cfg"
"$APPLY"; "$APPLY"
check "idempotent (2 runs, 1 unique call)" "1" "$(sort -u "$calls" | wc -l | tr -d ' ')"

if [[ $fail -eq 0 ]]; then
  echo "PASS: touchpad toggle"
else
  echo "TESTS FAILED" >&2
  exit 1
fi
