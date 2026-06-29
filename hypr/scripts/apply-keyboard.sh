#!/bin/bash
# Apply the keyboard Aura lighting per keyboard-config.json, using the current
# Matugen palette primary (colorMode "theme") or a fixed custom color
# (colorMode "custom"). Called at the end of apply-theme.sh and directly from
# the Settings → Appearance panel.
#
# Single source of truth for the asusctl command — the QML never shells asusctl
# itself. No-ops safely (exit 0) whenever the feature is off or the hardware /
# daemon isn't present, so it can never break the theme pipeline (which runs
# under `set -euo pipefail` and on machines with no ASUS keyboard).
set -euo pipefail

# Hardware / daemon guards — silently do nothing if asusctl isn't usable.
command -v asusctl >/dev/null 2>&1 || exit 0
systemctl is-active --quiet asusd 2>/dev/null || exit 0

cfg="$HOME/.config/quickshell/keyboard-config.json"
colors="$HOME/.config/quickshell/theme/colors.json"
[[ -f "$cfg" ]] || exit 0

enabled=$(jq -r '.enabled // false' "$cfg" 2>/dev/null || echo false)
[[ "$enabled" == "true" ]] || exit 0

effect=$(jq -r '.effect // "static"' "$cfg" 2>/dev/null || echo static)
colorMode=$(jq -r '.colorMode // "theme"' "$cfg" 2>/dev/null || echo theme)
speed=$(jq -r '.speed // "med"' "$cfg" 2>/dev/null || echo med)
brightness=$(jq -r '.brightness // "high"' "$cfg" 2>/dev/null || echo high)

# Resolve the color: custom hex from config, or the live palette primary.
if [[ "$colorMode" == "custom" ]]; then
  hex=$(jq -r '.color // "#33ccff"' "$cfg" 2>/dev/null || echo "#33ccff")
else
  hex=$(jq -r '.primary // "#33ccff"' "$colors" 2>/dev/null || echo "#33ccff")
fi
hex="${hex#\#}"   # asusctl wants the bare hex, no leading '#'

# Build the right command form per effect (verified against asusctl 6.3.8):
#   -c only            : static, pulse, comet, flash
#   -c + --speed       : highlight, laser, ripple
#   --colour/--colour2 : breathe (two-colour; reuse primary for both)
case "$effect" in
  static|pulse|comet|flash)
    asusctl aura effect "$effect" -c "$hex" ;;
  highlight|laser|ripple)
    asusctl aura effect "$effect" -c "$hex" --speed "$speed" ;;
  breathe)
    # Breathe the theme color in and out (second colour = off) so the effect
    # is actually visible rather than a static fade between identical colours.
    asusctl aura effect breathe --colour "$hex" --colour2 "000000" --speed "$speed" ;;
  *)
    asusctl aura effect static -c "$hex" ;;
esac

# Backlight brightness — independent of the effect/colour (off|low|med|high).
case "$brightness" in
  off|low|med|high) asusctl leds set "$brightness" ;;
  *)                asusctl leds set high ;;
esac
