#!/bin/bash
# Apply the touchpad enabled/disabled state from touchpad-config.json.
#
# Single source of truth for the `hyprctl keyword device[...]` command — neither
# the QML nor the toggle bind shells hyprctl itself (same rule apply-keyboard.sh
# follows for asusctl).
#
# Wired into hypr/components/autostart.conf as `exec =` (NOT exec-once), so it
# runs at login AND on every config reload. That is what makes a disabled
# touchpad survive both a reboot and Super+Shift+R — a reload re-reads
# touchpad.conf, which always declares `enabled = true` as the boot default,
# and this script immediately re-applies the real state on top.
#
# No-ops safely (exit 0) when the config, jq, hyprctl, or a touchpad is missing,
# so it can never wedge startup on a machine with no touchpad.
set -euo pipefail

command -v hyprctl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

cfg="${TOUCHPAD_CONFIG:-$HOME/.config/quickshell/touchpad-config.json}"
[[ -f "$cfg" ]] || exit 0

# NOT `.enabled // true` — jq's alternative operator treats `false` as empty, so
# that idiom reads a disabled touchpad back as enabled and silently no-ops.
# Anything that isn't a clean boolean means a corrupt config — fail safe by
# leaving the touchpad usable rather than stranding the user with no pointer.
enabled=$(jq -r 'if (.enabled | type) == "boolean" then .enabled else true end' \
  "$cfg" 2>/dev/null || echo true)
[[ "$enabled" == "true" || "$enabled" == "false" ]] || enabled=true

# Discover touchpads at runtime instead of hardcoding the device name, so this
# keeps working if the ASUS device string changes across a firmware/kernel bump.
mapfile -t pads < <(hyprctl -j devices 2>/dev/null \
  | jq -r '.mice[]?.name | select(test("touchpad"))' 2>/dev/null || true)
[[ ${#pads[@]} -gt 0 ]] || exit 0

for pad in "${pads[@]}"; do
  hyprctl keyword "device[$pad]:enabled" "$enabled" >/dev/null
done
