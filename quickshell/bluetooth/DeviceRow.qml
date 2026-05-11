import QtQuick
import QtQuick.Layouts
import ".."
import "../bluetooth"

Item {
    id: row

    // modelData fields: mac, name, paired, connected, rssi, icon
    required property var modelData

    height: 44

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: hoverArea.containsMouse ? Theme.surfaceContainer : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 10

            Text {
                text: row.modelData.connected ? "\u{F00B0}" : "\u{F00AF}"   // bluetooth-connect : bluetooth
                font.family: "Monaspace Argon NF"
                font.pixelSize: 16
                color: row.modelData.connected ? Theme.primary : Theme.surfaceText
                Layout.preferredWidth: 20
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: row.modelData.name
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
                Text {
                    text: row.modelData.connected
                        ? "Connected"
                        : (row.modelData.paired ? "Paired" : "Available")
                    color: Theme.outline
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }

            Rectangle {
                Layout.preferredWidth: actionLabel.implicitWidth + 16
                Layout.preferredHeight: 26
                radius: 13
                color: actionMouse.containsMouse ? Theme.primary : Theme.surfaceContainer
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: actionLabel
                    anchors.centerIn: parent
                    text: row.modelData.connected
                        ? "Disconnect"
                        : (row.modelData.paired ? "Connect" : "Pair")
                    color: actionMouse.containsMouse ? Theme.primaryText : Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (row.modelData.connected) {
                            BluetoothService.disconnect(row.modelData.mac);
                        } else if (row.modelData.paired) {
                            BluetoothService.connect(row.modelData.mac);
                        } else {
                            BluetoothService.pair(row.modelData.mac);
                        }
                    }
                }
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
        }
    }
}
