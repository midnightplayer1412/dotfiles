import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Bottom-layer host: renders the resolved desktop stacks as absolutely-placed,
// draggable frames. y is computed flush over VISIBLE widgets so hide/reorder
// reflow with no gaps. Input mask = only the widget rects (empty desktop is
// click-through); mask dropped during a drag (like mascot/Mascot.qml).
//
// The Repeater model (`enabledWidgets`) depends ONLY on config, never on
// relevance — so a widget going (ir)relevant repositions cells via the `layout`
// map without recreating delegates. Coupling the model to relevance instead
// caused a binding loop (delegates bump relevanceTick, which rebuilt the model).
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

    // Repeater model: enabled widgets in stack order. Relevance-INDEPENDENT, so
    // it's stable across play/stop etc. — delegates are never recreated by a
    // relevance change (that's what broke before).
    readonly property var enabledWidgets: {
        const out = [];
        const rd = WidgetsConfig.resolvedDesktop;
        for (const s of rd.stacks)
            for (const id of s.widgets)
                if (rd.enabled[id]) out.push({ id: id, stackId: s.id });
        return out;
    }

    // id -> { x, y, visible }. Flush y accumulates over VISIBLE (relevant) widgets
    // only, so hiding one slides the rest up. Depends on relevanceTick; recomputed
    // when a frame reports a changed relevance. Not a delegate model, so no loop.
    readonly property var layout: {
        void relevanceTick;
        const pos = ({});
        const rd = WidgetsConfig.resolvedDesktop;
        const sw = desk.screen ? desk.screen.width : 1920;
        for (const s of rd.stacks) {
            let cy = s.dy;
            for (const id of s.widgets) {
                if (!rd.enabled[id]) continue;
                const d = WidgetRegistry.descriptors[id];
                const x = s.anchor === "top-right" ? (sw - s.dx - d.w) : s.dx;
                const vis = desk.relevance[id] !== false;
                pos[id] = { x: x, y: cy, stackId: s.id, visible: vis };
                if (vis) cy += d.h + 16;
            }
        }
        return pos;
    }

    // Visible placed widgets (for the input mask + drop hit-testing).
    readonly property var placedVisible: {
        void relevanceTick;
        const out = [];
        const lay = desk.layout;
        const rd = WidgetsConfig.resolvedDesktop;
        for (const s of rd.stacks)
            for (const id of s.widgets)
                if (rd.enabled[id] && lay[id] && lay[id].visible)
                    out.push({ id: id, stackId: s.id, x: lay[id].x, y: lay[id].y });
        return out;
    }

    // Nearest column within 120px => insert there by y; else free drop at (x,y).
    function commitDrop(id, x, y) {
        const rd = WidgetsConfig.resolvedDesktop;
        const sw = desk.screen ? desk.screen.width : 1920;
        const d = WidgetRegistry.descriptors[id];
        const cx = x + d.w / 2;
        let best = null, bestDist = 1e9;
        for (const s of rd.stacks) {
            const colX = s.anchor === "top-right" ? (sw - s.dx - d.w) : s.dx;
            const dist = Math.abs((colX + d.w / 2) - cx);
            if (dist < bestDist) { bestDist = dist; best = s; }
        }
        if (best && bestDist < 120) {
            const inStack = desk.placedVisible.filter(p => p.stackId === best.id && p.id !== id);
            let idx = inStack.length;
            for (let k = 0; k < inStack.length; k++) { if (y < inStack[k].y) { idx = k; break; } }
            WidgetsConfig.moveWidget(id, best.id, idx, best.dx, best.dy);
        } else {
            const sh = desk.screen ? desk.screen.height : 1080;
            WidgetsConfig.moveWidget(id, "", 0, Math.max(0, Math.min(x, sw - d.w)), Math.max(0, Math.min(y, sh - d.h)));
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
            z: desk.draggingId === wid ? 100 : 1
            visible: pos.visible
            width: fr.width
            height: fr.height

            WidgetFrame {
                id: fr
                widgetId: cell.wid
                content: WidgetRegistry.componentFor(cell.wid)
                enabled: true
                onRelevantChanged: desk.setRelevance(cell.wid, relevant)
                Component.onCompleted: desk.setRelevance(cell.wid, relevant)
            }

            MouseArea {
                anchors.fill: parent
                property real ox: 0
                property real oy: 0
                // Capture the widget's real position BEFORE flipping draggingId:
                // setting draggingId re-evaluates cell.x/y to read dragX/dragY, so
                // reading cell.x afterwards would return a stale value (widget would
                // snap to 0,0). Order matters — draggingId is set last.
                onPressed: mouse => { desk.dragX = cell.x; desk.dragY = cell.y; ox = mouse.x; oy = mouse.y; desk.draggingId = cell.wid }
                onPositionChanged: mouse => {
                    if (desk.draggingId !== cell.wid) return;
                    desk.dragX = cell.x + (mouse.x - ox);
                    desk.dragY = cell.y + (mouse.y - oy);
                }
                onReleased: {
                    if (desk.draggingId !== cell.wid) return;
                    desk.commitDrop(cell.wid, desk.dragX, desk.dragY);
                    desk.draggingId = "";
                }
            }
        }
    }

    // Union of the VISIBLE widget rects — only these grab the pointer; empty
    // desktop is click-through. `regions` is a READ-ONLY list populated solely by
    // declared children (an Instantiator can't feed it), so use a fixed pool of
    // slots each bound to placedVisible[i]; out-of-range slots collapse to 0x0 and
    // add nothing. Pool must be >= max simultaneously-placed widgets; 12 covers
    // the current registry with headroom — bump it if the catalog grows past 12.
    Region {
        id: widgetMask
        Region { property var e: desk.placedVisible[0]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[1]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[2]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[3]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[4]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[5]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[6]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[7]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[8]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[9]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[10] ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placedVisible[11] ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
    }
    mask: desk.draggingId !== "" ? null : widgetMask
}
