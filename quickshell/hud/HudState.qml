pragma Singleton

import QtQuick

QtObject {
    id: root

    property bool visible: false
    property var activeScreens: ({})

    function show(screen) {
        activeScreens[screen.name] = true;
        activeScreensChanged();
        visible = true;
    }

    function hide(screen) {
        delete activeScreens[screen.name];
        activeScreensChanged();

        // Check if any screens still have HUD visible
        var hasVisible = false;
        for (var key in activeScreens) {
            if (activeScreens[key]) {
                hasVisible = true;
                break;
            }
        }
        visible = hasVisible;
    }

    function isVisibleOnScreen(screen) {
        return activeScreens[screen?.name] === true;
    }
}
