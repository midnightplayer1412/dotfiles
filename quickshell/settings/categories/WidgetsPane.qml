import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../ui" as Ui
import "../../widgets" as Widgets
import "../.."

// Widgets settings: enable each widget per surface, reorder the dashboard, set
// the weather location, and restore defaults. Rows are driven by the registry,
// so newly-registered widgets appear here automatically.
Item {
    id: pane

    Ui.ScrollView {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Widgets"; color: Theme.primary; Layout.fillWidth: true
                font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
            }
            Ui.Button {
                kind: "ghost"; text: "Restore default layout"; fontSize: 12
                onClicked: Widgets.WidgetsConfig.restoreDefaults()
            }
        }
        Text {
            Layout.fillWidth: true
            text: "Toggle each widget on the desktop or the SUPER+W dashboard. Drag widgets on the desktop to place them; positions are saved."
            color: Theme.surfaceText; opacity: 0.7; wrapMode: Text.WordWrap
            font.family: Theme.fontFamily; font.pixelSize: 12
        }

        // Per-widget surface toggles.
        Rectangle {
            Layout.fillWidth: true; Layout.topMargin: 4
            radius: 12; color: Qt.darker(Theme.surface, 1.06)
            border.width: 1; border.color: Theme.outline
            implicitHeight: toggles.implicitHeight + 28

            ColumnLayout {
                id: toggles
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Text { text: "Desktop"; color: Theme.surfaceText; opacity: 0.6
                           Layout.preferredWidth: 80; horizontalAlignment: Text.AlignHCenter
                           font.family: Theme.fontFamily; font.pixelSize: 11 }
                    Text { text: "Dashboard"; color: Theme.surfaceText; opacity: 0.6
                           Layout.preferredWidth: 80; horizontalAlignment: Text.AlignHCenter
                           font.family: Theme.fontFamily; font.pixelSize: 11 }
                }

                Repeater {
                    model: Widgets.WidgetRegistry.ids
                    delegate: RowLayout {
                        required property var modelData
                        readonly property var rd: Widgets.WidgetsConfig.resolvedDesktop
                        readonly property var rdash: Widgets.WidgetsConfig.resolvedDashboard
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: Widgets.WidgetRegistry.descriptors[modelData].label
                            color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 13
                        }
                        Item {
                            Layout.preferredWidth: 80
                            implicitHeight: dtog.implicitHeight
                            Ui.Toggle {
                                id: dtog; anchors.horizontalCenter: parent.horizontalCenter
                                checked: rd.enabled[modelData]
                                onToggled: Widgets.WidgetsConfig.toggleDesktop(modelData)
                            }
                        }
                        Item {
                            Layout.preferredWidth: 80
                            implicitHeight: btog.implicitHeight
                            Ui.Toggle {
                                id: btog; anchors.horizontalCenter: parent.horizontalCenter
                                checked: rdash.enabled[modelData]
                                onToggled: Widgets.WidgetsConfig.toggleDashboard(modelData)
                            }
                        }
                    }
                }
            }
        }

        // Dashboard order (▲/▼ swap with the neighbour).
        Rectangle {
            Layout.fillWidth: true; Layout.topMargin: 8
            radius: 12; color: Qt.darker(Theme.surface, 1.06)
            border.width: 1; border.color: Theme.outline
            implicitHeight: orderCol.implicitHeight + 28

            ColumnLayout {
                id: orderCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 8

                Text { text: "Dashboard order"; color: Theme.primary
                       font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }

                Text {
                    Layout.fillWidth: true
                    text: "Drag to reorder how widgets appear in the dashboard."
                    color: Theme.surfaceText; opacity: 0.7; wrapMode: Text.WordWrap
                    font.family: Theme.fontFamily; font.pixelSize: 12
                }

                // Drag-to-reorder board (same pattern as the Bar widget board):
                // stable Repeater model (registry ids), a mutable `slots` array the
                // drag mutates, rows bound to computed y so siblings reflow live.
                Item {
                    id: orderBoard
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Layout.preferredHeight: Math.max(1, orderBoard.slots.length) * orderBoard.rowH

                    readonly property real rowH: 38
                    // Mutable order. Re-synced from config when idle; mutated freely
                    // during a drag (never rebound mid-drag, so motion isn't clobbered).
                    property var slots: []
                    property string dragKey: ""
                    property real dragY: 0
                    property real dragBaseY: 0

                    function syncSlots() {
                        if (orderBoard.dragKey !== "") return;
                        orderBoard.slots = Widgets.WidgetsConfig.resolvedDashboard.order.slice();
                    }
                    Component.onCompleted: orderBoard.syncSlots()
                    Connections {
                        target: Widgets.WidgetsConfig
                        function onResolvedDashboardChanged() { orderBoard.syncSlots() }
                    }

                    function updateDrag(ty) {
                        orderBoard.dragY = orderBoard.dragBaseY + ty;
                        const cur = orderBoard.slots.indexOf(orderBoard.dragKey);
                        if (cur < 0) return;
                        let tgt = Math.round(orderBoard.dragY / orderBoard.rowH);
                        tgt = Math.max(0, Math.min(orderBoard.slots.length - 1, tgt));
                        if (tgt !== cur) {
                            const ns = orderBoard.slots.slice();
                            ns.splice(cur, 1);
                            ns.splice(tgt, 0, orderBoard.dragKey);
                            orderBoard.slots = ns;
                        }
                    }
                    function commitDrag() {
                        if (orderBoard.dragKey === "") return;
                        const o = orderBoard.slots.slice();
                        orderBoard.dragKey = "";
                        Widgets.WidgetsConfig.setDashboardOrder(o);
                    }

                    Repeater {
                        model: Widgets.WidgetRegistry.ids
                        delegate: Rectangle {
                            id: chip
                            required property string modelData
                            readonly property int slot: orderBoard.slots.indexOf(modelData)
                            readonly property bool dragging: orderBoard.dragKey === modelData

                            visible: slot >= 0
                            x: 0
                            width: orderBoard.width
                            height: orderBoard.rowH - 6
                            y: dragging ? orderBoard.dragY : slot * orderBoard.rowH
                            z: dragging ? 10 : 1
                            radius: 8
                            color: dragging ? Theme.primary : Theme.surfaceContainer
                            border.width: 1
                            border.color: dragging ? Theme.primary : Theme.outline

                            Behavior on y { enabled: !chip.dragging; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 8
                                spacing: 6
                                Text {
                                    Layout.fillWidth: true
                                    text: Widgets.WidgetRegistry.descriptors[chip.modelData].label
                                    elide: Text.ElideRight
                                    color: chip.dragging ? Theme.primaryText : Theme.surfaceText
                                    font.family: Theme.fontFamily; font.pixelSize: 13
                                }
                                Text {
                                    text: "\u{F01DB}"   // nf-md-drag
                                    font.family: Theme.glyphFont; font.pixelSize: 15
                                    color: chip.dragging ? Theme.primaryText : Theme.outline
                                }
                            }

                            DragHandler {
                                target: null
                                xAxis.enabled: false
                                yAxis.enabled: true
                                cursorShape: Qt.ClosedHandCursor
                                onActiveChanged: {
                                    if (active) {
                                        orderBoard.dragKey = chip.modelData;
                                        orderBoard.dragBaseY = chip.slot * orderBoard.rowH;
                                        orderBoard.dragY = orderBoard.dragBaseY;
                                    } else {
                                        orderBoard.commitDrag();
                                    }
                                }
                                onActiveTranslationChanged: if (active) orderBoard.updateDrag(activeTranslation.y)
                            }
                        }
                    }
                }
            }
        }

        // Weather location.
        Rectangle {
            Layout.fillWidth: true; Layout.topMargin: 8
            radius: 12; color: Qt.darker(Theme.surface, 1.06)
            border.width: 1; border.color: Theme.outline
            implicitHeight: wxCol.implicitHeight + 28

            ColumnLayout {
                id: wxCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 10

                Text { text: "Weather location"; color: Theme.primary
                       font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }

                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Repeater {
                        model: [
                            { label: "Lat", key: "weatherLat" },
                            { label: "Lon", key: "weatherLon" }
                        ]
                        delegate: RowLayout {
                            required property var modelData
                            spacing: 6
                            Text { text: modelData.label; color: Theme.surfaceText
                                   font.family: Theme.fontFamily; font.pixelSize: 13 }
                            Rectangle {
                                Layout.preferredWidth: 110; implicitHeight: 30; radius: 8
                                color: Qt.darker(Theme.surface, 1.2)
                                border.width: 1; border.color: Theme.outline
                                TextInput {
                                    id: ti
                                    anchors.fill: parent; anchors.margins: 8
                                    verticalAlignment: Text.AlignVCenter
                                    color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 13
                                    text: String(Widgets.WidgetsConfig[modelData.key])
                                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                                    onEditingFinished: {
                                        const v = parseFloat(text);
                                        if (!isNaN(v)) { Widgets.WidgetsConfig[modelData.key] = v; Widgets.WidgetsConfig.save(); }
                                    }
                                }
                            }
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Find your coordinates at open-meteo.com or Google Maps. Applies to the Weather widget."
                    color: Theme.surfaceText; opacity: 0.6; wrapMode: Text.WordWrap
                    font.family: Theme.fontFamily; font.pixelSize: 11
                }
            }
        }
    }
}
