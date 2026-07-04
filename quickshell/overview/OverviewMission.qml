import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."
import "../wallpaper" as Wallpaper

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

    // ── Top Spaces bar geometry ──
    // macOS Mission Control: a frosted, edge-to-edge bar pinned to the top
    // screen edge — full width, square top corners (flush into the screen
    // corners), rounded bottom corners — with the workspace thumbnails centered
    // inside it.
    // Desired tile width from the size setting.
    readonly property real desiredSpaceW: 138 * OverviewConfig.resolvedMissionScale
    readonly property int  spaceGap:  12
    // Effective tile width: the desired width, capped so the whole bar (every
    // workspace tile + gaps + the + button) fits on screen. macOS-style
    // shrink-to-fit — the bar never scrolls, so oversized or too-many tiles
    // shrink to stay visible rather than overflowing off the edges.
    readonly property int  barEdgeMargin: 40
    readonly property int  tileCount:     wsCount + (showAddBtn ? 1 : 0)
    readonly property real fitSpaceW:     tileCount > 0
        ? (width - barEdgeMargin * 2 - (tileCount - 1) * spaceGap) / tileCount
        : desiredSpaceW
    readonly property int  spaceW:    Math.max(40, Math.round(Math.min(desiredSpaceW, fitSpaceW)))
    readonly property real spaceH:    spaceW * monAspect
    readonly property int  spaceInset: 3
    readonly property int  barPadTop:    16
    readonly property int  barPadBottom: 14
    readonly property real barH:         spaceH + barPadTop + barPadBottom
    readonly property int  barRadius:    18

    // ── Workspace set shown in the bar ──
    // Dynamic mode (macOS Spaces): only the occupied workspaces (+ the active
    // one). Hyprland only tracks a workspace while it has windows or is focused,
    // so its live workspace list already IS "occupied + active"; we just sort it
    // and drop specials (id < 1). Fixed mode: the configured 1..N set.
    readonly property var missionWsIds: {
        if (!OverviewConfig.missionDynamic)
            return OverviewState.workspaceIds;
        const ids = OverviewState.workspaces
            .map(w => w.id)
            .filter(id => id >= 1);
        if (activeWs >= 1 && ids.indexOf(activeWs) < 0)
            ids.push(activeWs);
        return ids.sort((a, b) => a - b);
    }
    // Add-workspace (+) button — only in dynamic mode; sits at the end of the
    // Row. Same footprint as a workspace tile (spaceW × spaceH) so it reads as a
    // sibling tile with a centered + icon, not a shrunken mini-workspace.
    readonly property bool showAddBtn: OverviewConfig.missionDynamic
    readonly property real addBtnW:    spaceW

    // Strip layout metrics — the Row (thumbnails + optional + button) is centered
    // in mc, so a drop column for workspace i starts at stripLeft +
    // i*(spaceW+spaceGap). The drop columns (see below) are DIRECT children of
    // mc, because a DropArea nested inside the bar subtree does not receive
    // dragged windows, whereas a direct child of mc does (verified empirically).
    readonly property int  wsCount:      missionWsIds.length
    readonly property real rowContentW:  wsCount * spaceW + (wsCount - 1) * spaceGap
                                          + (showAddBtn ? spaceGap + addBtnW : 0)
    readonly property real stripLeft:    (width - rowContentW) / 2
    // Which workspace column the dragged window is currently over (-1 = none);
    // drives the thumbnail highlight since the DropArea lives outside the strip.
    property int dropTargetWs: -1

    // Smallest workspace id (≥1) with no windows — where the + button lands.
    function nextEmptyWs() {
        const used = new Set(OverviewState.workspaces
            .filter(w => OverviewState.windowsForWorkspace(w.id).length > 0)
            .map(w => w.id));
        let id = 1;
        while (used.has(id)) id++;
        return id;
    }

    // ── Center exposé area (below the bar) ──
    readonly property int  pad:     56
    readonly property real areaTop: barH + 28
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

    // ── Frosted glass behind the bar ───────────────────────────────────
    // macOS vibrancy. The bar sits over the OPAQUE OverviewBackdrop, so the
    // shell's compositor-blur glass (which blurs what's behind the layer) can't
    // show through — we blur in-scene instead. The blur runs FULL-SCREEN so its
    // wallpaper source samples 1:1 with the backdrop (a band-sized blur would
    // squash the whole wallpaper into the band). `frost` is only band-tall, so
    // its layer crops the blur to the top band; an OpacityMask then rounds the
    // bottom corners. NOTE: we do NOT use MultiEffect's own `maskSource` — with
    // auto-padding it scales the mask and reveals only part of the band; the
    // layer-crop + OpacityMask maps 1:1 and covers the whole bar.
    Item {
        id: frost
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: mc.barH
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: frostMask }

        // Full-screen wallpaper, matching OverviewBackdrop's crop so the frost
        // lines up exactly with the sharp wallpaper behind it. Sampled only.
        Image {
            id: frostSrc
            width: mc.width
            height: mc.height
            source: Wallpaper.WallpaperService.currentPath !== ""
                ? "file://" + Wallpaper.WallpaperService.currentPath : ""
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            visible: false
            layer.enabled: true
        }

        // Full-screen blur at the screen origin (frost is at 0,0), so it aligns
        // with the sharp backdrop; frost's band-tall layer crops it to the bar.
        MultiEffect {
            width: mc.width
            height: mc.height
            source: frostSrc
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            brightness: -0.28    // vibrancy darkening
            saturation: -0.10
        }
    }

    // Rounded-bottom / square-top shape masking the frost layer above. The outer
    // Rectangle rounds all corners; the inner top strip re-squares the two TOP
    // corners so the bar meets the screen's top-left/right corners flush.
    Item {
        id: frostMask
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: mc.barH
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: mc.barRadius
            color: "white"
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: mc.barRadius
                color: "white"
            }
        }
    }

    // ── Spaces bar (edge-to-edge, pinned to the top edge) ───────────────
    Item {
        id: strip
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: mc.barH

        // Hairline bottom edge, inset to follow the rounded corners.
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            anchors.leftMargin: mc.barRadius
            anchors.rightMargin: mc.barRadius
            height: 1
            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.16)
        }

        MouseArea { anchors.fill: parent; onClicked: {} }

        // NOTE: the Spaces row must NOT be wrapped in a Flickable — a DropArea
        // nested inside a Flickable (clip) never receives the dragged window, so
        // drag-to-move silently fails. Grid works because its DropAreas sit in a
        // plain positioner. All workspaces fit on screen, so no scrolling needed.
        Row {
            id: spaceRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: mc.barPadTop
            height: mc.spaceH
            spacing: mc.spaceGap

                Repeater {
                    model: mc.missionWsIds

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
                        color: (dropHover || kbSelected) ? Theme.primaryContainer : Qt.darker(Theme.surface, 1.2)
                        border.width: kbSelected ? 3 : active ? 2 : 1
                        border.color: (active || dropHover || kbSelected) ? Theme.primary : Theme.outline
                        clip: true
                        readonly property bool dropHover: mc.dropTargetWs === wsId
                        // Keyboard selection (HJKL Spaces-bar nav): K hops here.
                        readonly property bool kbSelected:
                            OverviewState.navZone === "spaces" && OverviewState.navWs === wsId
                        z: kbSelected ? 10 : 0
                        scale: kbSelected ? 1.05 : 1.0

                        Behavior on color        { ColorAnimation  { duration: 100 } }
                        Behavior on border.color { ColorAnimation  { duration: 120 } }
                        Behavior on scale        { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                        // Report this thumbnail's center (in mc coords) for the
                        // Spaces-bar keyboard nav registry. x changes as the Row
                        // lays out; width changes when the size setting scales it.
                        function reportSpaceGeometry() {
                            if (!OverviewState.visible) return;
                            const c = space.mapToItem(mc, space.width / 2, space.height / 2);
                            OverviewState.registerSpace(space.wsId, c.x, c.y);
                        }
                        Component.onCompleted: Qt.callLater(reportSpaceGeometry)
                        onXChanged: reportSpaceGeometry()
                        onWidthChanged: reportSpaceGeometry()

                        // Miniature window previews, positioned by each window's
                        // real geometry so the thumbnail mirrors the workspace
                        // layout. The colored rect is the frame + fallback; a live
                        // ScreencopyView overlays it and covers the fill when a
                        // capture is available. On capture failure (e.g. NVIDIA
                        // DMA-BUF flakiness) hasContent is false, the preview hides,
                        // and the colored rect shows through — same fallback pattern
                        // as the center tiles and the Dock. Cross-workspace live
                        // capture is proven by the Dock (it captures every window
                        // across all workspaces).
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
                                clip: true

                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: Theme.overviewLivePreviews
                                                && OverviewState.visible
                                                && modelData?.wayland
                                        ? modelData.wayland : null
                                    live: OverviewState.visible
                                    visible: hasContent
                                }
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
                        // in the bar subtree never receives the drag. The
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

                // ── Add-workspace (+) button (dynamic mode only) ──
                // Switches to the next empty workspace and closes the overview,
                // like clicking + in macOS Mission Control. Invisible in fixed
                // mode; Row skips invisible items, so it leaves no gap.
                Rectangle {
                    id: addBtn
                    visible: mc.showAddBtn
                    width: mc.addBtnW
                    height: mc.spaceH
                    radius: 8
                    color: addHover.hovered ? Theme.primaryContainer : Qt.darker(Theme.surface, 1.2)
                    border.width: 1
                    border.color: addHover.hovered ? Theme.primary : Theme.outline

                    Behavior on color        { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\u{F0415}"   // nf-md-plus
                        color: addHover.hovered ? Theme.primary : Theme.surfaceText
                        font.family: Theme.glyphFont
                        font.pixelSize: Math.round(mc.spaceH * 0.4)
                    }

                    HoverHandler { id: addHover }
                    TapHandler {
                        onTapped: {
                            OverviewState.focusWorkspace(mc.nextEmptyWs());
                            OverviewState.close();
                        }
                    }
                }
            }
        }

    // ── Drop targets (direct children of mc) ───────────────────────────
    // One drop target per workspace, aligned exactly over its bar column — so a
    // window only moves when RELEASED on a workspace column; releasing anywhere
    // else hits no target and the tile snaps back (cancel). This is only usable
    // because the drag proxy puts the drop point under the cursor (see
    // OverviewWindow.dragProxyLongEdge). Kept OUT of the bar subtree because a
    // DropArea nested there never receives drags.
    Repeater {
        model: mc.missionWsIds

        DropArea {
            required property int modelData
            required property int index
            readonly property int wsId: modelData

            x: mc.stripLeft + index * (mc.spaceW + mc.spaceGap)
            y: 0
            width: mc.spaceW
            height: mc.barH   // full bar band — a forgiving drop column
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
                : (OverviewState.navZone === "windows"
                    && OverviewState.keyboardSelectedWindow === modelData)

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
