import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."

// Exposé layout: every window spread across the whole screen in a computed
// near-square grid (GNOME-Activities style), independent of real window
// positions or workspaces. Reuses the OverviewWindow tile (live preview, icon,
// click-to-focus) since placement here is absolute like the grid's.
Item {
    id: expose

    readonly property var windows: OverviewState.toplevels
    readonly property int n: windows.length

    readonly property int pad: 64
    readonly property int gap: 16
    readonly property int cols: n > 0 ? Math.ceil(Math.sqrt(n)) : 1
    readonly property int rows: n > 0 ? Math.ceil(n / cols) : 1

    readonly property real areaW: width  - pad * 2
    readonly property real areaH: height - pad * 2
    readonly property real cellW: (areaW - (cols - 1) * gap) / cols
    readonly property real cellH: (areaH - (rows - 1) * gap) / rows

    // Fade + slight scale entry.
    opacity: 0
    transform: Scale {
        id: entryScale
        origin.x: expose.width / 2
        origin.y: expose.height / 2
        xScale: 0.98
        yScale: 0.98
    }
    Component.onCompleted: entryAnim.start()
    ParallelAnimation {
        id: entryAnim
        NumberAnimation { target: expose;     property: "opacity"; from: 0;    to: 1; duration: 170; easing.type: Easing.OutCubic }
        NumberAnimation { target: entryScale; property: "xScale";  from: 0.98; to: 1; duration: 170; easing.type: Easing.OutCubic }
        NumberAnimation { target: entryScale; property: "yScale";  from: 0.98; to: 1; duration: 170; easing.type: Easing.OutCubic }
    }

    Repeater {
        model: expose.windows

        OverviewWindow {
            id: tile
            required property var modelData
            required property int index

            toplevel: modelData
            constrainTo: expose
            highlighted: OverviewState.armed
                ? OverviewState.highlightedWindow === modelData
                : OverviewState.keyboardSelectedWindow === modelData

            readonly property int col:  index % expose.cols
            readonly property int rowi: Math.floor(index / expose.cols)

            readonly property var  ipc:  modelData?.lastIpcObject ?? ({})
            readonly property real winW: ipc.size?.[0] ?? 100
            readonly property real winH: ipc.size?.[1] ?? 100
            // Fit the window's aspect ratio inside its cell (letter/pillarboxed).
            readonly property real fit: Math.min((expose.cellW - 8) / winW,
                                                 (expose.cellH - 8) / winH)
            readonly property real tw: Math.max(48, winW * fit)
            readonly property real th: Math.max(48, winH * fit)
            readonly property real cellX: expose.pad + col  * (expose.cellW + expose.gap)
            readonly property real cellY: expose.pad + rowi * (expose.cellH + expose.gap)

            tileX: cellX + (expose.cellW - tw) / 2
            tileY: cellY + (expose.cellH - th) / 2
            tileW: tw
            tileH: th

            // Report center (home geometry) for geometric HJKL nav, in expose coords.
            function reportGeometry() {
                if (!OverviewState.visible || !tile.address) return;
                const c = tile.mapToItem(expose, tile.tileW / 2, tile.tileH / 2);
                OverviewState.registerTile(tile.address, c.x, c.y);
            }
            Component.onCompleted: Qt.callLater(reportGeometry)
            onTileXChanged: reportGeometry()
            onTileYChanged: reportGeometry()

            onClicked: {
                const a = toplevel?.address ?? "";
                if (a) OverviewState.focusWindow(a);
                OverviewState.close();
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: expose.n === 0
        text: "No open windows"
        color: Theme.surfaceText
        opacity: 0.6
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMedium
    }
}
