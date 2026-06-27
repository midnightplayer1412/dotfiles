import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import ".."

Rectangle {
    id: root

    readonly property int cellW: Theme.overviewCellWidth
    readonly property int cellH: Theme.overviewCellHeight
    readonly property int gap:   Theme.overviewCellGap
    readonly property int pad:   Theme.overviewPadding
    readonly property int inset: Theme.overviewCellInset
    readonly property int minTile: Theme.overviewWindowMinSize

    readonly property int gridW: OverviewState.columns * cellW + (OverviewState.columns - 1) * gap
    readonly property int gridH: OverviewState.rows    * cellH + (OverviewState.rows    - 1) * gap

    implicitWidth:  gridW + pad * 2
    implicitHeight: gridH + pad * 2

    // Workspace id whose tile is currently being dragged. Used to elevate the
    // source cell's z above all other cells so the dragged tile renders on top
    // even when dragged toward higher-index workspaces.
    property int draggingFromWs: -1

    radius: Theme.overviewRadius
    color:  Theme.surface
    border.color: Theme.outline
    border.width: 1

    // Absorb clicks on widget padding so they don't reach Overview's outer
    // close-catcher. Declared first so the Grid renders above it.
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    Grid {
        anchors.centerIn: parent
        rows:    OverviewState.rows
        columns: OverviewState.columns
        rowSpacing:    root.gap
        columnSpacing: root.gap

        Repeater {
            model: OverviewState.workspaceIds

            Rectangle {
                id: cell

                required property int modelData
                readonly property int wsId: modelData
                readonly property var ws: OverviewState.workspaces.find(w => w.id === wsId) ?? null
                readonly property var windows: OverviewState.windowsForWorkspace(wsId)
                readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
                property bool hovered: false

                // Monitor whose coordinate space this cell mirrors. Fall back
                // to the focused monitor when the workspace itself is inactive
                // (Hyprland leaves .monitor null for unfocused empty workspaces).
                readonly property var monitor: ws?.monitor ?? Hyprland.focusedMonitor
                readonly property int monW: monitor?.width ?? 1920
                readonly property int monH: monitor?.height ?? 1080
                readonly property int monX: monitor?.x ?? 0
                readonly property int monY: monitor?.y ?? 0

                // Scale that fits the whole monitor rect into the cell's inset
                // area, preserving aspect (letter/pillarboxed as needed).
                readonly property real scale: Math.min(
                    (root.cellW - root.inset * 2) / monW,
                    (root.cellH - root.inset * 2) / monH)
                readonly property real offsetX: (root.cellW - monW * scale) / 2
                readonly property real offsetY: (root.cellH - monH * scale) / 2

                width:  root.cellW
                height: root.cellH
                radius: 8
                z: wsId === root.draggingFromWs ? 1000 : 0

                color: hovered ? Theme.surfaceContainer
                              : Qt.darker(Theme.surface, 1.2)
                border.width: active ? 2 : 1
                border.color: active ? Theme.primary : Theme.outline
                // Clip overflowing tiles (windows whose at-coords come from a
                // different monitor than this workspace's). But the SOURCE
                // cell of an in-progress drag must NOT clip, or the dragged
                // tile gets cut off the moment it crosses the cell boundary.
                clip: wsId !== root.draggingFromWs

                Behavior on border.color { ColorAnimation { duration: 120 } }

                // DropArea below clicks/tiles — separate event stream, sees
                // drag enter/exit/drop only.
                DropArea {
                    anchors.fill: parent
                    keys: ["overview-window"]

                    onEntered: cell.hovered = true
                    onExited:  cell.hovered = false

                    onDropped: drop => {
                        const src = drop.source;
                        const addr = src?.address ?? src?.toplevel?.address ?? "";
                        const srcWs = src?.toplevel?.workspace?.id;
                        if (addr && srcWs !== cell.wsId) {
                            OverviewState.moveWindow(addr, cell.wsId);
                        }
                        drop.accept();
                    }
                }

                // Click on cell background (gaps between tiles) jumps to that
                // workspace. Tile MouseAreas sit above and handle their own.
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: cell.hovered = true
                    onExited:  cell.hovered = false
                    onClicked: {
                        OverviewState.focusWorkspace(cell.wsId);
                        OverviewState.close();
                    }
                }

                // Window tiles positioned absolutely from Hyprland window
                // geometry. Repeater children stack above the cell MouseArea
                // (later in declaration order).
                Repeater {
                    model: cell.windows

                    OverviewWindow {
                        id: tile
                        required property var modelData
                        toplevel: modelData
                        constrainTo: root

                        // Report this tile's center (in widget-root `root`
                        // coords) so OverviewState's HJKL navigation can find the
                        // geometrically nearest window. Re-report whenever the
                        // tile's home geometry changes. Uses tileW/tileH (home
                        // size), so an in-progress drag doesn't perturb nav.
                        function reportGeometry() {
                            if (!OverviewState.visible || !tile.address) return;
                            const c = tile.mapToItem(root, tile.tileW / 2, tile.tileH / 2);
                            OverviewState.registerTile(tile.address, c.x, c.y);
                        }
                        Component.onCompleted: reportGeometry()
                        onTileXChanged: reportGeometry()
                        onTileYChanged: reportGeometry()
                        onTileWChanged: reportGeometry()
                        onTileHChanged: reportGeometry()

                        // Armed alt-tab uses its MRU highlight; the sticky
                        // Super+Tab overview uses the keyboard selection. Same
                        // visual (OverviewWindow border/scale), one at a time.
                        highlighted: OverviewState.armed
                            ? OverviewState.highlightedWindow === modelData
                            : OverviewState.keyboardSelectedWindow === modelData

                        // Pull at/size from the raw IPC object (HyprlandToplevel
                        // doesn't expose them as direct properties).
                        readonly property var ipc: modelData?.lastIpcObject ?? ({})
                        readonly property real winX: (ipc.at?.[0] ?? 0) - cell.monX
                        readonly property real winY: (ipc.at?.[1] ?? 0) - cell.monY
                        readonly property real winW: ipc.size?.[0] ?? 100
                        readonly property real winH: ipc.size?.[1] ?? 100

                        // Tiles dropped across monitors via movetoworkspacesilent
                        // can share at-coords because Hyprland doesn't retile
                        // unfocused workspaces. Offset duplicates so the buried
                        // tile still pokes out enough to be clickable. Unique
                        // positions are untouched.
                        readonly property var _sharers: cell.windows.filter(w => {
                            const a = w?.lastIpcObject?.at;
                            return a && a[0] === (ipc.at?.[0] ?? 0)
                                     && a[1] === (ipc.at?.[1] ?? 0);
                        })
                        readonly property int _dupIdx: _sharers.indexOf(modelData)
                        readonly property int _dupOff: _dupIdx > 0 ? _dupIdx * 6 : 0

                        tileX: cell.offsetX + winX * cell.scale + _dupOff
                        tileY: cell.offsetY + winY * cell.scale + _dupOff
                        tileW: Math.max(root.minTile, winW * cell.scale)
                        tileH: Math.max(root.minTile, winH * cell.scale)

                        onClicked: {
                            const addr = toplevel?.address ?? "";
                            if (addr) OverviewState.focusWindow(addr);
                            OverviewState.close();
                        }

                        onDraggingChanged: {
                            if (dragging) {
                                root.draggingFromWs = cell.wsId;
                            } else if (root.draggingFromWs === cell.wsId) {
                                root.draggingFromWs = -1;
                            }
                        }
                    }
                }

                // Workspace number badge — explicit z so it stays above tiles.
                Rectangle {
                    z: 10
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 4
                    width: 22; height: 18
                    radius: 4
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
