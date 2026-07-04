pragma Singleton
import Quickshell
import QtQuick

// Visibility + target screen for the SUPER+W dashboard overlay. Mirrors
// settings/SettingsState.qml.
Singleton {
    id: state
    property bool visible: false
    property var targetScreen: null

    function toggle(screen) { if (visible && targetScreen === screen) { close(); return; } open(screen); }
    function open(screen) { targetScreen = screen; visible = true; }
    function close() { visible = false; }
}
