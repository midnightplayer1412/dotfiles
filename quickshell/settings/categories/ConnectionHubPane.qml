import QtQuick
import QtQuick.Layouts
import "../../connection" as Conn
import "../../ui" as Ui
import "../.."

// Connection Hub settings: reorderable + toggleable tab list (left) and a live
// glyph preview of the hub row (right, inset from edges). Mirrors the Lock Screen
// pane's split layout. Order + visibility are persisted via Conn.HubConfig.
//
// Reorder is drag-and-drop with stable delegates: the Repeater model (`entries`)
// never changes during a drag; instead we reorder a separate key array
// (`slotKeys`) and each row binds its y to its slot, so siblings reflow
// frame-by-frame while the dragged row follows the pointer. (See the repo's
// swipe-collapse-reflow note: drive motion from explicit positions, don't fight
// a positioner.)
Item {
    id: pane

    // Working model — the reconciled tabs. Rebinds when HubConfig changes
    // (e.g. after a toggle/reorder commit). Stable during a drag.
    property var entries: Conn.HubConfig.resolvedTabs

    // Visual order as an array of keys. Plain property (not bound) so it can be
    // mutated freely mid-drag; re-synced from entries whenever not dragging.
    property var slotKeys: []
    property string dragKey: ""        // key being dragged, "" when idle
    readonly property real rowH: 44    // row pitch in px
    property real dragBaseY: 0
    property real dragY: 0

    function syncSlots() {
        if (pane.dragKey !== "") return;          // don't clobber an active drag
        pane.slotKeys = pane.entries.map(e => e.key);
    }
    onEntriesChanged: pane.syncSlots()
    Component.onCompleted: pane.syncSlots()

    function enabledOf(key) {
        const e = pane.entries.find(t => t.key === key);
        return e ? e.enabled : true;
    }

    function updateDrag(dy) {
        const maxY = (pane.slotKeys.length - 1) * pane.rowH;
        pane.dragY = Math.max(0, Math.min(maxY, pane.dragBaseY + dy));
        let target = Math.round(pane.dragY / pane.rowH);
        target = Math.max(0, Math.min(pane.slotKeys.length - 1, target));
        const cur = pane.slotKeys.indexOf(pane.dragKey);
        if (target !== cur && cur >= 0) {
            const arr = pane.slotKeys.slice();
            arr.splice(cur, 1);
            arr.splice(target, 0, pane.dragKey);
            pane.slotKeys = arr;                  // siblings recompute slot & animate
        }
    }

    function commitDrag() {
        if (pane.dragKey === "") return;
        const order = pane.slotKeys.slice();
        pane.dragKey = "";
        Conn.HubConfig.setOrder(order);           // persist; entries → syncSlots
    }

    // ── Live preview (hub glyph row), right, inset from edges ─────────
    Ui.Surface {
        id: preview
        level: 1
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 260
        radius: 14

        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            text: "Preview"
            color: Theme.outline
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        // Glyphs mirror HubTab's default ("on") icon per tab.
        readonly property var glyphs: ({
            "wifi": "\u{F0928}",       // wifi-strength-4
            "bluetooth": "\u{F00AF}",  // bluetooth
            "audio": "\u{F04C3}",      // speaker
            "vpn": "\u{F0582}"         // vpn
        })

        Row {
            anchors.centerIn: parent
            spacing: 14
            Repeater {
                model: pane.slotKeys.filter(k => pane.enabledOf(k))
                delegate: Text {
                    required property var modelData
                    text: preview.glyphs[modelData] || "?"
                    font.family: "Monaspace Argon NF"
                    font.pixelSize: 22
                    color: Theme.surfaceText
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: pane.slotKeys.filter(k => pane.enabledOf(k)).length === 0
            text: "All tabs hidden"
            color: Theme.outline
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }

    // ── Controls, left ────────────────────────────────────────────────
    ColumnLayout {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.right: preview.left
        anchors.rightMargin: 20
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.bottom: parent.bottom
        spacing: 10

        Text {
            text: "Hub tabs"
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
        }
        Text {
            Layout.fillWidth: true
            text: "Drag \u{F01DB} to reorder · toggle to show or hide each tab."
            color: Theme.surfaceText
            opacity: 0.7
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        // Absolute-positioned reorder list.
        Item {
            id: listArea
            Layout.fillWidth: true
            Layout.preferredHeight: pane.entries.length * pane.rowH

            Repeater {
                model: pane.entries
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    readonly property string key: modelData.key
                    readonly property bool isEnabled: modelData.enabled
                    readonly property int slot: pane.slotKeys.indexOf(key)
                    readonly property bool dragging: pane.dragKey === key

                    width: listArea.width
                    height: pane.rowH - 6
                    y: dragging ? pane.dragY : Math.max(0, slot) * pane.rowH
                    z: dragging ? 2 : 1
                    radius: 10
                    color: dragging ? Theme.surfaceContainer : "transparent"
                    border.color: dragging ? Theme.outline : "transparent"
                    border.width: 1

                    Behavior on y {
                        enabled: !row.dragging
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 12

                        // Drag handle
                        Text {
                            text: "\u{F01DB}"           // nf-md-drag
                            font.family: "Monaspace Argon NF"
                            font.pixelSize: 18
                            color: Theme.outline
                            opacity: dragHandler.active ? 1.0 : 0.6
                            DragHandler {
                                id: dragHandler
                                target: null
                                xAxis.enabled: false
                                yAxis.enabled: true
                                cursorShape: Qt.ClosedHandCursor
                                onActiveChanged: {
                                    if (active) {
                                        pane.dragKey = row.key;
                                        pane.dragBaseY = Math.max(0, row.slot) * pane.rowH;
                                        pane.dragY = pane.dragBaseY;
                                    } else {
                                        pane.commitDrag();
                                    }
                                }
                                onActiveTranslationChanged: {
                                    if (active) pane.updateDrag(activeTranslation.y);
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Conn.HubConfig.labels[row.key] || row.key
                            color: Theme.surfaceText
                            opacity: row.isEnabled ? 1.0 : 0.4
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        Ui.Toggle {
                            checked: row.isEnabled
                            onToggled: (v) => Conn.HubConfig.setEnabled(row.key, v)
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }   // bottom spacer
    }
}
