import QtQuick
import ".."
import "../ui" as Ui
import "../wifi"
import "../bluetooth"
import "../audio"
import "../vpn"

Item {
    id: root

    required property string tabKey   // "wifi" | "bluetooth" | "audio" | "vpn"
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
        case "audio":
            const cur = AudioService.sinks.find(s => s.name === AudioService.defaultSink);
            if (!cur) return "\u{F057E}";                       // volume-high
            if (cur.kind === "bluetooth") return "\u{F0AB7}";   // bluetooth-audio
            if (cur.kind === "hdmi") return "\u{F0379}";        // monitor
            if (cur.portLabel === "Headphones") return "\u{F02CB}"; // headphones
            return "\u{F04C3}";                                  // speaker
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
        case "audio":     return 1.0;
        case "vpn":       return VpnService.activeName !== "" ? 1.0 : 0.5;
        }
        return 1.0;
    }

    Ui.IconButton {
        anchors.fill: parent
        bg: "bare"
        size: 36
        glyph: root.glyph
        glyphSize: 22
        active: root.isActive
        opacity: root.iconOpacity
        onClicked: ConnectionState.tabClicked(root.tabKey, root.parentScreen)
    }
}
