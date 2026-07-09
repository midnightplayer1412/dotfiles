pragma Singleton

import Quickshell
import QtQuick
import ".."
import "../ui"

// Design tokens for the active widget style preset (UiStyle.widgetStyle).
//
// Desktop/dashboard widgets read these tokens to skin themselves, the same way
// Ui.Surface reads Surfaces for the Solid/Glass preset. This singleton is the
// ONE place that decides what "Refined / Minimal / Playful / Data-dense" mean.
// Every value is a binding on `preset` (and, for colors, on Theme) so changing
// the preset in Settings → Appearance — or cycling the wallpaper — re-skins
// every widget live.
//
//   refined  — polished default: gradient accents, hairline frame, soft type
//   minimal  — borderless, airy, thin monochrome type, one quiet accent
//   playful  — bold gradients, big glyphs, radial gauges, pill controls
//   dense    — more per tile: rings + sparkline, hi/lo, media progress
Singleton {
    id: root

    readonly property string preset: UiStyle.widgetStyle

    // Structural knobs
    readonly property string gauge: (preset === "playful" || preset === "dense") ? "ring" : "bar"
    readonly property bool dense: preset === "dense"
    readonly property bool useGradient: preset === "refined" || preset === "playful"

    // Frame chrome (consumed by WidgetFrame). Minimal and Playful drop the
    // hairline for a cleaner look (Playful reads as an edge-to-edge gradient tile).
    readonly property bool frameBorder: preset !== "minimal" && preset !== "playful"
    readonly property int  frameRadius: preset === "playful" ? 20 : preset === "dense" ? 14 : 16
    readonly property int  framePad:    preset === "minimal" ? 14 : preset === "playful" ? 12 : 10

    // Typography / accent
    readonly property color titleColor:  preset === "minimal" ? Theme.surfaceText : Theme.primary
    readonly property int   titleWeight: preset === "minimal" ? Font.Light : preset === "playful" ? Font.ExtraBold : Font.Bold
    readonly property color accent:      preset === "minimal" ? Theme.surfaceText : Theme.primary
    readonly property real  subOpacity:  preset === "minimal" ? 0.55 : preset === "dense" ? 0.6 : preset === "playful" ? 0.75 : 0.7

    // Gradient fill stops (bars, rings, playful backgrounds). Derived from Theme
    // so they track matugen. `gradB` collapses to the accent for flat presets.
    readonly property color gradA: Theme.primary
    readonly property color gradB: (preset === "minimal") ? Theme.surfaceText : Theme.secondary

    // Progress/gauge track + bar thickness
    readonly property int barThickness: preset === "minimal" ? 3 : preset === "dense" ? 6 : 8
}
