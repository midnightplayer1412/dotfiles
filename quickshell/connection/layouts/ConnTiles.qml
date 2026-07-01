import QtQuick
import QtQuick.Layouts
import "../../ui" as Ui
import "../.."
import "../../wifi" as Wifi
import "../../bluetooth" as Bt
import "../../vpn" as Vpn

// Default connection layout: a row of Wi-Fi / Bluetooth / VPN tiles (icon + name
// + status; the icon colour shows on/off). Tap a tile to reveal its detail
// below, with the service's on/off toggle in the detail header.
Item {
    id: root

    property string sel: "wifi"

    readonly property var tiles: [
        { key: "wifi",      sec: wifiSec },
        { key: "bluetooth", sec: btSec },
        { key: "vpn",       sec: vpnSec }
    ]
    readonly property var currentSec:
        sel === "bluetooth" ? btSec : sel === "vpn" ? vpnSec : wifiSec

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // ── Tiles ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: root.tiles
                delegate: Ui.Surface {
                    required property var modelData
                    readonly property bool active: root.sel === modelData.key
                    readonly property bool on: modelData.sec.sectionEnabled
                    level: 1
                    radius: 12
                    Layout.fillWidth: true
                    Layout.preferredHeight: 66

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sel = modelData.key
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: modelData.sec.sectionGlyph
                                font.family: Theme.glyphFont
                                font.pixelSize: 20
                                color: on ? Theme.primary : Theme.outline
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.sec.sectionTitle
                                color: Theme.surfaceText
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.sec.sectionSummary
                            color: Theme.outline
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    // Selection outline.
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: "transparent"
                        border.color: Theme.primary
                        border.width: active ? 2 : 0
                    }
                }
            }
        }

        // ── Detail header (selected service name + on/off) ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.currentSec.sectionTitle
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.bold: true
            }
            Ui.Toggle {
                visible: root.currentSec.toggleAvailable
                Layout.preferredWidth: 44
                Layout.preferredHeight: 24
                checked: root.currentSec.sectionEnabled
                onToggled: (v) => root.currentSec.setSectionEnabled(v)
            }
        }

        // ── Detail body (selected section) ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Wifi.WifiSection { id: wifiSec; anchors.fill: parent; visible: root.sel === "wifi" }
            Bt.BtSection     { id: btSec;   anchors.fill: parent; visible: root.sel === "bluetooth" }
            Vpn.VpnSection   { id: vpnSec;  anchors.fill: parent; visible: root.sel === "vpn" }
        }
    }
}
