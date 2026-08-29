#!/usr/bin/env bash
# gen-keymap.sh — build the cheatsheet keymap JSON from Hyprland's bind table.
#
# Usage:
#   gen-keymap.sh [OUTPUT]
#     OUTPUT      output file, or "-" for stdout
#                 (default: quickshell/cheatsheet/keymaps/hyprland.json)
#
#   BINDS_JSON=<file>   read `hyprctl binds -j` output from a file instead of
#                       querying the live compositor (used by the tests)
#
# Source of truth is the compositor, not the config text. components/binds.lua
# attaches a `desc = "<Category>: <Description>"` to each bind; Hyprland exposes
# it as .description in `hyprctl binds -j`, so the cheatsheet is generated from
# the binds that are actually registered and cannot drift from them.
#
# (Before the lua migration this text-scraped `# @cheat` comments out of
# binds.conf. hyprlang is deprecated since 0.55 and dropped in 0.57.)
#
# Binds inside a submap (e.g. the resize / altTab modes) are skipped so the
# transient mode keys don't pollute the main map. Mouse binds are skipped too.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

OUT="${1:-$DOTFILES/quickshell/cheatsheet/keymaps/hyprland.json}"

command -v jq >/dev/null 2>&1 || { echo "gen-keymap: jq not found" >&2; exit 1; }

read_binds() {
  if [[ -n "${BINDS_JSON:-}" ]]; then
    if [[ ! -f "$BINDS_JSON" ]]; then
      echo "gen-keymap: binds json not found: $BINDS_JSON" >&2
      exit 1
    fi
    cat "$BINDS_JSON"
  else
    command -v hyprctl >/dev/null 2>&1 || { echo "gen-keymap: hyprctl not found" >&2; exit 1; }
    hyprctl binds -j
  fi
}

generate() {
  read_binds | jq -r '
    # modmask bits, emitted in the order the old config wrote them
    def mods($m): [
      (if (($m / 64) | floor) % 2 == 1 then "SUPER" else empty end),
      (if (($m /  1) | floor) % 2 == 1 then "SHIFT" else empty end),
      (if (($m /  4) | floor) % 2 == 1 then "CTRL"  else empty end),
      (if (($m /  8) | floor) % 2 == 1 then "ALT"   else empty end)
    ];

    # label for a bind that carries no description
    def fallback($d):
      { killactive:      "Close active window",
        exit:            "Exit Hyprland",
        togglefloating:  "Toggle floating",
        fullscreen:      "Toggle fullscreen",
        pseudo:          "Toggle pseudotile",
        workspace:       "Switch workspace",
        movetoworkspace: "Move window to workspace",
        movefocus:       "Move focus",
        swapwindow:      "Swap window",
        resizeactive:    "Resize window",
        layoutmsg:       "Layout command",
        togglesplit:     "Toggle split",
        submap:          "Enter mode",
        global:          "Shell action",
        exec:            "Run command"
      }[$d] // $d;

    [ .[]
      | select(.submap == "")            # transient mode keys stay out of the map
      | select(.mouse != true)
      | select((.key // "") != "")
      | select((.key | test("mouse")) | not)
      | . as $b
      | (if (.description // "") != ""
         then (.description | split(": ")) | { cat: .[0], desc: (.[1:] | join(": ")) }
         else { cat: "", desc: fallback($b.dispatcher) }
         end) as $d
      | "    { \"key\": " + ($b.key | tojson)
        + ", \"mods\": [" + ((mods($b.modmask) | map(tojson)) | join(", ")) + "]"
        + ", \"category\": " + ($d.cat | tojson)
        + ", \"desc\": " + ($d.desc | tojson)
        + " }"
    ] | join(",\n")
  ' | {
    printf '{\n  "app": "Hyprland",\n  "id": "hyprland",\n  "binds": [\n'
    cat
    printf '  ]\n}\n'
  }
}

if [[ "$OUT" == "-" ]]; then
  generate
  exit 0
fi

# Refuse to overwrite a good keymap with a description-less one.
#
# The generated map is a tracked artifact. If the compositor reports no
# descriptions at all, the binds it is running did not come from
# components/binds.lua — the usual cause is a session still on the legacy
# hyprlang config, where `desc` does not exist and every entry would collapse to
# a dispatcher fallback ("Run command"). Writing that would silently degrade the
# committed cheatsheet on every reload. Keep the existing file instead.
tmp_out="$(mktemp)"
trap 'rm -f "$tmp_out"' EXIT
generate > "$tmp_out"

if [[ -s "$OUT" ]] && ! grep -q '"category": "[^"]' "$tmp_out"; then
  echo "gen-keymap: compositor reported no bind descriptions; keeping $OUT" >&2
  exit 0
fi

mkdir -p "$(dirname "$OUT")"
cat "$tmp_out" > "$OUT"
echo "gen-keymap: wrote $OUT" >&2
