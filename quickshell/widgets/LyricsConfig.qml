pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Persistent settings for the synced lyrics strip, backed by
// ~/.config/quickshell/lyrics-config.json. Same FileView+JsonAdapter shape as
// BarConfig. The Settings → Appearance "Lyrics strip" card writes these.
Singleton {
    id: config

    property alias enabled: adapter.enabled              // master on/off
    property alias position: adapter.position            // "top" | "bottom"
    property alias layoutMode: adapter.layoutMode        // "single" | "triple" | "scroll"
    property alias background: adapter.background        // "theme" | "transparent"
    property alias offsetMs: adapter.offsetMs            // sync nudge (+ = lyrics later)
    property alias sideGap: adapter.sideGap              // base edge inset (px); 0 = flush
    property alias showWhenEmpty: adapter.showWhenEmpty  // keep strip + "No lyrics found" label
    property alias useLocalFiles: adapter.useLocalFiles  // prefer on-disk .lrc over LRCLIB
    property alias lyricsDir: adapter.lyricsDir          // folder searched for "Artist - Title.lrc"
    property alias screenName: adapter.screenName        // monitor to show on; "" = primary

    // Looks & behavior
    property alias fontScale: adapter.fontScale          // lyric text size multiplier (1.0 = default)
    property alias heightScale: adapter.heightScale      // strip height multiplier (1.0 = default)
    property alias animate: adapter.animate              // slide in/out from the edge
    property alias hideWhenPaused: adapter.hideWhenPaused // hide the strip while playback is paused

    function save() { view.writeAdapter(); }

    // Set one key and persist. Segmented controls / toggles use this; the offset
    // slider writes the alias live and calls save() on release to avoid file spam.
    function set(key, val) { adapter[key] = val; save(); }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/lyrics-config.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()

        JsonAdapter {
            id: adapter
            property bool enabled: true
            property string position: "bottom"
            property string layoutMode: "single"
            property string background: "theme"
            property int offsetMs: 0
            property int sideGap: 0
            property bool showWhenEmpty: false
            property bool useLocalFiles: true
            property string lyricsDir: ""
            property string screenName: ""
            property real fontScale: 1.0
            property real heightScale: 1.0
            property bool animate: true
            property bool hideWhenPaused: false
        }
    }
}
