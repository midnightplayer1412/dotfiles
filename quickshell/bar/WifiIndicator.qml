import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."
import "../wifi"

Item {
    id: root
    width: Theme.barWidth - 8
    height: Theme.barWidth - 8

    // Nerd Font Material Design wifi glyphs (nf-md range).
    // Unicode escapes used so the codepoints are unambiguous in source.
    readonly property string glyph: {
        if (!WifiService.enabled) return "\u{F092D}";       // wifi-strength-off
        if (!WifiService.connected) return "\u{F092B}";     // wifi-strength-alert-outline
        const s = WifiService.activeSignal;
        if (s > 75) return "\u{F0928}";                     // wifi-strength-4
        if (s > 50) return "\u{F0925}";                     // wifi-strength-3
        if (s > 25) return "\u{F0922}";                     // wifi-strength-2
        return "\u{F091F}";                                  // wifi-strength-1
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: "Monaspace Argon NF"
        font.pixelSize: 28
        color: Theme.primary
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const monitorName = Hyprland.focusedMonitor?.name ?? "";
            for (const s of Quickshell.screens) {
                if (s.name === monitorName) {
                    WifiState.toggle(s);
                    return;
                }
            }
            if (Quickshell.screens.length > 0) WifiState.toggle(Quickshell.screens[0]);
        }
    }
}
