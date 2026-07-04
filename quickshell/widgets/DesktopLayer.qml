import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Bottom-layer host: renders the resolved desktop stacks as absolutely-placed,
// draggable, resizable frames. y is computed flush over VISIBLE widgets (at their
// scaled size) so hide/reorder/resize reflow with no gaps. Input mask = only the
// widget rects (empty desktop is click-through); mask dropped during a drag.
//
// The Repeater model (`enabledWidgets`) depends ONLY on config, never on
// relevance/scale-in-progress — so those reposition cells via the `layout` map
// without recreating delegates.
PanelWindow {
    id: desk
    readonly property string targetName: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    visible: desk.screen && desk.screen.name === targetName

    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    Component.onCompleted: console.log("BUILD widgets-desktop-layer")

    // id -> relevant, reported by frames. Only bump the tick on a real change so
    // stable relevance doesn't churn the layout.
    property var relevance: ({})
    property int relevanceTick: 0
    function setRelevance(id, val) {
        if (relevance[id] === val) return;
        relevance[id] = val;
        relevanceTick++;
    }

    property string draggingId: ""
    property real dragX: 0
    property real dragY: 0

    // ── Resize (per-widget aspect-locked scale) ──
    // While a grip is dragged, resizingScale overrides the persisted scale so the
    // widget (and the stack around it) resizes live.
    property string resizingId: ""
    property real resizingScale: 1
    function scaleFor(id) { return desk.resizingId === id ? desk.resizingScale : WidgetsConfig.scaleOf(id); }
    function effW(id) { return WidgetRegistry.descriptors[id].w * desk.scaleFor(id); }
    function effH(id) { return WidgetRegistry.descriptors[id].h * desk.scaleFor(id); }

    // Repeater model: enabled widgets in stack order. Relevance/scale-INDEPENDENT.
    readonly property var enabledWidgets: {
        const out = [];
        const rd = WidgetsConfig.resolvedDesktop;
        for (const s of rd.stacks)
            for (const id of s.widgets)
                if (rd.enabled[id]) out.push({ id: id, stackId: s.id });
        return out;
    }

    // id -> { x, y, visible, w, h }. Flush y accumulates over VISIBLE widgets at
    // their scaled height. Depends on relevanceTick + scaleFor (resizing/scaleOf).
    readonly property var layout: {
        void relevanceTick;
        const pos = ({});
        const rd = WidgetsConfig.resolvedDesktop;
        const sw = desk.screen ? desk.screen.width : 1920;
        for (const s of rd.stacks) {
            let cy = s.dy;
            for (const id of s.widgets) {
                if (!rd.enabled[id]) continue;
                const ew = desk.effW(id), eh = desk.effH(id);
                const x = s.anchor === "top-right" ? (sw - s.dx - ew) : s.dx;
                const vis = desk.relevance[id] !== false;
                pos[id] = { x: x, y: cy, stackId: s.id, visible: vis, w: ew, h: eh };
                if (vis) cy += eh + 16;
            }
        }
        return pos;
    }

    // Visible placed widgets (for the input mask + drop hit-testing), scaled.
    readonly property var placedVisible: {
        void relevanceTick;
        const out = [];
        const lay = desk.layout;
        const rd = WidgetsConfig.resolvedDesktop;
        for (const s of rd.stacks)
            for (const id of s.widgets)
                if (rd.enabled[id] && lay[id] && lay[id].visible)
                    out.push({ id: id, stackId: s.id, x: lay[id].x, y: lay[id].y, w: lay[id].w, h: lay[id].h });
        return out;
    }

    // Nearest column within 120px => insert there by y; else free drop at (x,y).
    function commitDrop(id, x, y) {
        const rd = WidgetsConfig.resolvedDesktop;
        const sw = desk.screen ? desk.screen.width : 1920;
        const ew = desk.effW(id), eh = desk.effH(id);
        const cx = x + ew / 2;
        let best = null, bestDist = 1e9;
        for (const s of rd.stacks) {
            const colX = s.anchor === "top-right" ? (sw - s.dx - ew) : s.dx;
            const dist = Math.abs((colX + ew / 2) - cx);
            if (dist < bestDist) { bestDist = dist; best = s; }
        }
        if (best && bestDist < 120) {
            const inStack = desk.placedVisible.filter(p => p.stackId === best.id && p.id !== id);
            let idx = inStack.length;
            for (let k = 0; k < inStack.length; k++) { if (y < inStack[k].y) { idx = k; break; } }
            WidgetsConfig.moveWidget(id, best.id, idx, best.dx, best.dy);
        } else {
            const sh = desk.screen ? desk.screen.height : 1080;
            WidgetsConfig.moveWidget(id, "", 0, Math.max(0, Math.min(x, sw - ew)), Math.max(0, Math.min(y, sh - eh)));
        }
    }

    // Faint dotted grid, shown only while dragging with snap on, as a snap target.
    Canvas {
        id: gridOverlay
        anchors.fill: parent
        z: 0
        visible: desk.draggingId !== "" && WidgetsConfig.snapEnabled
        opacity: 0.18
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = Theme.surfaceText;
            const g = WidgetsConfig.resolvedGridSize;
            for (let gx = 0; gx < width; gx += g)
                for (let gy = 0; gy < height; gy += g)
                    ctx.fillRect(gx, gy, 2, 2);
        }
    }

    Repeater {
        model: desk.enabledWidgets
        delegate: Item {
            id: cell
            required property var modelData
            readonly property string wid: modelData.id
            readonly property var pos: desk.layout[wid] ?? ({ x: 0, y: 0, visible: false })
            x: desk.draggingId === wid ? desk.dragX : pos.x
            y: desk.draggingId === wid ? desk.dragY : pos.y
            z: (desk.draggingId === wid || desk.resizingId === wid) ? 100 : 1
            visible: pos.visible
            width: fr.width
            height: fr.height

            HoverHandler { id: cellHover }

            WidgetFrame {
                id: fr
                widgetId: cell.wid
                content: WidgetRegistry.componentFor(cell.wid)
                enabled: true
                scaleFactor: desk.scaleFor(cell.wid)
                onRelevantChanged: desk.setRelevance(cell.wid, relevant)
                Component.onCompleted: desk.setRelevance(cell.wid, relevant)
            }

            // Move drag — snaps to the grid unless snap is off or Shift is held.
            MouseArea {
                id: moveArea
                anchors.fill: parent
                property real ox: 0
                property real oy: 0
                // Capture position BEFORE flipping draggingId (else cell.x reads
                // the drag value and the widget snaps to 0,0).
                onPressed: mouse => { desk.dragX = cell.x; desk.dragY = cell.y; ox = mouse.x; oy = mouse.y; desk.draggingId = cell.wid }
                onPositionChanged: mouse => {
                    if (desk.draggingId !== cell.wid) return;
                    let nx = cell.x + (mouse.x - ox);
                    let ny = cell.y + (mouse.y - oy);
                    if (WidgetsConfig.snapEnabled && !(mouse.modifiers & Qt.ShiftModifier)) {
                        const g = WidgetsConfig.resolvedGridSize;
                        nx = Math.round(nx / g) * g;
                        ny = Math.round(ny / g) * g;
                    }
                    desk.dragX = nx;
                    desk.dragY = ny;
                }
                onReleased: {
                    if (desk.draggingId !== cell.wid) return;
                    desk.commitDrop(cell.wid, desk.dragX, desk.dragY);
                    desk.draggingId = "";
                }
            }

            // Resize grip — bottom-right, shown on hover. Owns its own drag (above
            // moveArea) so resizing never moves the widget; maps the cursor's
            // cell-local position to an aspect-locked scale.
            Rectangle {
                id: grip
                width: 16; height: 16; radius: 4
                x: cell.width - width - 3
                y: cell.height - height - 3
                z: 10
                color: Theme.primary
                border.width: 1; border.color: Theme.primaryText
                opacity: (cellHover.hovered || desk.resizingId === cell.wid) ? 0.9 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                MouseArea {
                    id: resizeArea
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.SizeFDiagCursor
                    // Fixed reference (widget top-left in desk coords) + press value,
                    // captured once at press so a resizing/right-anchored cell whose
                    // origin moves can't feed back into the scale (runaway).
                    property real refX: 0
                    property real refY: 0
                    property real baseScale: 1
                    property real pressVal: 0
                    function _val(mx, my) {
                        const c = mapToItem(desk, mx, my);
                        const d = WidgetRegistry.descriptors[cell.wid];
                        return ((c.x - refX) / d.w + (c.y - refY) / d.h) / 2;
                    }
                    onPressed: mouse => {
                        const tl = cell.mapToItem(desk, 0, 0);
                        refX = tl.x; refY = tl.y;
                        baseScale = WidgetsConfig.scaleOf(cell.wid);
                        pressVal = _val(mouse.x, mouse.y);
                        desk.resizingScale = baseScale;
                        desk.resizingId = cell.wid;
                    }
                    onPositionChanged: mouse => {
                        if (desk.resizingId !== cell.wid) return;
                        const s = baseScale + (_val(mouse.x, mouse.y) - pressVal);
                        desk.resizingScale = Math.max(WidgetsConfig.scaleMin, Math.min(WidgetsConfig.scaleMax, s));
                    }
                    onReleased: {
                        if (desk.resizingId !== cell.wid) return;
                        WidgetsConfig.setScale(cell.wid, desk.resizingScale);
                        desk.resizingId = "";
                    }
                }
            }
        }
    }

    // Union of the VISIBLE widget rects (scaled) — only these grab the pointer.
    // Fixed pool of slots bound to placedVisible[i]; out-of-range slots collapse
    // to 0x0. Pool must be >= max simultaneously-placed widgets (12 = headroom).
    Region {
        id: widgetMask
        Region { property var e: desk.placedVisible[0]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[1]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[2]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[3]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[4]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[5]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[6]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[7]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[8]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[9]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[10] ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
        Region { property var e: desk.placedVisible[11] ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? e.w : 0; height: e ? e.h : 0 }
    }
    // Drop the mask while dragging OR resizing so the gesture keeps receiving
    // pointer events after the cursor leaves the widget's (masked) rect.
    mask: (desk.draggingId !== "" || desk.resizingId !== "") ? null : widgetMask
}
