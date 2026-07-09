pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Global UI component style selection, shared by every Ui.Toggle / Ui.Slider in
// the shell. Persisted to ~/.config/quickshell/ui-style.json. Changing a value
// here re-skins every instance live. Edited from the Settings → Appearance tab.
Singleton {
    id: style

    property alias toggle: adapter.toggle     // "capsule" | "square" | "notch"
    property alias slider: adapter.slider     // "thin" | "thick"
    property alias surface: adapter.surface   // "solid" | "glass"
    property alias desktopBlur: adapter.desktopBlur  // real compositor backdrop blur behind glass
    property alias connectionLayout: adapter.connectionLayout  // "tiles" | "accordion" | "stacked"
    property alias widgetStyle: adapter.widgetStyle  // "refined" | "minimal" | "playful" | "dense"

    function save() { view.writeAdapter(); }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/ui-style.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()

        JsonAdapter {
            id: adapter
            property string toggle: "capsule"
            property string slider: "thin"
            property string surface: "glass"
            property bool desktopBlur: true
            property string connectionLayout: "tiles"
            property string widgetStyle: "refined"
        }
    }
}
