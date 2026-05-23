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
                text: "Forget device?"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: BluetoothService.pendingForgetName
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 13
                elide: Text.ElideMiddle
            }

            Text {
                Layout.fillWidth: true
                text: "You'll need to pair it again to reconnect."
                color: Theme.outline
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
                        onClicked: BluetoothService.confirmForget(false)
                    }
                }

                Rectangle {
                    Layout.preferredWidth: forgetLabel.implicitWidth + 24
                    Layout.preferredHeight: 30
                    radius: 15
                    color: forgetMouse.containsMouse
                        ? Qt.rgba(1.0, 0.4, 0.4, 1.0)
                        : Qt.rgba(1.0, 0.4, 0.4, 0.25)

                    Text {
                        id: forgetLabel
                        anchors.centerIn: parent
                        text: "Forget"
                        color: forgetMouse.containsMouse ? Theme.primaryText : Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: forgetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothService.confirmForget(true)
                    }
                }
            }
        }
    }
}
