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

    // Side-panel edge: "auto" docks opposite the bar; "left"/"right" force a side.
    property alias sidePosition: adapter.sidePosition
    readonly property var sidePositions: ["auto", "left", "right"]

    // Side-panel drag auto-scroll speed (px per ~16ms tick while a drag hovers an edge).
    property alias sideScrollSpeed: adapter.sideScrollSpeed
    readonly property int sideScrollMin: 4
    readonly property int sideScrollMax: 30

    // Mission Control tuning. missionScale grows/shrinks the top Spaces
    // thumbnails; the bar height derives from them, so it follows along.
    property alias missionScale: adapter.missionScale
    readonly property real missionScaleMin: 0.6
    readonly property real missionScaleMax: 1.4
    readonly property real resolvedMissionScale:
        Math.max(missionScaleMin, Math.min(missionScaleMax, missionScale))

    // Dynamic Spaces (macOS-style): when true the top bar shows only the
    // occupied workspaces (+ the active one) and an Add-workspace (+) button
    // that switches to the next empty workspace. When false the bar shows the
    // fixed 1..workspacesShown set.
    property alias missionDynamic: adapter.missionDynamic

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
    readonly property var defaults: ({ layout: "grid", gridScale: 1.0, gridPosition: "center", sidePosition: "auto", sideScrollSpeed: 12, missionScale: 1.0, missionDynamic: false })

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

    function setSidePosition(pos) {
        if (config.sidePositions.indexOf(pos) < 0) return;
        adapter.sidePosition = pos;
        config.save();
    }

    // Clamp so a hand-edited JSON can't push the grid off-screen / to zero.
    readonly property real resolvedGridScale:
        Math.max(gridScaleMin, Math.min(gridScaleMax, gridScale))
    readonly property string resolvedGridPosition:
        gridPositions.indexOf(gridPosition) >= 0 ? gridPosition : "center"
    readonly property string resolvedSidePosition:
        sidePositions.indexOf(sidePosition) >= 0 ? sidePosition : "auto"
    readonly property int resolvedSideScrollSpeed:
        Math.max(sideScrollMin, Math.min(sideScrollMax, sideScrollSpeed))

    function resetDefaults() {
        adapter.layout = config.defaults.layout;
        adapter.gridScale = config.defaults.gridScale;
        adapter.gridPosition = config.defaults.gridPosition;
        adapter.sidePosition = config.defaults.sidePosition;
        adapter.sideScrollSpeed = config.defaults.sideScrollSpeed;
        adapter.missionScale = config.defaults.missionScale;
        adapter.missionDynamic = config.defaults.missionDynamic;
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
            property string sidePosition: "auto"
            property int sideScrollSpeed: 12
            property real missionScale: 1.0
            property bool missionDynamic: false
        }
    }
}
