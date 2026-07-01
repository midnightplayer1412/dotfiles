import QtQuick
import QtQuick.Layouts
import "../ui" as Ui
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

            Ui.Button {
                // Disconnect is neutral (device stays paired) → filled; connect-type
                // actions get emphasis → primary. In-flight labels + dimming via busy.
                kind: (row.modelData.connected && !row.halfConnected) ? "filled" : "primary"
                busy: row.inFlight
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
                onClicked: {
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

            Ui.IconButton {
                // Forget affordance — now tints via theme accent on hover instead of
                // the old red. Destructive confirmation lives in ForgetConfirm.
                bg: "bare"
                glyph: "\u{F01B4}"   // nf-md-delete
                size: 26
                glyphSize: 14
                visible: row.modelData.paired
                onClicked: BluetoothService.requestForget(row.modelData.mac, row.modelData.name)
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
