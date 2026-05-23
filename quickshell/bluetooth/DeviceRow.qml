import QtQuick
import QtQuick.Layouts
import ".."
import "../bluetooth"

Item {
    id: row

    // modelData fields: mac, name, paired, connected, rssi, icon
    required property var modelData

    readonly property bool isAudioDevice: modelData.icon && modelData.icon.indexOf("audio") === 0
    readonly property bool audioBound: BluetoothService.audioMacs.indexOf(modelData.mac) >= 0
    readonly property bool inFlight: BluetoothService.inFlightMac === modelData.mac
    // Connected at ACL but no audio profile bound — bluez briefly reports
    // Connected: yes when AVDTP setup fails. Only meaningful for audio devices.
    readonly property bool halfConnected: modelData.connected && isAudioDevice && !audioBound

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
                    text: {
                        if (row.modelData.connected) {
                            return row.halfConnected ? "Connected (no audio)" : "Connected";
                        }
                        return row.modelData.paired ? "Paired" : "Available";
                    }
                    color: row.halfConnected ? Qt.rgba(1.0, 0.55, 0.3, 1.0) : Theme.outline
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
                    text: {
                        if (row.inFlight) {
                            return BluetoothService.inFlightAction === "disconnect"
                                ? "Disconnecting…"
                                : "Connecting…";
                        }
                        if (row.modelData.connected) {
                            return row.halfConnected ? "Reconnect" : "Disconnect";
                        }
                        return row.modelData.paired ? "Connect" : "Pair";
                    }
                    color: actionMouse.containsMouse ? Theme.primaryText : Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    opacity: row.inFlight ? 0.7 : 1.0
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: row.inFlight ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (row.inFlight) return;
                        if (row.halfConnected) {
                            BluetoothService.reconnect(row.modelData.mac);
                        } else if (row.modelData.connected) {
                            BluetoothService.disconnect(row.modelData.mac);
                        } else if (row.modelData.paired) {
                            BluetoothService.connect(row.modelData.mac);
                        } else {
                            BluetoothService.pair(row.modelData.mac);
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 13
                visible: row.modelData.paired
                color: forgetMouse.containsMouse ? Qt.rgba(1.0, 0.4, 0.4, 0.25) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "\u{F01B4}"   // nf-md-delete
                    font.family: "Monaspace Argon NF"
                    font.pixelSize: 14
                    color: forgetMouse.containsMouse ? Qt.rgba(1.0, 0.4, 0.4, 1.0) : Theme.outline
                }

                MouseArea {
                    id: forgetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.requestForget(row.modelData.mac, row.modelData.name)
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
