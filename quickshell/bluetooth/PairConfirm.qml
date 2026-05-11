import QtQuick
import QtQuick.Layouts
import ".."
import "../bluetooth"

Rectangle {
    id: root

    color: Qt.rgba(0, 0, 0, 0.6)
    radius: Theme.drawerRadius

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 40
        radius: 12
        color: Theme.surface
        border.color: Theme.outline
        border.width: 1
        height: contentCol.implicitHeight + 32

        ColumnLayout {
            id: contentCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Confirm pairing"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: BluetoothService.pendingConfirmDevice
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideMiddle
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: BluetoothService.pendingConfirmCode
                color: Theme.primary
                font.family: "Monaspace Argon NF"
                font.pixelSize: 28
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "Does this code match the one on the device?"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: cancelLabel.implicitWidth + 24
                    Layout.preferredHeight: 30
                    radius: 15
                    color: cancelMouse.containsMouse ? Theme.surfaceContainer : "transparent"
                    border.color: Theme.outline
                    border.width: 1

                    Text {
                        id: cancelLabel
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.confirmPair(false)
                    }
                }

                Rectangle {
                    Layout.preferredWidth: pairLabel.implicitWidth + 24
                    Layout.preferredHeight: 30
                    radius: 15
                    color: pairMouse.containsMouse ? Theme.primary : Theme.primaryContainer

                    Text {
                        id: pairLabel
                        anchors.centerIn: parent
                        text: "Pair"
                        color: pairMouse.containsMouse ? Theme.primaryText : Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: pairMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.confirmPair(true)
                    }
                }
            }
        }
    }
}
