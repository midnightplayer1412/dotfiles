#!/usr/bin/env bash
# gen-keymap.sh — parse Hyprland binds.conf into the cheatsheet keymap JSON.
#
# Usage:
#   gen-keymap.sh [BINDS_CONF] [OUTPUT]
#     BINDS_CONF  input file   (default: hypr/components/binds.conf next to this script)
#     OUTPUT      output file, or "-" for stdout
#                 (default: quickshell/cheatsheet/keymaps/hyprland.json)
#
# Description source per bind:
#   - "# @cheat <Category>: <Description>" trailing comment → category + desc
#   - otherwise a fallback label is derived from the dispatcher
#
# Binds inside a non-reset submap (e.g. the resize submap) are skipped so the
# transient mode keys don't pollute the main map. Mouse binds are skipped too.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

BINDS="${1:-$DOTFILES/hypr/components/binds.conf}"
OUT="${2:-$DOTFILES/quickshell/cheatsheet/keymaps/hyprland.json}"

if [[ ! -f "$BINDS" ]]; then
  echo "gen-keymap: binds file not found: $BINDS" >&2
  exit 1
fi

generate() {
  awk '
    function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function fallback(d) {
      if (d == "killactive")        return "Close active window"
      if (d == "exit")              return "Exit Hyprland"
      if (d == "togglefloating")    return "Toggle floating"
      if (d == "fullscreen")        return "Toggle fullscreen"
      if (d == "pseudo")            return "Toggle pseudotile"
      if (d == "workspace")         return "Switch workspace"
      if (d == "movetoworkspace")   return "Move window to workspace"
      if (d == "movefocus")         return "Move focus"
      if (d == "swapwindow")        return "Swap window"
      if (d == "resizeactive")      return "Resize window"
      if (d == "layoutmsg")         return "Layout command"
      if (d == "togglesplit")       return "Toggle split"
      if (d == "submap")            return "Enter mode"
      if (d == "global")            return "Shell action"
      if (d == "exec")              return "Run command"
      return d
    }
    BEGIN {
      print "{"
      print "  \"app\": \"Hyprland\","
      print "  \"id\": \"hyprland\","
      print "  \"binds\": ["
      first = 1; insub = 0
    }
    {
      line = $0
      sub(/^[ \t]+/, "", line)

      # submap tracking — skip binds inside a non-reset submap
      if (line ~ /^submap[ \t]*=/) {
        val = line; sub(/^submap[ \t]*=[ \t]*/, "", val); val = trim(val)
        if (val == "reset") insub = 0; else insub = 1
        next
      }
      if (insub) next

      if (line !~ /^bind[a-z]*[ \t]*=/) next

      # separate trailing comment / @cheat annotation
      cheat = ""; directive = line
      hi = index(line, "#")
      if (hi > 0) {
        comment = substr(line, hi)
        directive = substr(line, 1, hi - 1)
        ci = index(comment, "@cheat")
        if (ci > 0) cheat = trim(substr(comment, ci + 6))
      }

      sub(/^bind[a-z]*[ \t]*=[ \t]*/, "", directive)

      n = split(directive, f, ",")
      for (i = 1; i <= n; i++) f[i] = trim(f[i])
      mods = f[1]; key = f[2]; disp = f[3]

      if (key == "") next
      if (key ~ /mouse/) next

      gsub(/\$mainMod/, "SUPER", mods)
      mj = ""; mn = split(mods, mm, " ")
      for (i = 1; i <= mn; i++)
        if (mm[i] != "") { if (mj != "") mj = mj ", "; mj = mj "\"" mm[i] "\"" }

      cat = ""; desc = ""
      if (cheat != "") {
        pi = index(cheat, ":")
        if (pi > 0) { cat = trim(substr(cheat, 1, pi - 1)); desc = trim(substr(cheat, pi + 1)) }
        else desc = cheat
      } else {
        desc = fallback(disp)
      }

      if (!first) printf(",\n"); first = 0
      printf("    { \"key\": \"%s\", \"mods\": [%s], \"category\": \"%s\", \"desc\": \"%s\" }",
             esc(key), mj, esc(cat), esc(desc))
    }
    END { print "\n  ]\n}" }
  ' "$BINDS"
}

if [[ "$OUT" == "-" ]]; then
  generate
else
  mkdir -p "$(dirname "$OUT")"
  generate > "$OUT"
  echo "gen-keymap: wrote $OUT" >&2
fi
