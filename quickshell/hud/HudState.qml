pragma Singleton

import QtQuick

QtObject {
    id: root

    property bool visible: false
    property var activeScreens: ({})
    // "volume" or "brightness" — which indicator to show
    property string activeIndicator: "volume"

    function show(screen, indicator) {
        activeScreens[screen.name] = true;
        activeScreensChanged();
        visible = true;
        if (indicator) activeIndicator = indicator;
    }

    function hide(screen) {
        delete activeScreens[screen.name];
        activeScreensChanged();

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
