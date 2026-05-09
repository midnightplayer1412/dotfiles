import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors {
        top: true
        right: true
        bottom: true
    }

    implicitWidth: 380

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: WifiState.close()
    }

    Rectangle {
        id: panel

        width: parent.width - 10
        height: parent.height - 20
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.surface
        radius: 16
        border.color: Theme.outline
        border.width: 1
        clip: true

        x: 40
        opacity: 0
        Component.onCompleted: entryAnim.start()
        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "x"; from: 40; to: 0; duration: 200; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                }

                // Toggle pill
                Rectangle {
                    id: toggle
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 24
                    radius: 12
                    color: WifiService.enabled ? Theme.primary : Theme.surfaceContainer
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: Theme.surface
                        anchors.verticalCenter: parent.verticalCenter
                        x: WifiService.enabled ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiService.setEnabled(!WifiService.enabled)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                visible: WifiService.connected
                radius: 12
                color: Theme.primaryContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: WifiService.activeSsid
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Connected · " + WifiService.activeSignal + "%"
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            opacity: 0.7
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: disconnectLabel.implicitWidth + 18
                        Layout.preferredHeight: 28
                        radius: 14
                        color: disconnectMouse.containsMouse ? Theme.primary : Theme.surface
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: disconnectLabel
                            anchors.centerIn: parent
                            text: "Disconnect"
                            color: disconnectMouse.containsMouse ? Theme.primaryText : Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: disconnectMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WifiService.disconnect()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: errStripText.implicitHeight + 16
                visible: WifiService.lastError.length > 0 && WifiService.pendingPasswordSsid.length === 0
                radius: 8
                color: Qt.rgba(1.0, 0.4, 0.4, 0.15)
                border.color: Qt.rgba(1.0, 0.4, 0.4, 0.4)
                border.width: 1

                Text {
                    id: errStripText
                    anchors.fill: parent
                    anchors.margins: 8
                    text: WifiService.lastError
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiService.clearError()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Available networks"
                    color: Theme.outline
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: WifiService.scanning ? "…" : "↻"
                    color: Theme.primary
                    opacity: refreshMouse.containsMouse ? 1.0 : 0.7
                    font.pixelSize: 14

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiService.refresh()
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: WifiService.networks

                delegate: NetworkRow {
                    width: ListView.view ? ListView.view.width : 0
                    visible: !modelData.active
                    height: visible ? 44 : 0
                }
            }

            Timer {
                interval: 10000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: WifiService.refresh()
            }
        }

        PasswordPrompt {
            anchors.fill: parent
            visible: WifiService.pendingPasswordSsid.length > 0
        }
    }
}
