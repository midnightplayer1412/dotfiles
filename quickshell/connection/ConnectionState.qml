pragma Singleton

import Quickshell
import QtQuick

// Right-side panel state. A single container hosts EITHER the unified connection
// panel (wifi/bluetooth/vpn) or the audio panel — never both. Bar icons toggle
// it; the container's focus grab calls close() on click-outside.
Singleton {
    id: state

    // "" (closed) | "connection" | "audio"
    property string openPanel: ""
    property var targetScreen: null

    readonly property bool visible: openPanel !== "" && targetScreen !== null

    // Toggle a panel from a bar icon: same panel on the same screen closes it;
    // otherwise (re)open the requested panel on that screen.
    function toggle(kind, screen) {
        if (state.openPanel === kind && state.targetScreen === screen) { state.close(); return; }
        state.open(kind, screen);
    }

    function open(kind, screen) { state.targetScreen = screen; state.openPanel = kind; }
    function close() { state.openPanel = ""; }
}
