import QtQuick
import QtQuick.Layouts
import "../ui" as Ui
import ".."
import "../vpn"

Item {
    id: row

    required property var modelData    // { name, type, active }

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
                text: "\u{F0582}"   // vpn glyph
                font.family: "Monaspace Argon NF"
                font.pixelSize: 16
                color: row.modelData.active ? Theme.primary : Theme.surfaceText
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
                    text: row.modelData.type === "wireguard" ? "WireGuard" : "VPN"
                    color: Theme.outline
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }

            Ui.Button {
                kind: "filled"
                text: row.modelData.active ? "Disconnect" : "Connect"
                onClicked: row.modelData.active
                    ? VpnService.deactivate(row.modelData.name)
                    : VpnService.activate(row.modelData.name)
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
