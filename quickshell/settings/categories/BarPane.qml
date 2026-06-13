import QtQuick
import QtQuick.Layouts
import "../../ui" as Ui
import "../.."

// Bar settings: position + appearance + a drag-drop widget board.
//
// Board reuses the Connection Hub's reorder idea (stable Repeater model, a
// mutable slot structure the drag mutates, rows bound to computed positions so
// siblings reflow frame-by-frame) — generalized from one list to four fixed
// columns (start / center / end / hidden). Columns have fixed x-ranges, so the
// drag target is just pointer-X → column, pointer-Y → slot.
Item {
    id: pane

    readonly property var positions: ["left", "right", "top", "bottom"]
    readonly property var cols: ["start", "center", "end", "hidden"]
    readonly property var colTitles: ({
        "start":  BarConfig.horizontal ? "Left"  : "Top",
        "center": "Center",
        "end":    BarConfig.horizontal ? "Right" : "Bottom",
        "hidden": "Hidden"
    })

    // ── Drag state ──
    // Mutable per-column key arrays. Re-synced from BarConfig when idle; mutated
    // freely during a drag (never rebound mid-drag, so it won't clobber motion).
    property var slots: ({ start: [], center: [], end: [], hidden: [] })
    property string dragKey: ""
    property real dragX: 0
    property real dragY: 0
    property real dragBaseX: 0
    property real dragBaseY: 0

    readonly property real headerH: 24
    readonly property real rowH: 34

    function syncSlots() {
        if (pane.dragKey !== "") return;
        const r = BarConfig.resolved;
        pane.slots = ({
            start:  r.start.slice(),
            center: r.center.slice(),
            end:    r.end.slice(),
            hidden: BarConfig.hidden.slice()
        });
    }
    Component.onCompleted: pane.syncSlots()
    Connections {
        target: BarConfig
        function onLayoutChanged() { pane.syncSlots() }
    }

    function locate(key) {
        for (const c of pane.cols) {
            const i = pane.slots[c].indexOf(key);
            if (i >= 0) return ({ col: c, slot: i });
        }
        return ({ col: "hidden", slot: 0 });
    }

    function updateDrag(tx, ty) {
        pane.dragX = pane.dragBaseX + tx;
        pane.dragY = pane.dragBaseY + ty;

        const colW = board.width / 4;
        const cx = pane.dragX + colW / 2;
        const cy = pane.dragY + pane.rowH / 2;

        let ci = Math.floor(cx / colW);
        ci = Math.max(0, Math.min(3, ci));
        const colName = pane.cols[ci];

        const loc = pane.locate(pane.dragKey);
        const ns = ({
            start:  pane.slots.start.slice(),
            center: pane.slots.center.slice(),
            end:    pane.slots.end.slice(),
            hidden: pane.slots.hidden.slice()
        });
        ns[loc.col].splice(loc.slot, 1);                 // pull out of current spot
        let tSlot = Math.round((cy - pane.headerH) / pane.rowH);
        tSlot = Math.max(0, Math.min(ns[colName].length, tSlot));
        ns[colName].splice(tSlot, 0, pane.dragKey);      // drop into target

        if (JSON.stringify(ns) !== JSON.stringify(pane.slots)) pane.slots = ns;
    }

    function commitDrag() {
        if (pane.dragKey === "") return;
        const layout = ({
            start:  pane.slots.start.slice(),
            center: pane.slots.center.slice(),
            end:    pane.slots.end.slice()
        });
        pane.dragKey = "";
        BarConfig.setLayout(layout);   // keys not in any zone become hidden
    }

    // ── Controls + board ──────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Position
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Position"; color: Theme.surfaceText; Layout.fillWidth: true
                font.family: Theme.fontFamily; font.pixelSize: 13
            }
            Ui.Dropdown {
                Layout.preferredWidth: 150
                model: [ "Left", "Right", "Top", "Bottom" ]
                currentIndex: Math.max(0, pane.positions.indexOf(BarConfig.position))
                onActivated: (i) => { BarConfig.position = pane.positions[i]; BarConfig.save(); }
            }
        }

        // Appearance
        Text {
            text: "Appearance"; color: Theme.primary; Layout.topMargin: 2
            font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
        }
        component SliderRow: RowLayout {
            property string label: ""
            property alias from: s.from
            property alias to: s.to
            property alias stepSize: s.stepSize
            property real value: 0
            signal moved(real v)
            signal committed()
            Layout.fillWidth: true
            spacing: 10
            Text {
                text: parent.label; color: Theme.surfaceText; Layout.preferredWidth: 80
                font.family: Theme.fontFamily; font.pixelSize: 13
            }
            Ui.Slider {
                id: s
                Layout.fillWidth: true
                value: parent.value
                onMoved: (v) => parent.moved(v)
                onReleased: parent.committed()
            }
        }
        SliderRow {
            label: "Thickness"; from: 32; to: 72; stepSize: 2
            value: BarConfig.thickness
            onMoved: (v) => BarConfig.thickness = v
            onCommitted: BarConfig.save()
        }
        SliderRow {
            label: "Opacity"; from: 0.3; to: 1.0; stepSize: 0.05
            value: BarConfig.bgOpacity
            onMoved: (v) => BarConfig.bgOpacity = v
            onCommitted: BarConfig.save()
        }
        SliderRow {
            label: "Corner radius"; from: 0; to: 24; stepSize: 1
            value: BarConfig.radius
            onMoved: (v) => BarConfig.radius = v
            onCommitted: BarConfig.save()
        }
        SliderRow {
            // Pads the bar's two ends along its length: top/bottom for a vertical
            // bar, left/right for a horizontal one.
            label: BarConfig.horizontal ? "L/R padding" : "T/B padding"
            from: 0; to: 24; stepSize: 1
            value: BarConfig.endPadding
            onMoved: (v) => BarConfig.endPadding = v
            onCommitted: BarConfig.save()
        }

        // Widget board
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Text {
                text: "Widgets"; color: Theme.primary; Layout.fillWidth: true
                font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
            }
            // Restores position + appearance + layout to the known-good baseline,
            // so over-tuning is always one click from working again.
            Rectangle {
                Layout.preferredHeight: 28
                implicitWidth: resetLabel.implicitWidth + 22
                radius: 8
                color: resetMouse.containsMouse ? Theme.surfaceContainer : "transparent"
                border.width: 1
                border.color: Theme.outline
                Text {
                    id: resetLabel
                    anchors.centerIn: parent
                    text: "Reset to defaults"
                    color: resetMouse.containsMouse ? Theme.primary : Theme.surfaceText
                    font.family: Theme.fontFamily; font.pixelSize: 12
                }
                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BarConfig.resetDefaults()
                }
            }
        }
        Text {
            Layout.fillWidth: true
            text: "Drag widgets between columns to place them; drag within a column to reorder. Anything in Hidden is off."
            color: Theme.surfaceText; opacity: 0.7; wrapMode: Text.WordWrap
            font.family: Theme.fontFamily; font.pixelSize: 12
        }

        Item {
            id: board
            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property real colW: width / 4
            // Tallest column drives how far rows can travel.
            readonly property int maxRows: Math.max(
                pane.slots.start.length, pane.slots.center.length,
                pane.slots.end.length, pane.slots.hidden.length, 1)

            // Column backdrops + headers.
            Repeater {
                model: pane.cols
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    x: index * board.colW + 3
                    y: 0
                    width: board.colW - 6
                    height: board.height
                    radius: 10
                    color: modelData === "hidden" ? "transparent" : Theme.surfaceContainer
                    opacity: modelData === "hidden" ? 1 : 0.4
                    border.width: modelData === "hidden" ? 1 : 0
                    border.color: Theme.outline
                    Text {
                        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: 5
                        text: pane.colTitles[modelData]
                        color: Theme.outline
                        font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true
                    }
                }
            }

            // Widget chips — stable model (knownKeys); position from `slots`.
            Repeater {
                model: BarConfig.knownKeys
                delegate: Rectangle {
                    id: chip
                    required property string modelData
                    readonly property var loc: pane.locate(modelData)
                    readonly property bool dragging: pane.dragKey === modelData

                    width: board.colW - 14
                    height: pane.rowH - 6
                    x: dragging ? pane.dragX : pane.cols.indexOf(loc.col) * board.colW + 7
                    y: dragging ? pane.dragY : pane.headerH + loc.slot * pane.rowH
                    z: dragging ? 10 : 1
                    radius: 8
                    color: dragging ? Theme.primary
                         : (loc.col === "hidden" ? Theme.surface : Theme.surfaceContainer)
                    border.width: 1
                    border.color: dragging ? Theme.primary : Theme.outline

                    Behavior on x { enabled: !chip.dragging; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on y { enabled: !chip.dragging; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 7
                        anchors.rightMargin: 6
                        spacing: 5
                        Text {
                            Layout.fillWidth: true
                            text: BarConfig.labels[chip.modelData] || chip.modelData
                            elide: Text.ElideRight
                            color: chip.dragging ? Theme.primaryText
                                 : (chip.loc.col === "hidden" ? Theme.outline : Theme.surfaceText)
                            font.family: Theme.fontFamily; font.pixelSize: 12
                        }
                        Text {
                            text: "\u{F01DB}"   // nf-md-drag
                            font.family: Theme.glyphFont; font.pixelSize: 15
                            color: chip.dragging ? Theme.primaryText : Theme.outline
                        }
                    }

                    DragHandler {
                        target: null
                        xAxis.enabled: true
                        yAxis.enabled: true
                        cursorShape: Qt.ClosedHandCursor
                        onActiveChanged: {
                            if (active) {
                                pane.dragKey = chip.modelData;
                                pane.dragBaseX = pane.cols.indexOf(chip.loc.col) * board.colW + 7;
                                pane.dragBaseY = pane.headerH + chip.loc.slot * pane.rowH;
                                pane.dragX = pane.dragBaseX;
                                pane.dragY = pane.dragBaseY;
                            } else {
                                pane.commitDrag();
                            }
                        }
                        onActiveTranslationChanged: if (active) pane.updateDrag(activeTranslation.x, activeTranslation.y)
                    }
                }
            }
        }
    }
}
