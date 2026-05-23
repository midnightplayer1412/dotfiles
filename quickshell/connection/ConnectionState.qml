pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: state

    // ── Drawer state ─────────────────────────────────────────────────
    property string activeTab: ""        // "" | "wifi" | "bluetooth" | "audio" | "vpn"
    property var targetScreen: null

    // ── Hub visibility state (driven by hover) ───────────────────────
    property var triggerScreen: null     // screen whose trigger zone is hovered
    property bool hubHovered: false      // cursor inside the visible Hub itself

    // The hub renders on this screen. Drawer's screen wins when open so
    // the hub follows the drawer; otherwise the hovered trigger's screen.
    readonly property var hubScreen:
        activeTab !== "" ? targetScreen : triggerScreen

    readonly property bool hubVisible: hubScreen !== null

    // ── Hub window registry (for focus grab) ─────────────────────────
    // Map of screen.name -> Hub PanelWindow. Hub.qml registers itself in
    // Component.onCompleted; Drawer reads this so it can include the
    // matching hub in its HyprlandFocusGrab.windows list.
    property var hubWindows: ({})

    function registerHub(screen, win) {
        hubWindows[screen.name] = win;
        hubWindowsChanged();
    }
    function unregisterHub(screen) {
        delete hubWindows[screen.name];
        hubWindowsChanged();
    }

    // ── Hover bridging ───────────────────────────────────────────────
    // When the cursor leaves either window we defer the hide so it can
    // land in the other without flicker. Re-entry cancels the timer.
    Timer {
        id: leaveTimer
        interval: 150
        onTriggered: if (!state.hubHovered) state.triggerScreen = null
    }

    function triggerEntered(screen) { triggerScreen = screen; leaveTimer.stop(); }
    function triggerExited()        { leaveTimer.restart(); }
    function hubEntered()           { hubHovered = true;  leaveTimer.stop(); }
    function hubExited()            { hubHovered = false; leaveTimer.restart(); }

    // ── Tab clicks ───────────────────────────────────────────────────
    function tabClicked(tab, screen) {
        if (activeTab === tab && targetScreen === screen) { close(); return; }
        if (activeTab !== "" && targetScreen === screen) { setTab(tab); return; }
        open(tab, screen);
    }

    function open(tab, screen) { targetScreen = screen; activeTab = tab; }
    function setTab(tab) { activeTab = tab; }
    function close() { activeTab = ""; }
}
