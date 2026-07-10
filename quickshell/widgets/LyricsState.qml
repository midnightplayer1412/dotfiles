pragma Singleton

import Quickshell
import QtQuick

// Runtime toggle for the lyrics strip. The strip auto-shows whenever a player
// with lyrics is active (LyricsConfig.enabled && LyricsService.available); this
// `userHidden` flag lets the keybind hide it on demand without touching the
// persisted enable switch. Mirrors DashboardState's shape.
Singleton {
    id: state
    property bool userHidden: false
    property var targetScreen: null

    function toggle(screen) {
        if (screen) targetScreen = screen;
        userHidden = !userHidden;
    }

    // Full-screen karaoke overlay (Super+Shift+Y): a centered, blown-up lyrics
    // view over a dimmed backdrop. Separate from the edge strip — either, both,
    // or neither can be on.
    property bool karaoke: false

    function toggleKaraoke(screen) {
        if (screen) targetScreen = screen;
        karaoke = !karaoke;
    }

    function closeKaraoke() { karaoke = false; }
}
