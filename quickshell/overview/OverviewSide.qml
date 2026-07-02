import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."
import "../ui" as Ui

// Side layout: a full-height panel docked to the screen edge OPPOSITE the bar
// (bar left → panel right, bar right → panel left, horizontal bar → left),
// holding a scrollable vertical column of workspace mini-monitors. Per-workspace
// like the grid; reuses the grid's monitor-scaling math and the OverviewWindow
// tile. Tiles focus on click; the cell background jumps to that workspace.
Item {
    id: side

    // Docked edge. "auto" (default) docks opposite the bar; "left"/"right" force
    // a side. Recomputes when the bar moves (auto) or the setting changes.
    readonly property string edge: {
        const p = OverviewConfig.resolvedSidePosition;
        if (p === "left")  return "left";
        if (p === "right") return "right";
        return BarConfig.position === "left"  ? "right"
             : BarConfig.position === "right" ? "left"
             :                                  "left";
    }

    readonly property int panelW: 320
    readonly property int pad:    12
    readonly property int cellGap: 10
    readonly property int inset:  4
    readonly property int cellW:  panelW - pad * 2
    // Cell height from the focused monitor's aspect so mirrors aren't distorted.
    readonly property real monAspect: {
        const m = Hyprland.focusedMonitor;
        return (m && m.width > 0 && m.height > 0) ? m.height / m.width : 9 / 16;
    }
    readonly property real cellH: cellW * monAspect

    // Drag-to-move state. Drop targets are overlaid as direct children of `side`
    // (below) because a DropArea nested in the panel's Flickable/Ui.Surface never
    // receives dragged windows.
    property int dropTargetWs: -1       // workspace the drag is currently over
    property int draggingFromWs: -1     // source workspace of the in-flight drag
    property int scrollDir: 0           // -1 up / +1 down while a drag hovers an edge

    // Auto-scroll the column while a drag hovers the top/bottom edge zones, so a
    // window can be dropped on a workspace that's currently scrolled out of view.
    Timer {
        id: edgeScroll
        interval: 16
        repeat: true
        running: side.scrollDir !== 0 && side.draggingFromWs >= 0
        onTriggered: {
            const maxY = Math.max(0, flick.contentHeight - flick.height);
            const step = side.scrollDir * OverviewConfig.resolvedSideScrollSpeed;
            flick.contentY = Math.max(0, Math.min(maxY, flick.contentY + step));
        }
    }

    // Live geometry of the scroll viewport in `side` coords, for placing the
    // overlay drop targets so they track each cell as the column scrolls.
    readonly property real panelX:    side.edge === "left" ? 16 : side.width - side.panelW - 16
    readonly property real flickLeft: panelX + side.pad
    readonly property real flickTop:  16 + side.pad
    readonly property real flickH:    side.height - 32 - side.pad * 2

    // Wallpaper backdrop (covers the real desktop so windows aren't shown twice).
    OverviewBackdrop {}

    // Follow the selection: with many workspaces the column overflows, so scroll
    // to reveal the workspace holding the HJKL/alt-tab-selected window.
    readonly property var selWin: OverviewState.armed
        ? OverviewState.highlightedWindow : OverviewState.keyboardSelectedWindow
    readonly property int selWsIndex: {
        if (!selWin) return -1;
        const wid = selWin.workspace?.id ?? (selWin.lastIpcObject?.workspace?.id ?? -1);
        return OverviewState.workspaceIds.indexOf(wid);
    }
    onSelWsIndexChanged: Qt.callLater(ensureVisible)
    Component.onCompleted: Qt.callLater(ensureVisible)
    function ensureVisible() {
        if (selWsIndex < 0) return;
        const cellTop    = selWsIndex * (cellH + cellGap);
        const cellBottom = cellTop + cellH;
        const maxY = Math.max(0, flick.contentHeight - flick.height);
        let target = flick.contentY;
        if (cellTop < flick.contentY)                        target = cellTop;
        else if (cellBottom > flick.contentY + flick.height) target = cellBottom - flick.height;
        target = Math.max(0, Math.min(target, maxY));
        if (Math.abs(target - flick.contentY) > 1) {
            scrollAnim.to = target;
            scrollAnim.restart();
        }
    }
    NumberAnimation {
        id: scrollAnim
        target: flick
        property: "contentY"
        duration: 200
        easing.type: Easing.OutCubic
    }

    Ui.Surface {
        id: panel
        level: 0
        radius: 18
        width: side.panelW
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        anchors.left:  side.edge === "left"  ? parent.left  : undefined
        anchors.right: side.edge === "right" ? parent.right : undefined
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        // Slide-in from the docked edge + fade.
        opacity: 0
        transform: Translate { id: slide; x: side.edge === "left" ? -28 : 28 }
        Component.onCompleted: entryAnim.start()
        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { target: slide; property: "x";       to: 0;         duration: 180; easing.type: Easing.OutCubic }
        }

        // Swallow background clicks.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: side.pad
            contentWidth: width
            contentHeight: col.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: col
                width: parent.width
                spacing: side.cellGap

                Repeater {
                    model: OverviewState.workspaceIds

                    // ── Workspace cell ──
                    Rectangle {
                        id: cell
                        required property int modelData
                        readonly property int wsId: modelData
                        readonly property var ws: OverviewState.workspaces.find(w => w.id === wsId) ?? null
                        readonly property var windows: OverviewState.windowsForWorkspace(wsId)
                        readonly property bool active: Hyprland.focusedWorkspace?.id === wsId

                        readonly property var monitor: ws?.monitor ?? Hyprland.focusedMonitor
                        readonly property int monW: monitor?.width  ?? 1920
                        readonly property int monH: monitor?.height ?? 1080
                        readonly property int monX: monitor?.x ?? 0
                        readonly property int monY: monitor?.y ?? 0

                        readonly property real scale: Math.min(
                            (side.cellW - side.inset * 2) / monW,
                            (side.cellH - side.inset * 2) / monH)
                        readonly property real offsetX: (side.cellW - monW * scale) / 2
                        readonly property real offsetY: (side.cellH - monH * scale) / 2

                        readonly property bool dropHover: side.dropTargetWs === wsId

                        width:  side.cellW
                        height: side.cellH
                        radius: 10
                        color: dropHover ? Theme.primaryContainer
                             : hover.hovered ? Theme.surfaceContainer
                             :                 Qt.darker(Theme.surface, 1.2)
                        border.width: dropHover || active ? 2 : 1
                        border.color: dropHover || active ? Theme.primary : Theme.outline
                        // Don't clip the cell a tile is being dragged out of, so
                        // the dragged tile stays visible while crossing to another.
                        clip: side.draggingFromWs !== wsId
                        z: side.draggingFromWs === wsId ? 1000 : 0

                        Behavior on color        { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: hover }
                        // Click on cell background jumps to that workspace.
                        TapHandler {
                            onTapped: {
                                OverviewState.focusWorkspace(cell.wsId);
                                OverviewState.close();
                            }
                        }

                        // Window tiles, positioned from real geometry (tiles sit
                        // above the cell TapHandler, so their own taps win).
                        Repeater {
                            model: cell.windows

                            OverviewWindow {
                                id: tile
                                required property var modelData
                                toplevel: modelData
                                // Unclamped so it can be dragged to another cell's
                                // overlay drop target (see the overlays on `side`).
                                constrainTo: null
                                onDraggingChanged: {
                                    if (dragging) {
                                        side.draggingFromWs = cell.wsId;
                                    } else {
                                        if (side.draggingFromWs === cell.wsId) side.draggingFromWs = -1;
                                        side.scrollDir = 0;
                                    }
                                }
                                highlighted: OverviewState.armed
                                    ? OverviewState.highlightedWindow === modelData
                                    : OverviewState.keyboardSelectedWindow === modelData

                                readonly property var  ipc:  modelData?.lastIpcObject ?? ({})
                                readonly property real winX: (ipc.at?.[0] ?? 0) - cell.monX
                                readonly property real winY: (ipc.at?.[1] ?? 0) - cell.monY
                                readonly property real winW: ipc.size?.[0] ?? 100
                                readonly property real winH: ipc.size?.[1] ?? 100

                                tileX: cell.offsetX + winX * cell.scale
                                tileY: cell.offsetY + winY * cell.scale
                                tileW: Math.max(16, winW * cell.scale)
                                tileH: Math.max(16, winH * cell.scale)

                                function reportGeometry() {
                                    if (!OverviewState.visible || !tile.address) return;
                                    const c = tile.mapToItem(side, tile.tileW / 2, tile.tileH / 2);
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

                        // Workspace number badge.
                        Rectangle {
                            z: 10
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 4
                            width: 22; height: 18
                            radius: 6
                            color: cell.active ? Theme.primary : Theme.surfaceContainer
                            opacity: 0.92
                            Text {
                                anchors.centerIn: parent
                                text: cell.wsId
                                color: cell.active ? Theme.primaryText : Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }

    // Overlay drop targets — one per workspace, tracking each cell's live
    // on-screen rect as the column scrolls. Direct children of `side` because a
    // DropArea nested in the panel's Flickable/Ui.Surface never receives drags.
    // Only active while the cell is within the scroll viewport.
    Repeater {
        model: OverviewState.workspaceIds
        DropArea {
            required property int modelData
            required property int index
            readonly property int wsId: modelData
            readonly property real cellTop:
                side.flickTop + index * (side.cellH + side.cellGap) - flick.contentY

            x: side.flickLeft
            y: cellTop
            width: side.cellW
            height: side.cellH
            enabled: cellTop + side.cellH > side.flickTop
                  && cellTop < side.flickTop + side.flickH
            keys: ["overview-window"]

            onEntered: side.dropTargetWs = wsId
            onExited: if (side.dropTargetWs === wsId) side.dropTargetWs = -1;
            onDropped: (drop) => {
                const src = drop.source;
                const addr = src?.address ?? src?.toplevel?.address ?? "";
                const srcWs = src?.toplevel?.workspace?.id;
                if (addr && srcWs !== wsId)
                    OverviewState.moveWindow(addr, wsId);
                side.dropTargetWs = -1;
                drop.accept();
            }
        }
    }

    // Edge auto-scroll zones at the top/bottom of the viewport. While a drag
    // hovers one, the column scrolls so a workspace that's off-screen can be
    // revealed and dropped on. Declared after the cell overlays so they take
    // priority right at the edges (scroll intent beats drop intent there).
    DropArea {
        x: side.flickLeft; y: side.flickTop
        width: side.cellW; height: 30
        keys: ["overview-window"]
        onEntered: side.scrollDir = -1
        onExited:  if (side.scrollDir === -1) side.scrollDir = 0
    }
    DropArea {
        x: side.flickLeft; y: side.flickTop + side.flickH - 30
        width: side.cellW; height: 30
        keys: ["overview-window"]
        onEntered: side.scrollDir = 1
        onExited:  if (side.scrollDir === 1) side.scrollDir = 0
    }
}
