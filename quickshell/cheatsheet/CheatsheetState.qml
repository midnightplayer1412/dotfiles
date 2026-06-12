pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: state

    // ── Panel visibility ─────────────────────────────────────────────
    property bool visible: false
    property var targetScreen: null

    // ── Selection / hover ────────────────────────────────────────────
    property string activeApp: "hyprland"   // app id of the selected tab
    property string hoveredSym: ""           // keysym currently under the cursor
    property string hoveredLabel: ""         // display label for that key

    function toggle(screen) {
        if (visible && targetScreen === screen) { close(); return; }
        open(screen);
    }
    function open(screen) {
        targetScreen = screen;
        hoveredSym = "";
        hoveredLabel = "";
        visible = true;
    }
    function close() { visible = false; }

    function selectApp(id) {
        activeApp = id;
        hoveredSym = "";
        hoveredLabel = "";
    }
}
