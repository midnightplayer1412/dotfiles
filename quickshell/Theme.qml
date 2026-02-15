pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Material You color roles — fallbacks used until matugen generates colors.json
    readonly property color primary:          colors?.primary          ?? "#8aadf4"
    readonly property color onPrimary:        colors?.onPrimary        ?? "#003258"
    readonly property color primaryContainer: colors?.primaryContainer ?? "#114a7a"
    readonly property color secondary:        colors?.secondary        ?? "#b4befe"
    readonly property color onSecondary:      colors?.onSecondary      ?? "#1e1e2e"
    readonly property color surface:          colors?.surface          ?? "#1e1e2e"
    readonly property color onSurface:        colors?.onSurface        ?? "#cdd6f4"
    readonly property color surfaceContainer: colors?.surfaceContainer ?? "#2b2b3d"
    readonly property color outline:          colors?.outline          ?? "#6c7086"

    // Bar geometry
    readonly property int barWidth: 48
    readonly property int barMargin: 8
    readonly property int barRadius: 12
    readonly property int iconSize: 20
    readonly property int workspaceDotSize: 8
    readonly property int workspaceDotActiveSize: 20

    // Launcher geometry
    readonly property int launcherWidth: 600
    readonly property int launcherHeight: 400
    readonly property int launcherRadius: 16
    readonly property int launcherItemHeight: 48
    readonly property int launcherSearchHeight: 44
    readonly property int launcherMargin: 12

    // Fonts
    readonly property string fontFamily: "sans-serif"
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeMedium: 12

    // Internal: parsed colors from matugen JSON
    property var colors: ({})

    FileView {
        id: colorFile
        path: Quickshell.shellDir + "/theme/colors.json"
        watchChanges: true
        preload: true

        onFileChanged: colorFile.reload()
        onLoaded: {
            try {
                root.colors = JSON.parse(colorFile.text())
            } catch (e) {
                console.warn("Theme: could not parse colors.json, using fallbacks")
                root.colors = {}
            }
        }
    }
}
