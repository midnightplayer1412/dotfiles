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
    readonly property color error:            colors?.error            ?? "#f38ba8"
    readonly property color errorText:        colors?.onError          ?? "#1e1e2e"
    readonly property color errorContainer:   colors?.errorContainer   ?? "#93000a"

    // Bar geometry
    readonly property int barWidth: 48
    readonly property int barMargin: 4
    readonly property int barRadius: 12
    readonly property int iconSize: 20
    readonly property int barIconSize: 22   // standalone bar widget icons/glyphs (tray, volume, network)
    readonly property int scrollGutter: 12   // right gutter reserved for Ui.ScrollBar / Ui.ScrollView
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

    // Launcher layout presets (named sizes resolved in Launcher.qml)
    readonly property int launcherSpotlightWidthSmall: 600
    readonly property int launcherSpotlightHeightSmall: 440
    readonly property int launcherSpotlightWidthMedium: 720
    readonly property int launcherSpotlightHeightMedium: 520
    readonly property int launcherSpotlightWidthLarge: 860
    readonly property int launcherSpotlightHeightLarge: 620
    readonly property int launcherSidebarWidthNarrow: 360
    readonly property int launcherSidebarWidthMedium: 420
    readonly property int launcherSidebarWidthWide: 500
    readonly property int launcherSidebarGap: 12
    readonly property int launcherGridIconSmall: 56
    readonly property int launcherGridIconMedium: 72
    readonly property int launcherGridIconLarge: 92

    // HUD geometry
    readonly property int hudWidth: 300
    readonly property int hudHeight: 50
    readonly property int hudRadius: 25
    readonly property int hudBottomMargin: 40

    // Overview geometry
    readonly property int overviewCellWidth:  240
    readonly property int overviewCellHeight: 150
    readonly property int overviewCellGap:    10
    readonly property int overviewPadding:    20
    readonly property int overviewRadius:     16
    readonly property int overviewCellInset:  4    // tile area inside each cell
    readonly property int overviewWindowMinSize: 20
    readonly property bool overviewLivePreviews: true

    // Connection hub geometry
    readonly property int hubTriggerHeight: 20    // fits inside gaps_out: 20
    readonly property int hubTriggerWidth:  220   // wider than hub for easier hover target
    readonly property int hubWidth:         188
    readonly property int hubHeight:        44
    readonly property int hubMargin:        4
    readonly property int hubDrawerGap:     10
    readonly property int drawerWidth:      380
    readonly property int drawerRadius:     16

    // Wallpaper picker geometry
    readonly property int wallpaperPickerWidth:  980
    readonly property int wallpaperPickerHeight: 720
    readonly property int wallpaperPickerRadius: 16
    readonly property int wallpaperPickerPadding: 14
    readonly property int wallpaperThumbColumns: 6
    readonly property int wallpaperThumbGap: 6
    readonly property int wallpaperThumbRadius: 5
    readonly property int wallpaperThumbBorder: 2
    readonly property string wallpaperPickerFontFamily: "Monaspace Argon NF"
    readonly property int wallpaperPickerTitleSize: 11
    readonly property int wallpaperPickerBodySize: 13
    readonly property int wallpaperPickerRowHeight: 30

    // Notifications geometry
    readonly property int notifRadius: 12              // card (matches barRadius — medium container)
    readonly property int notifIconRadius: 6           // icon slot (small thumb)
    readonly property int notifChipRadius: 12          // pill (radius ≥ chip height/2)
    readonly property int notifPadding: 12             // popup outer padding
    readonly property int notifPaddingCompact: 8       // drawer outer padding
    readonly property int notifIconSize: 48            // popup
    readonly property int notifIconSizeCompact: 32     // drawer
    readonly property int notifIconGap: 12             // icon → text
    readonly property int notifSectionGap: 8           // between bodyArea and chips, between chips
    readonly property int notifTextGap: 4              // between summary and body
    readonly property int notifChipPadding: 10         // chip horizontal padding (per side)
    readonly property int notifChipHeight: 24
    readonly property int notifChipHeightCompact: 22
    readonly property int notifBorderCritical: 2

    // Fonts
    readonly property string fontFamily: "sans-serif"
    readonly property string glyphFont: "Monaspace Argon NF"   // Nerd Font (nf-md-* glyphs)
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
