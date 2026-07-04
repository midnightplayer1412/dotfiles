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

                Repeater {
                    model: Widgets.WidgetsConfig.resolvedDashboard.order
                    delegate: RowLayout {
                        required property var modelData
                        required property int index
                        readonly property var order: Widgets.WidgetsConfig.resolvedDashboard.order
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: (index + 1) + ".  " + Widgets.WidgetRegistry.descriptors[modelData].label
                            color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 13
                        }
                        Ui.IconButton {
                            glyph: "\u{F0143}"   // nf-md-chevron-up
                            enabled: index > 0
                            onClicked: {
                                const o = order.slice();
                                const t = o[index - 1]; o[index - 1] = o[index]; o[index] = t;
                                Widgets.WidgetsConfig.setDashboardOrder(o);
                            }
                        }
                        Ui.IconButton {
                            glyph: "\u{F0140}"   // nf-md-chevron-down
                            enabled: index < order.length - 1
                            onClicked: {
                                const o = order.slice();
                                const t = o[index + 1]; o[index + 1] = o[index]; o[index] = t;
                                Widgets.WidgetsConfig.setDashboardOrder(o);
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
