pragma Singleton

import Quickshell
import QtQuick
import ".."
import "../ui"

// Surface design tokens for the active surface preset (UiStyle.surface).
//
// Every panel/card background in the shell is drawn by Ui.Surface, which reads
// its colors from here. This singleton is the ONE place that decides what
// "Solid" vs "Glass" looks like — change a value and the whole shell re-skins
// live. Colors are derived from Theme so they keep tracking matugen; the preset
// only changes translucency / border / highlight, never the hue.
Singleton {
    id: root

    readonly property string preset: UiStyle.surface   // "solid" | "glass"
    readonly property bool isGlass: preset === "glass"

    // Namespace stamped on glass-bearing PanelWindows so Hyprland layerrules can
    // target them for real backdrop blur. The static layerrule in hyprland.conf
    // matches "quickshell-glass"; returning "quickshell" (a non-matching name)
    // is how the Glass preset with blur OFF, or the Solid preset, opts out.
    readonly property string blurNamespace:
        (isGlass && UiStyle.desktopBlur) ? "quickshell-glass" : "quickshell"

    // Convenience accessors for the *active* global preset (what Ui.Surface uses
    // by default). Preview cards in Settings pass an explicit preset to tokensFor().
    readonly property color baseColor:      tokensFor(preset).base
    readonly property color cardColor:      tokensFor(preset).card
    readonly property int   borderWidth:    tokensFor(preset).borderWidth
    readonly property color borderColor:    tokensFor(preset).borderColor
    readonly property color highlightColor: tokensFor(preset).highlight

    // The single source of truth for how a preset is drawn. Returns concrete,
    // matugen-derived tokens for `p` ("solid" | "glass").
    //   base        — level 0 (panel/window) background
    //   card        — level 1 (inner card) background
    //   borderWidth — hairline width (0 = no border)
    //   borderColor — hairline color
    //   highlight   — subtle top-edge highlight (transparent = none)
    function tokensFor(p) {
        if (p === "glass") {
            return {
                base:        withAlpha(Theme.surface, 0.55),
                card:        withAlpha(Theme.surfaceContainer, 0.45),
                borderWidth: 1,
                borderColor: withAlpha(Theme.surfaceText, 0.14),
                highlight:   Qt.rgba(1, 1, 1, 0.07),
                isGlass:     true
            };
        }
        // "solid" (and any unknown value) — today's opaque look, unchanged.
        return {
            base:        Theme.surface,
            card:        Theme.surfaceContainer,
            borderWidth: 0,
            borderColor: "transparent",
            highlight:   "transparent",
            isGlass:     false
        };
    }

    // c with a replaced alpha channel.
    function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
}
