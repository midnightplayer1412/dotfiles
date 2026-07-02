pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Persistent SUPER+TAB overview settings, backed by
// ~/.config/quickshell/overview-config.json.
//
// v1 stores a single choice: which layout the overview renders. Structured like
// BarConfig so future style knobs (radius, opacity, previews) are a one-line
// `property alias` + JsonAdapter property addition.
Singleton {
    id: config

    // Active layout variant. Overview.qml dispatches on this.
    property alias layout: adapter.layout   // "grid" | "dock" | "expose" | "side"

    // Grid-layout tuning. gridScale grows/shrinks the whole grid (0.6–1.4);
    // gridPosition places it at one of nine presets on screen.
    property alias gridScale: adapter.gridScale
    property alias gridPosition: adapter.gridPosition   // e.g. "center", "top-left", "bottom-right"

    readonly property var gridPositions: [
        "top-left",    "top",    "top-right",
        "left",        "center", "right",
        "bottom-left", "bottom", "bottom-right"
    ]
    readonly property real gridScaleMin: 0.6
    readonly property real gridScaleMax: 1.4

    // Every layout the overview knows how to render, in picker order. A value
    // outside this set falls back to "grid" at the dispatcher.
    readonly property var knownLayouts: ["grid", "dock", "expose", "side", "mission"]
    readonly property var labels: ({
        "grid":    "Grid",
        "dock":    "Dock",
        "expose":  "Exposé",
        "side":    "Side panel",
        "mission": "Mission Control"
    })
    readonly property var descriptions: ({
        "grid":    "Centered 2×5 grid of workspace mini-monitors.",
        "dock":    "Horizontal strip of recent windows near the bottom edge.",
        "expose":  "Every window spread across the whole screen.",
        "side":    "Vertical workspace list docked opposite the bar.",
        "mission": "Spaces along the top, current space's windows spread below; drag a window onto a Space to move it."
    })

    // True when `layout` is a known key; the dispatcher uses resolvedLayout so a
    // stale / hand-edited JSON value can't blank the overview.
    readonly property string resolvedLayout:
        knownLayouts.indexOf(layout) >= 0 ? layout : "grid"

    // Known-good baseline. resetDefaults() restores it.
    readonly property var defaults: ({ layout: "grid", gridScale: 1.0, gridPosition: "center" })

    function setLayout(key) {
        if (config.knownLayouts.indexOf(key) < 0) return;
        adapter.layout = key;
        config.save();
    }

    function setGridPosition(pos) {
        if (config.gridPositions.indexOf(pos) < 0) return;
        adapter.gridPosition = pos;
        config.save();
    }

    // Clamp so a hand-edited JSON can't push the grid off-screen / to zero.
    readonly property real resolvedGridScale:
        Math.max(gridScaleMin, Math.min(gridScaleMax, gridScale))
    readonly property string resolvedGridPosition:
        gridPositions.indexOf(gridPosition) >= 0 ? gridPosition : "center"

    function resetDefaults() {
        adapter.layout = config.defaults.layout;
        adapter.gridScale = config.defaults.gridScale;
        adapter.gridPosition = config.defaults.gridPosition;
        config.save();
    }

    function save() { view.writeAdapter(); }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/overview-config.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()

        JsonAdapter {
            id: adapter
            property string layout: "grid"
            property real gridScale: 1.0
            property string gridPosition: "center"
        }
    }
}
