import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."
import "../ui" as Ui

// Mission Control layout (macOS style): a Spaces strip pinned along the top
// (each workspace as a live mini-monitor), the CURRENT workspace's windows
// spread out in the center, and drag-a-window-onto-a-Space to move it there.
//
// Reuses OverviewState for data/focus/move and the OverviewWindow tile (which
// already emits Drag.keys ["overview-window"]); the top Space thumbnails are
// DropAreas keyed to accept those drags, mirroring the grid layout's cells.
Item {
    id: mc

    readonly property int  activeWs: Hyprland.focusedWorkspace?.id ?? 1
    readonly property var  windows:  OverviewState.windowsForWorkspace(activeWs)
    readonly property int  n:        windows.length

    // Monitor aspect for thumbnails/center scaling.
    readonly property real monAspect: {
        const m = Hyprland.focusedMonitor;
        return (m && m.width > 0 && m.height > 0) ? m.height / m.width : 9 / 16;
    }

    // ── Top Spaces strip geometry ──
    readonly property int  stripTop:  20
    readonly property int  spaceW:    138
    readonly property real spaceH:    spaceW * monAspect
    readonly property int  spaceGap:  12
    readonly property int  spaceInset: 3
    readonly property real stripH:    spaceH + 22

    // Strip layout metrics — the thumbnail Row is centered in mc, so a drop
    // column for workspace i starts at stripLeft + i*(spaceW+spaceGap). The drop
    // columns (see below) are DIRECT children of mc, because a DropArea nested
    // inside the strip's Ui.Surface subtree does not receive dragged windows,
    // whereas a direct child of mc does (verified empirically).
    readonly property int  wsCount:       OverviewState.workspaceIds.length
    readonly property real stripContentW: wsCount * spaceW + (wsCount - 1) * spaceGap
    readonly property real stripLeft:     (width - stripContentW) / 2
    // Which workspace column the dragged window is currently over (-1 = none);
    // drives the thumbnail highlight since the DropArea lives outside the strip.
    property int dropTargetWs: -1

    // ── Center exposé area (below the strip) ──
    readonly property int  pad:     56
    readonly property real areaTop: stripTop + stripH + 28
    readonly property real areaW:   width  - pad * 2
    readonly property real areaH:   height - areaTop - pad
    readonly property int  cols:    n > 0 ? Math.ceil(Math.sqrt(n)) : 1
    readonly property int  rows:    n > 0 ? Math.ceil(n / cols) : 1
    readonly property real cellW:   (areaW - (cols - 1) * 16) / cols
    readonly property real cellH:   (areaH - (rows - 1) * 16) / rows

    // Fade entry.
    opacity: 0
    Component.onCompleted: fadeIn.start()
    NumberAnimation { id: fadeIn; target: mc; property: "opacity"; from: 0; to: 1; duration: 170; easing.type: Easing.OutCubic }

    // Wallpaper backdrop (covers the real desktop so windows aren't shown twice).
    OverviewBackdrop {}

    // ── Spaces strip ──────────────────────────────────────────────────
    Ui.Surface {
        id: strip
        level: 0
        radius: 16
        height: mc.stripH + 12
        anchors.top: parent.top
        anchors.topMargin: mc.stripTop
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property int count: OverviewState.workspaceIds.length
        readonly property real contentW: count * mc.spaceW + (count - 1) * mc.spaceGap
        width: Math.min(contentW + 28, mc.width - 60)

        MouseArea { anchors.fill: parent; onClicked: {} }

        // NOTE: the Spaces row must NOT be wrapped in a Flickable — a DropArea
        // nested inside a Flickable (clip) never receives the dragged window, so
        // drag-to-move silently fails. Grid works because its DropAreas sit in a
        // plain positioner. All workspaces fit on screen, so no scrolling needed.
        Row {
            id: spaceRow
            anchors.centerIn: parent
            height: mc.spaceH
            spacing: mc.spaceGap

                Repeater {
                    model: OverviewState.workspaceIds

                    // ── One Space (workspace thumbnail) ──
                    Rectangle {
                        id: space
                        required property int modelData
                        readonly property int wsId: modelData
                        readonly property var ws: OverviewState.workspaces.find(w => w.id === wsId) ?? null
                        readonly property var wins: OverviewState.windowsForWorkspace(wsId)
                        readonly property bool active: mc.activeWs === wsId

                        readonly property var  monitor: ws?.monitor ?? Hyprland.focusedMonitor
                        readonly property int  monW: monitor?.width  ?? 1920
                        readonly property int  monH: monitor?.height ?? 1080
                        readonly property int  monX: monitor?.x ?? 0
                        readonly property int  monY: monitor?.y ?? 0
                        readonly property real sc: Math.min(
                            (mc.spaceW - mc.spaceInset * 2) / monW,
                            (mc.spaceH - mc.spaceInset * 2) / monH)
                        readonly property real offX: (mc.spaceW - monW * sc) / 2
                        readonly property real offY: (mc.spaceH - monH * sc) / 2

                        anchors.verticalCenter: parent.verticalCenter
                        width: mc.spaceW
                        height: mc.spaceH
                        radius: 6
                        color: dropHover ? Theme.primaryContainer : Qt.darker(Theme.surface, 1.2)
                        border.width: active ? 2 : 1
                        border.color: active || dropHover ? Theme.primary : Theme.outline
                        clip: true
                        readonly property bool dropHover: mc.dropTargetWs === wsId

                        Behavior on color        { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        // Miniature, non-interactive window rects.
                        Repeater {
                            model: space.wins
                            Rectangle {
                                required property var modelData
                                readonly property var ipc: modelData?.lastIpcObject ?? ({})
                                x: space.offX + ((ipc.at?.[0] ?? 0) - space.monX) * space.sc
                                y: space.offY + ((ipc.at?.[1] ?? 0) - space.monY) * space.sc
                                width:  Math.max(4, (ipc.size?.[0] ?? 100) * space.sc)
                                height: Math.max(4, (ipc.size?.[1] ?? 100) * space.sc)
                                radius: 2
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
                                border.width: 1
                                border.color: Theme.outline
                            }
                        }

                        // Workspace number badge.
                        Rectangle {
                            z: 5
                            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 3
                            width: 18; height: 15; radius: 4
                            color: space.active ? Theme.primary : Theme.surfaceContainer
                            opacity: 0.92
                            Text {
                                anchors.centerIn: parent
                                text: space.wsId
                                color: space.active ? Theme.primaryText : Theme.surfaceText
                                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; font.bold: true
                            }
                        }

                        // NOTE: the drop target is NOT here — a DropArea nested
                        // in the strip's Ui.Surface never receives the drag. The
                        // per-workspace drop columns are direct children of mc
                        // (below), and drive this thumbnail's `dropHover` via
                        // mc.dropTargetWs.

                        // Click a Space to switch to it.
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                OverviewState.focusWorkspace(space.wsId);
                                OverviewState.close();
                            }
                        }
                    }
                }
            }
        }

    // ── Drop targets (direct children of mc) ───────────────────────────
    // One drop target per workspace, aligned exactly over its strip panel — so a
    // window only moves when RELEASED on a workspace panel; releasing anywhere
    // else hits no target and the tile snaps back (cancel). This is only usable
    // because the drag proxy puts the drop point under the cursor (see
    // OverviewWindow.dragProxyLongEdge). Kept OUT of the strip's Ui.Surface
    // because a DropArea nested there never receives drags.
    Repeater {
        model: OverviewState.workspaceIds

        DropArea {
            required property int modelData
            required property int index
            readonly property int wsId: modelData

            x: mc.stripLeft + index * (mc.spaceW + mc.spaceGap)
            y: mc.stripTop
            width: mc.spaceW
            height: mc.stripH + 12   // matches the strip panel's height
            keys: ["overview-window"]

            onEntered: mc.dropTargetWs = wsId
            onExited: if (mc.dropTargetWs === wsId) mc.dropTargetWs = -1;
            onDropped: (drop) => {
                const src = drop.source;
                const addr = src?.address ?? src?.toplevel?.address ?? "";
                const srcWs = src?.toplevel?.workspace?.id;
                if (addr && srcWs !== wsId)
                    OverviewState.moveWindow(addr, wsId);
                mc.dropTargetWs = -1;
                drop.accept();
            }
        }
    }

    // ── Center: active workspace's windows spread out ──────────────────
    Repeater {
        model: mc.windows

        OverviewWindow {
            id: tile
            required property var modelData
            required property int index

            toplevel: modelData
            // No constrainTo: the center tiles are large, so clamping them
            // on-screen would keep their center (the drag hotspot) far below the
            // Spaces strip and the drop target would be unreachable. Unclamped,
            // the user can drag a window up so its center enters a Space.
            constrainTo: null
            highlighted: OverviewState.armed
                ? OverviewState.highlightedWindow === modelData
                : OverviewState.keyboardSelectedWindow === modelData

            // macOS-style drag proxy: while dragging, shrink to ~260px around
            // the grab point so a big window doesn't cover the Spaces, and the
            // drop lands under the cursor (see OverviewWindow.dragProxyLongEdge).
            dragProxyLongEdge: 260
            opacity: dragging ? 0.85 : 1.0

            readonly property int col:  index % mc.cols
            readonly property int rowi: Math.floor(index / mc.cols)

            readonly property var  ipc:  modelData?.lastIpcObject ?? ({})
            readonly property real winW: ipc.size?.[0] ?? 100
            readonly property real winH: ipc.size?.[1] ?? 100
            readonly property real fit:  Math.min((mc.cellW - 8) / winW, (mc.cellH - 8) / winH)
            readonly property real tw:   Math.max(48, winW * fit)
            readonly property real th:   Math.max(48, winH * fit)
            readonly property real cellX: mc.pad     + col  * (mc.cellW + 16)
            readonly property real cellY: mc.areaTop + rowi * (mc.cellH + 16)

            tileX: cellX + (mc.cellW - tw) / 2
            tileY: cellY + (mc.cellH - th) / 2
            tileW: tw
            tileH: th

            function reportGeometry() {
                if (!OverviewState.visible || !tile.address) return;
                const c = tile.mapToItem(mc, tile.tileW / 2, tile.tileH / 2);
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
        anchors.horizontalCenter: parent.horizontalCenter
        y: mc.areaTop + mc.areaH / 2 - height / 2
        visible: mc.n === 0
        text: "No windows in this workspace"
        color: Theme.surfaceText
        opacity: 0.6
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMedium
    }
}
