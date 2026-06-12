pragma Singleton

import Quickshell

Singleton {
    property bool visible: false
    property var targetScreen: null

    // Apps whose grouped stack is collapsed in the drawer. Absent = expanded.
    // collapsedRev tickles bindings that read the Set (Set mutations don't emit
    // QML change signals on their own).
    property var collapsedApps: new Set()
    property int collapsedRev: 0

    function toggleCollapsed(app) {
        if (collapsedApps.has(app)) collapsedApps.delete(app);
        else collapsedApps.add(app);
        collapsedRev++;
    }

    function isCollapsed(app) {
        collapsedRev;
        return collapsedApps.has(app);
    }

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
