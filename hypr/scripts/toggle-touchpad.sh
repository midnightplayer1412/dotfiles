#!/bin/bash
# Flip the touchpad on/off and report it. Bound to Super+Shift+T.
#
# Writes touchpad-config.json (the single source of truth, shared with
# Settings → Input) then delegates the actual hyprctl call to apply-touchpad.sh.
# The Settings pane's FileView watches the file, so its switch follows along
# without any IPC between the two surfaces.
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

cfg="${TOUCHPAD_CONFIG:-$HOME/.config/quickshell/touchpad-config.json}"
apply="${TOUCHPAD_APPLY:-$HOME/.config/hypr/scripts/apply-touchpad.sh}"

mkdir -p "$(dirname "$cfg")"
# Missing OR unparseable config is reset to the default, so a corrupt file can
# never wedge the bind — the next press just works.
if [[ ! -f "$cfg" ]] || ! jq -e . "$cfg" >/dev/null 2>&1; then
  printf '{\n    "enabled": true\n}\n' > "$cfg"
fi

# NOT `.enabled // true` — jq's `//` treats `false` as empty, which would read a
# disabled touchpad back as enabled and make the toggle a one-way street.
cur=$(jq -r 'if (.enabled | type) == "boolean" then .enabled else true end' "$cfg")
if [[ "$cur" == "false" ]]; then
  new=true
else
  new=false
fi

# Write via a temp file + mv so a crash mid-write can't leave a truncated config
# that the applier would read as corrupt.
tmp=$(mktemp "${cfg}.XXXXXX")
trap 'rm -f "$tmp"' EXIT
jq --argjson v "$new" '.enabled = $v' "$cfg" > "$tmp"
mv "$tmp" "$cfg"
trap - EXIT

[[ -x "$apply" ]] && "$apply"

if command -v notify-send >/dev/null 2>&1; then
  if [[ "$new" == "true" ]]; then
    body="Touchpad enabled"
    icon="input-touchpad"
  else
    body="Touchpad disabled"
    icon="input-touchpad-off"
  fi
  # The synchronous hint makes repeated toggles replace the existing card
  # instead of stacking a new one in the notification centre each press.
  notify-send -a "Hyprland" -i "$icon" \
    -h "string:x-canonical-private-synchronous:touchpad" \
    "$body"
fi
