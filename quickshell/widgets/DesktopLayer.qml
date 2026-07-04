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
    id: layer
    readonly property string targetName: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    visible: layer.screen && layer.screen.name === targetName

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
        const sw = layer.screen ? layer.screen.width : 1920;
        for (const s of rd.stacks) {
            let cy = s.dy;
            for (const id of s.widgets) {
                if (!rd.enabled[id]) continue;
                if (layer.relevance[id] === false) continue;
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
        const sw = layer.screen ? layer.screen.width : 1920;
        const d = WidgetRegistry.descriptors[id];
        const cx = x + d.w / 2;
        let best = null, bestDist = 1e9;
        for (const s of rd.stacks) {
            const colX = s.anchor === "top-right" ? (sw - s.dx - d.w) : s.dx;
            const dist = Math.abs((colX + d.w / 2) - cx);
            if (dist < bestDist) { bestDist = dist; best = s; }
        }
        if (best && bestDist < 120) {
            const inStack = layer.placed.filter(p => p.stackId === best.id && p.id !== id);
            let idx = inStack.length;
            for (let k = 0; k < inStack.length; k++) { if (y < inStack[k].y) { idx = k; break; } }
            WidgetsConfig.moveWidget(id, best.id, idx, best.dx, best.dy);
        } else {
            WidgetsConfig.moveWidget(id, "", 0, Math.max(0, Math.min(x, sw - d.w)), Math.max(0, y));
        }
    }

    Repeater {
        model: layer.placed
        delegate: Item {
            id: cell
            required property var modelData
            readonly property string wid: modelData.id
            x: layer.draggingId === wid ? layer.dragX : modelData.x
            y: layer.draggingId === wid ? layer.dragY : modelData.y
            z: layer.draggingId === wid ? 100 : 1
            width: fr.width
            height: fr.height

            WidgetFrame {
                id: fr
                widgetId: cell.wid
                content: WidgetRegistry.componentFor(cell.wid)
                enabled: true
                onRelevantChanged: layer.setRelevance(cell.wid, relevant)
                Component.onCompleted: layer.setRelevance(cell.wid, relevant)
            }

            MouseArea {
                anchors.fill: parent
                property real ox: 0
                property real oy: 0
                onPressed: mouse => { layer.draggingId = cell.wid; layer.dragX = cell.x; layer.dragY = cell.y; ox = mouse.x; oy = mouse.y }
                onPositionChanged: mouse => {
                    if (layer.draggingId !== cell.wid) return;
                    layer.dragX = cell.x + (mouse.x - ox);
                    layer.dragY = cell.y + (mouse.y - oy);
                }
                onReleased: {
                    if (layer.draggingId !== cell.wid) return;
                    layer.commitDrop(cell.wid, layer.dragX, layer.dragY);
                    layer.draggingId = "";
                }
            }
        }
    }

    // Union of the widget rects — only these grab the pointer. Instantiator adds
    // each child Region to the enclosing Region's default children.
    Region {
        id: widgetMask
        Instantiator {
            model: layer.placed
            delegate: Region {
                required property var modelData
                x: modelData.x
                y: modelData.y
                width: WidgetRegistry.descriptors[modelData.id].w
                height: WidgetRegistry.descriptors[modelData.id].h
            }
        }
    }
    mask: layer.draggingId !== "" ? null : widgetMask
}
