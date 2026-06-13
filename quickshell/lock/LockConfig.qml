pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Persistent lockscreen settings, backed by ~/.config/quickshell/lock-config.json.
// FileView + JsonAdapter give two-way persistence: properties load from disk on
// startup; call save() to write them back. The settings panel mutates these and
// calls save(); the lock instance reads them at launch.
Singleton {
    id: config

    property alias showMedia: adapter.showMedia
    property alias showBattery: adapter.showBattery
    property alias showIdentity: adapter.showIdentity
    property alias showDate: adapter.showDate

    property alias wallpaperSource: adapter.wallpaperSource   // "lock-image" | "current-desktop"
    property alias wallpaperPath: adapter.wallpaperPath
    property alias blur: adapter.blur
    property alias dim: adapter.dim

    property alias clockFormat: adapter.clockFormat           // "24h" | "12h"
    property alias showSeconds: adapter.showSeconds
    property alias dateFormat: adapter.dateFormat

    property alias hideInput: adapter.hideInput
    property alias inputPosition: adapter.inputPosition       // "center" | "bottom"

    // Persist current values to disk. Called by settings controls on commit.
    function save() { view.writeAdapter(); }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/lock-config.json"
        watchChanges: true
        // First run: no file yet -> seed it with the adapter defaults.
        onLoadFailed: (error) => view.writeAdapter()

        JsonAdapter {
            id: adapter
            property bool showMedia: true
            property bool showBattery: true
            property bool showIdentity: true
            property bool showDate: true

            property string wallpaperSource: "lock-image"
            property string wallpaperPath: "/home/jp/dotfiles/wallpapers/lock.jpeg"
            property int blur: 4
            property real dim: 0.5

            property string clockFormat: "24h"
            property bool showSeconds: false
            property string dateFormat: "dddd, MMMM d"

            property bool hideInput: false
            property string inputPosition: "center"
        }
    }
}
