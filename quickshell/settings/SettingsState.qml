pragma Singleton

import Quickshell
import QtQuick

// Visibility + active category for the Settings panel. Mirrors OverviewState.
Singleton {
    id: state

    property bool visible: false
    property var targetScreen: null
    property string activeCategory: "lock"   // future categories switch this

    function toggle(screen) {
        if (visible && targetScreen === screen) { close(); return; }
        open(screen);
    }
    function open(screen) { targetScreen = screen; visible = true; }
    function close() { visible = false; }
}
