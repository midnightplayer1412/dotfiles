import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../wifi" as Wifi
import "../bluetooth" as Bt
import "../vpn" as Vpn
import "../connection" as Conn
import ".."

// Combined connection status: Wi-Fi strength, plus small Bluetooth and VPN
// badges when active. Click toggles the Connection panel.
Item {
    id: net
    property bool horizontal: false

    readonly property bool wifiConnected: Wifi.WifiService.connected
    readonly property int wifiSignal: Wifi.WifiService.activeSignal
    readonly property bool btActive: (Bt.BluetoothService.audioMacs || []).length > 0
    readonly property bool vpnActive: (Vpn.VpnService.activeName || "").length > 0

    function wifiGlyph(s) {
        if (s > 75) return "\u{F0928}";  // wifi-strength-4
        if (s > 50) return "\u{F0925}";  // wifi-strength-3
        if (s > 25) return "\u{F0922}";  // wifi-strength-2
        return "\u{F091F}";              // wifi-strength-1
    }

    implicitWidth: lay.implicitWidth
    implicitHeight: lay.implicitHeight

    function panelScreen() {
        const name = Hyprland.focusedMonitor?.name ?? "";
        for (const s of Quickshell.screens) if (s.name === name) return s;
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    GridLayout {
        id: lay
        anchors.centerIn: parent
        rows: net.horizontal ? 1 : -1
        columns: net.horizontal ? -1 : 1
        rowSpacing: 4
        columnSpacing: 6

        Text {
            Layout.alignment: Qt.AlignCenter
            text: net.wifiConnected ? net.wifiGlyph(net.wifiSignal) : "\u{F091F}"
            font.family: Theme.glyphFont
            font.pixelSize: Theme.barIconSize
            color: mouse.containsMouse ? Theme.primary
                 : (net.wifiConnected ? Theme.surfaceText : Theme.outline)
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            visible: net.btActive
            text: "\u{F00B0}"   // bluetooth-connect
            font.family: Theme.glyphFont
            font.pixelSize: Theme.barIconSize - 4   // secondary badge, intentionally smaller
            color: mouse.containsMouse ? Theme.primary : Theme.surfaceText
        }
        Text {
            Layout.alignment: Qt.AlignCenter
            visible: net.vpnActive
            text: "\u{F0582}"   // vpn
            font.family: Theme.glyphFont
            font.pixelSize: Theme.barIconSize - 4   // secondary badge, intentionally smaller
            color: mouse.containsMouse ? Theme.primary : Theme.surfaceText
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Conn.ConnectionState.toggle("connection", net.panelScreen())
    }
}
