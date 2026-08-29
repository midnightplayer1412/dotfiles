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
# A bind with no description is skipped rather than given a derived label: under
# the lua config EVERY bind reports its dispatcher as the opaque "__lua", so
# there is nothing left to derive one from, and an undescribed bind is one the
# author did not mean to document (the alt-tab submap-enter, say, which shares
# its chord with the described bind next to it). Skipped chords are listed on
# stderr so a genuine oversight is visible rather than silent.
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

# List main-map binds that carry no description, so an oversight in binds.lua is
# visible instead of silently missing from the sheet.
report_skipped() {
  read_binds | jq -r '
    .[]
    | select(.submap == "" and .mouse != true)
    | select((.key // "") != "")
    | select((.key | test("mouse")) | not)
    | select((.description // "") == "")
    | "  \(.key) (modmask \(.modmask))"
  ' | {
    mapfile -t rows
    if (( ${#rows[@]} )); then
      printf 'gen-keymap: %d bind(s) have no desc and are not in the sheet:\n' "${#rows[@]}" >&2
      printf '%s\n' "${rows[@]}" >&2
    fi
  }
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

    [ .[]
      | select(.submap == "")            # transient mode keys stay out of the map
      | select(.mouse != true)
      | select((.key // "") != "")
      | select((.key | test("mouse")) | not)
      | select((.description // "") != "")
      | . as $b
      | ((.description | split(": ")) | { cat: .[0], desc: (.[1:] | join(": ")) }) as $d
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

report_skipped

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
