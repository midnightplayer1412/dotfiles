import QtQuick
import QtQuick.Layouts
import ".."
import "../vpn"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            Layout.fillWidth: true
            text: "VPN"
            color: Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.bold: true
        }

        // Active VPN strip
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            visible: VpnService.activeName.length > 0
            radius: 12
            color: Theme.primaryContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10

                Text {
                    text: "\u{F0582}"
                    font.family: "Monaspace Argon NF"
                    font.pixelSize: 18
                    color: Theme.primary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        text: VpnService.activeName
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "Connected"
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        opacity: 0.7
                    }
                }
            }
        }

        // Error strip
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: vpnErrText.implicitHeight + 16
            visible: VpnService.lastError.length > 0
            radius: 8
            color: Qt.rgba(1.0, 0.4, 0.4, 0.15)
            border.color: Qt.rgba(1.0, 0.4, 0.4, 0.4)
            border.width: 1

            Text {
                id: vpnErrText
                anchors.fill: parent
                anchors.margins: 8
                text: VpnService.lastError
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: VpnService.clearError()
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Connections"
            color: Theme.outline
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: VpnService.connections
            delegate: VpnRow {
                width: ListView.view ? ListView.view.width : 0
            }
        }

        Timer {
            interval: 5000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: VpnService.refresh()
        }
    }
}
