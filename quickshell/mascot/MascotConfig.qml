pragma Singleton

import QtQuick

QtObject {
    id: root

    // --- Asset ---
    readonly property url sheet: Qt.resolvedUrl("sprites/Sprite Sheet Cat - Aichan_owo.png")
    readonly property int frameW: 33
    readonly property int frameH: 32
    readonly property int scale: 3            // 33x32 -> 99x96 on screen

    // --- Placement ---
    readonly property string screenName: "eDP-2"   // roams this screen; falls back to primary

    // --- Movement / physics (pixels, screen-space) ---
    readonly property real speed: 1.5          // px per tick while walking
    readonly property real gravity: 1.2        // px/tick^2 while airborne
    readonly property int  pauseMinMs: 1200    // idle dwell between wanders
    readonly property int  pauseMaxMs: 4000

    // --- Reactions ---
    readonly property int lowBatteryThreshold: 20   // percent
    readonly property int reactionMs: 1800          // pet/alert reaction duration

    // --- Animation region map ---
    // y/n index into the unsliced sheet; dur = ms per frame; loop = repeat;
    // intro = a non-looping clip to play once before this clip loops.
    readonly property var animations: ({
        "idle":        { "y": 192, "n": 5, "dur": 160, "loop": true },
        "walk":        { "y": 256, "n": 8, "dur": 90,  "loop": true },
        "fall":        { "y": 416, "n": 7, "dur": 90,  "loop": true },
        "drag":        { "y": 416, "n": 7, "dur": 120, "loop": true },
        "pet":         { "y": 224, "n": 4, "dur": 140, "loop": true },
        "alert":       { "y": 672, "n": 4, "dur": 120, "loop": true },
        "low_battery": { "y": 128, "n": 5, "dur": 240, "loop": true, "intro": "sleep_down" },
        "sleep_down":  { "y": 96,  "n": 5, "dur": 120, "loop": false }
    })
}
