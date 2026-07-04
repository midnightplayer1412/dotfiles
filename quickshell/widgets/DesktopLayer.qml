import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Bottom-layer host: renders the resolved desktop stacks as absolutely-placed,
// draggable frames. y is computed flush over VISIBLE widgets so hide/reorder
// reflow with no gaps. Input mask = only the widget rects (empty desktop is
// click-through); mask dropped during a drag (same trick as mascot/Mascot.qml).
// If the Task 1 spike FAILED, see the arrange-mode fallback note in the plan.
PanelWindow {
    id: desk
    readonly property string targetName: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    visible: desk.screen && desk.screen.name === targetName

    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    Component.onCompleted: console.log("BUILD widgets-desktop-layer")

    // id -> relevant, reported by frames; bumping the tick recomputes `placed`.
    property var relevance: ({})
    property int relevanceTick: 0
    function setRelevance(id, val) { relevance[id] = val; relevanceTick++; }

    property string draggingId: ""
    property real dragX: 0
    property real dragY: 0

    readonly property var placed: {
        void relevanceTick;
        const out = [];
        const rd = WidgetsConfig.resolvedDesktop;
        const sw = desk.screen ? desk.screen.width : 1920;
        for (const s of rd.stacks) {
            let cy = s.dy;
            for (const id of s.widgets) {
                if (!rd.enabled[id]) continue;
                if (desk.relevance[id] === false) continue;
                const d = WidgetRegistry.descriptors[id];
                const x = s.anchor === "top-right" ? (sw - s.dx - d.w) : s.dx;
                out.push({ id: id, stackId: s.id, x: x, y: cy });
                cy += d.h + 16;
            }
        }
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
            const inStack = desk.placed.filter(p => p.stackId === best.id && p.id !== id);
            let idx = inStack.length;
            for (let k = 0; k < inStack.length; k++) { if (y < inStack[k].y) { idx = k; break; } }
            WidgetsConfig.moveWidget(id, best.id, idx, best.dx, best.dy);
        } else {
            const sh = desk.screen ? desk.screen.height : 1080;
            WidgetsConfig.moveWidget(id, "", 0, Math.max(0, Math.min(x, sw - d.w)), Math.max(0, Math.min(y, sh - d.h)));
        }
    }

    Repeater {
        model: desk.placed
        delegate: Item {
            id: cell
            required property var modelData
            readonly property string wid: modelData.id
            x: desk.draggingId === wid ? desk.dragX : modelData.x
            y: desk.draggingId === wid ? desk.dragY : modelData.y
            z: desk.draggingId === wid ? 100 : 1
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

    // Union of the widget rects — only these grab the pointer; empty desktop is
    // click-through. `regions` is a READ-ONLY list populated solely by declared
    // children (an Instantiator can't feed it), so use a fixed pool of slots each
    // bound to placed[i]; out-of-range slots collapse to 0x0 and contribute
    // nothing. The pool must be >= the max simultaneously-placed widget count; 12
    // covers the current registry with headroom — bump it if the catalog grows.
    Region {
        id: widgetMask
        Region { property var e: desk.placed[0]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[1]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[2]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[3]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[4]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[5]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[6]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[7]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[8]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[9]  ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[10] ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
        Region { property var e: desk.placed[11] ?? null; x: e ? e.x : 0; y: e ? e.y : 0; width: e ? WidgetRegistry.descriptors[e.id].w : 0; height: e ? WidgetRegistry.descriptors[e.id].h : 0 }
    }
    mask: desk.draggingId !== "" ? null : widgetMask
}
