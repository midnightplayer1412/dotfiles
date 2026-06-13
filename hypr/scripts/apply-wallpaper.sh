#!/bin/bash
# Apply a wallpaper: set it via awww, regenerate matugen-driven themes,
# reload tmux. Stateless — no cycle loop, no state persistence.
#
# Usage: apply-wallpaper.sh <absolute-path>
set -euo pipefail

path="${1:-}"
if [[ -z "$path" ]]; then
  echo "usage: $0 <wallpaper-path>" >&2
  exit 2
fi
if [[ ! -f "$path" ]]; then
  echo "apply-wallpaper: file not found: $path" >&2
  exit 1
fi

# GIFs and fade transitions don't mix well: awww-daemon's animator can keep
# stamping frames onto the output during/after the fade, which makes the new
# static wallpaper "revert" to the GIF. Detect either side being a GIF and
# use an immediate switch instead of a fade in that case.
prev=$(awww query 2>/dev/null | head -1 | sed -n 's/.*image: //p')
gif_re='\.gif$'
log=/tmp/apply-wallpaper.log
{ printf '[%(%H:%M:%S)T] applying %q (prev=%q)\n' -1 "$path" "$prev"; } >> "$log"
if [[ "${path,,}" =~ $gif_re ]] || [[ "${prev,,}" =~ $gif_re ]]; then
  awww img "$path" --transition-type none 2>>"$log"
  rc=$?
else
  awww img "$path" --transition-type fade --transition-duration 2 2>>"$log"
  rc=$?
fi
{ printf '[%(%H:%M:%S)T] awww rc=%s; query: %s\n' -1 "$rc" "$(awww query 2>&1 | head -1)"; } >> "$log"

# Regenerate colors per the theme-config: in "static" mode the seed color wins
# (this wallpaper change won't clobber the theme); in "auto" mode the palette is
# derived from this wallpaper. apply-theme.sh also reloads tmux.
~/.config/hypr/scripts/apply-theme.sh "" "" "$path"
