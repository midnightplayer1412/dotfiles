import QtQuick
import ".."
import "../wifi"
import "../bluetooth"
import "../vpn"

Item {
    id: root

    required property string tabKey   // "wifi" | "bluetooth" | "vpn"
    required property var parentScreen

    width: 36
    height: 36

    readonly property string glyph: {
        switch (tabKey) {
        case "wifi":
            if (!WifiService.enabled) return "\u{F092D}";       // wifi-strength-off
            if (!WifiService.connected) return "\u{F092B}";     // wifi-strength-alert-outline
            const s = WifiService.activeSignal;
            if (s > 75) return "\u{F0928}";                     // wifi-strength-4
            if (s > 50) return "\u{F0925}";                     // wifi-strength-3
            if (s > 25) return "\u{F0922}";                     // wifi-strength-2
            return "\u{F091F}";                                  // wifi-strength-1
        case "bluetooth":
            if (!BluetoothService.enabled) return "\u{F00B2}";  // bluetooth-off
            const anyConn = BluetoothService.devices.some(d => d.connected);
            if (anyConn) return "\u{F00B0}";                    // bluetooth-connect
            return "\u{F00AF}";                                  // bluetooth
        case "vpn":
            return "\u{F0582}";                                  // vpn
        }
        return "?";
    }

    readonly property bool isActive:
        ConnectionState.activeTab === tabKey
        && ConnectionState.targetScreen === root.parentScreen

    readonly property real iconOpacity: {
        switch (tabKey) {
        case "wifi":      return 1.0;
        case "bluetooth": return 1.0;
        case "vpn":       return VpnService.activeName !== "" ? 1.0 : 0.5;
        }
        return 1.0;
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: "Monaspace Argon NF"
        font.pixelSize: 22
        color: root.isActive ? Theme.primary : Theme.surfaceText
        opacity: root.iconOpacity
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ConnectionState.tabClicked(root.tabKey, root.parentScreen)
    }
}
