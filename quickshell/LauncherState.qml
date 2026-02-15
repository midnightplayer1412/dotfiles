pragma Singleton

import Quickshell

Singleton {
    property bool visible: false
    property var targetScreen: null

    function toggle(screen) {
        if (visible && targetScreen === screen) {
            close();
        } else {
            targetScreen = screen;
            visible = true;
        }
    }

    function close() {
        visible = false;
    }
}
