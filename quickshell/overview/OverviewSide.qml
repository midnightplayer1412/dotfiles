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

    // Dock opposite the bar; recomputes if the bar moves.
    readonly property string edge:
        BarConfig.position === "left"  ? "right" :
        BarConfig.position === "right" ? "left"  : "left"

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

                        width:  side.cellW
                        height: side.cellH
                        radius: 10
                        color: hover.hovered ? Theme.surfaceContainer
                                            : Qt.darker(Theme.surface, 1.2)
                        border.width: active ? 2 : 1
                        border.color: active ? Theme.primary : Theme.outline
                        clip: true

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
                                constrainTo: cell
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
}
