import QtQuick
import QtQuick.Layouts
import ".."
import "../wifi"

Rectangle {
    id: root
    color: Qt.rgba(0, 0, 0, 0.55)
    radius: 16

    property string targetSsid: WifiService.pendingPasswordSsid
    onTargetSsidChanged: {
        pwField.text = "";
        if (targetSsid.length > 0) pwField.forceActiveFocus();
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: contentCol.implicitHeight + 28
        radius: 16
        color: Theme.surfaceContainer
        border.color: Theme.outline
        border.width: 1

        ColumnLayout {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Connect to " + root.targetSsid
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 8
                color: Theme.surface
                border.color: pwField.activeFocus ? Theme.primary : Theme.outline
                border.width: 1

                TextInput {
                    id: pwField
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    clip: true
                    focus: true
                    onAccepted: WifiService.connectWithPassword(root.targetSsid, pwField.text)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Password"
                        color: Theme.outline
                        font: pwField.font
                        visible: pwField.text.length === 0
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: WifiService.lastError.length > 0
                text: WifiService.lastError
                color: "#ff6b6b"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: cancelLabel.implicitWidth + 18
                    Layout.preferredHeight: 28
                    radius: 14
                    color: cancelMouse.containsMouse ? Theme.surface : "transparent"
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
                        onClicked: WifiService.cancelPasswordPrompt()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: connectLabel.implicitWidth + 22
                    Layout.preferredHeight: 28
                    radius: 14
                    color: connectMouse.containsMouse ? Theme.primary : Theme.primaryContainer

                    Text {
                        id: connectLabel
                        anchors.centerIn: parent
                        text: WifiService.connecting ? "Connecting…" : "Connect"
                        color: connectMouse.containsMouse ? Theme.primaryText : Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: connectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !WifiService.connecting
                        onClicked: WifiService.connectWithPassword(root.targetSsid, pwField.text)
                    }
                }
            }
        }
    }
}
