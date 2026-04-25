pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Material You color roles — fallbacks used until matugen generates colors.json
    // NOTE: QML reserves property names starting with `on<Capital>` for signal
    // handlers, so Material You's `onPrimary` / `onSurface` are renamed to
    // `*Text` here. The matugen JSON keys keep the original names — only QML
    // property names need the prefix dropped.
    readonly property color primary:          colors?.primary          ?? "#8aadf4"
    readonly property color primaryText:      colors?.onPrimary        ?? "#003258"
    readonly property color primaryContainer: colors?.primaryContainer ?? "#114a7a"
    readonly property color secondary:        colors?.secondary        ?? "#b4befe"
    readonly property color secondaryText:    colors?.onSecondary      ?? "#1e1e2e"
    readonly property color surface:          colors?.surface          ?? "#1e1e2e"
    readonly property color surfaceText:      colors?.onSurface        ?? "#cdd6f4"
    readonly property color surfaceContainer: colors?.surfaceContainer ?? "#2b2b3d"
    readonly property color outline:          colors?.outline          ?? "#6c7086"

    // Bar geometry
    readonly property int barWidth: 48
    readonly property int barMargin: 4
    readonly property int barRadius: 12
    readonly property int iconSize: 20
    readonly property int workspaceDotSize: 8
    readonly property int workspaceDotActiveSize: 8

    // Launcher geometry
    readonly property int launcherWidth: 600
    readonly property int launcherHeight: 400
    readonly property int launcherRadius: 16
    readonly property int launcherItemHeight: 48
    readonly property int launcherSearchHeight: 44
    readonly property int launcherMargin: 4
    readonly property int launcherHoverHeight: 12
    readonly property int launcherHoverWidth: 700

    // HUD geometry
    readonly property int hudWidth: 300
    readonly property int hudHeight: 50
    readonly property int hudRadius: 25
    readonly property int hudBottomMargin: 40

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
