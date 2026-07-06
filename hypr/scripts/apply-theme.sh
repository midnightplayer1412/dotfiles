#!/bin/bash
# Regenerate the Matugen palette per the theme-config (mode: auto | static).
# This is the single Matugen entry point — both the wallpaper apply and the
# Settings → Appearance "theme color" controls funnel through here, so the four
# Matugen templates (quickshell, tmux, yazi, hyprlock) always stay in sync.
#
# Usage: apply-theme.sh [mode] [color] [wallpaper-path]
#   mode  : "auto" | "static"   (empty → read from theme-config.json)
#   color : seed hex "#rrggbb"  (empty → read from theme-config.json)
#   wp    : wallpaper for auto mode (empty → read .current from wallpaper-state)
#
# Passing mode/color as args lets the live Settings apply avoid a race with the
# config file it just wrote; the wallpaper path is honored only in auto mode.
set -euo pipefail

cfg="$HOME/.config/quickshell/theme-config.json"
wpstate="$HOME/.config/quickshell/wallpaper-state.json"

mode="${1:-}"
color="${2:-}"
wp="${3:-}"

if [[ -z "$mode" && -f "$cfg" ]]; then mode=$(jq -r '.mode // "auto"' "$cfg" 2>/dev/null); fi
[[ -z "$mode" || "$mode" == "null" ]] && mode="auto"
if [[ -z "$color" && -f "$cfg" ]]; then color=$(jq -r '.color // "#33ccff"' "$cfg" 2>/dev/null); fi
[[ -z "$color" || "$color" == "null" ]] && color="#33ccff"

if [[ "$mode" == "static" ]]; then
  matugen color hex "$color"
else
  if [[ -z "$wp" && -f "$wpstate" ]]; then wp=$(jq -r '.current // ""' "$wpstate" 2>/dev/null); fi
  if [[ -n "$wp" && "$wp" != "null" && -f "$wp" ]]; then
    matugen image --source-color-index 0 "$wp"
  fi
fi

tmux source-file "$HOME/.config/tmux/tmux.conf" 2>/dev/null || true

# Kitty re-reads its config (and the include'd theme.conf) on SIGUSR1; with
# dynamic_background_opacity set, colors + alpha reload live in every running
# instance. No-ops if no kitty is running.
pkill -SIGUSR1 -x kitty 2>/dev/null || true

# Retint the keyboard backlight to the freshly-generated palette. Self-guards
# and no-ops when asusctl/asusd or the feature is off; `|| true` ensures a
# keyboard hiccup never fails the theme apply.
"$HOME/.config/hypr/scripts/apply-keyboard.sh" || true

# GTK apps read gtk.css only at startup, and Thunar daemonizes — quit the daemon
# so the next window picks up the freshly-generated palette. No-ops if Thunar
# isn't installed or isn't running.
if command -v thunar >/dev/null && pgrep -x thunar >/dev/null; then
  thunar -q 2>/dev/null || true
fi
