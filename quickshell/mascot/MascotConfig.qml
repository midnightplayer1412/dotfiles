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
    readonly property real runSpeed: 4.5       // px per tick while fleeing
    readonly property real gravity: 1.2        // px/tick^2 while airborne
    readonly property real jumpVelocity: 18    // upward px/tick of a startled hop
    readonly property int  pauseMinMs: 1200    // idle dwell between wanders
    readonly property int  pauseMaxMs: 4000

    // --- Reactions / interactions ---
    readonly property int  lowBatteryThreshold: 20   // percent
    readonly property int  reactionMs: 1800          // pet/alert reaction duration
    readonly property int  doubleClickMs: 250        // window to register a double-click (jump)
    readonly property real startleSpeed: 2.0         // avg cursor px/ms over the sprite that scares it
    readonly property int  startleMinSpanMs: 25      // min motion window before trusting that speed
    readonly property int  startleGapMs: 100         // idle gap that resets the motion burst

    // --- Animation region map ---
    // y/n index into the unsliced sheet; dur = ms per frame; loop = repeat.
    // Sequencing (intros/outros/multi-step routines) lives in `sequences`, not
    // here — this map is purely "name -> a single clip's frames".
    // Loop flag matters for sequencing: a "loop": false clip plays once and lets
    // the sprite emit finished() (used by "anim" sequence steps); a "loop": true
    // clip repeats while a timed/held step counts down. Frame y/n verified
    // against the sheet pixels (row = anim# - 1, y = row * 32).
    readonly property var animations: ({
        "idle":          { "y": 192, "n": 5, "dur": 160, "loop": true },
        "walk":          { "y": 256, "n": 8, "dur": 90,  "loop": true },
        "run":           { "y": 288, "n": 4, "dur": 70,  "loop": true },
        "fall":          { "y": 416, "n": 7, "dur": 90,  "loop": true },
        "drag":          { "y": 416, "n": 7, "dur": 120, "loop": true },
        "pet":           { "y": 224, "n": 4, "dur": 140, "loop": true },
        "alert":         { "y": 672, "n": 4, "dur": 120, "loop": true },
        "low_battery":   { "y": 128, "n": 5, "dur": 240, "loop": true },
        "sleep_down":    { "y": 96,  "n": 5, "dur": 120, "loop": false },
        // Idle personality (Phase 2)
        "stand_to_sit":  { "y": 0,   "n": 4, "dur": 110, "loop": false },
        "sit_idle":      { "y": 32,  "n": 4, "dur": 220, "loop": true },
        "sit_to_stand":  { "y": 64,  "n": 4, "dur": 110, "loop": false },
        "sleep_idle":    { "y": 128, "n": 5, "dur": 240, "loop": true },
        "sleep_to_stand":{ "y": 160, "n": 5, "dur": 120, "loop": false },
        // System reactions (Phase 4)
        "prepare_stealth":{ "y": 320, "n": 3, "dur": 110, "loop": false },
        "stealth":       { "y": 352, "n": 7, "dur": 130, "loop": true },
        "cancel_stealth":{ "y": 384, "n": 3, "dur": 110, "loop": false },
        "attack":        { "y": 448, "n": 13, "dur": 55, "loop": false },
        // Box play (Phase 5) — jump in, mess about, jump out.
        "jump_in_box":   { "y": 512, "n": 8, "dur": 65,  "loop": false },
        "push_hand_up":  { "y": 544, "n": 3, "dur": 120, "loop": false },
        "play_box":      { "y": 576, "n": 5, "dur": 150, "loop": true },
        "push_hand_down":{ "y": 608, "n": 3, "dur": 120, "loop": false },
        "ear_up":        { "y": 640, "n": 2, "dur": 130, "loop": false },
        "scan":          { "y": 672, "n": 4, "dur": 150, "loop": true },
        "ear_down":      { "y": 704, "n": 2, "dur": 130, "loop": false },
        "jump_out_box":  { "y": 736, "n": 7, "dur": 65,  "loop": false }
    })

    // --- Sequence definitions ---
    // A sequence is an ordered list of steps `{ s: <animation>, d: <duration> }`
    // consumed by brain.js's sequence engine. Duration is one of:
    //   "anim"      advance when the one-shot clip finishes
    //   "loop"      hold until interrupted externally (condition-driven modes)
    //   <number>    dwell a fixed number of ms
    //   [min, max]  dwell a random number of ms in that range
    // `actions` are transient (preempt, then fall back); `modes` are persistent
    // condition-driven sequences (enter on a rising edge, cleared on the falling
    // edge) and typically end in a "loop" step.
    readonly property var actions: ({
        "pet":    [ { "s": "pet",   "d": reactionMs } ],
        "alert":  [ { "s": "alert", "d": reactionMs } ],
        // System reactions (Phase 4)
        "attack": [ { "s": "attack", "d": "anim" } ],          // swat a new notification
        "unstealth": [ { "s": "cancel_stealth", "d": "anim" } ], // outro when leaving stealth
        // Idle behaviors (Phase 2): enter pose -> dwell -> stand back up.
        "sit":   [ { "s": "stand_to_sit", "d": "anim" },
                   { "s": "sit_idle",     "d": [4000, 8000] },
                   { "s": "sit_to_stand", "d": "anim" } ],
        "nap":   [ { "s": "sleep_down",     "d": "anim" },
                   { "s": "sleep_idle",     "d": [10000, 18000] },
                   { "s": "sleep_to_stand", "d": "anim" } ]
    })

    // Box play (Phase 5) is assembled fresh each visit: jump in, then a random
    // count of antics drawn from the pool below (in random order), then jump
    // out — so no two box visits play the same. See MascotBrain.buildBoxSteps.
    readonly property var boxIntro: ({ "s": "jump_in_box",  "d": "anim" })
    readonly property var boxOutro: ({ "s": "jump_out_box", "d": "anim" })
    readonly property int boxAnticMin: 3
    readonly property int boxAnticMax: 6
    readonly property var boxAntics: [
        [ { "s": "play_box", "d": [800, 2200] } ],
        [ { "s": "push_hand_up",   "d": "anim" }, { "s": "play_box", "d": [600, 1400] } ],
        [ { "s": "push_hand_down", "d": "anim" }, { "s": "play_box", "d": [600, 1400] } ],
        [ { "s": "ear_up", "d": "anim" }, { "s": "scan", "d": [1000, 2200] }, { "s": "ear_down", "d": "anim" } ]
    ]
    readonly property var modes: ({
        "low_battery": [ { "s": "sleep_down", "d": "anim" }, { "s": "low_battery", "d": "loop" } ],
        // Hide/crouch while the focused window is fullscreen (Phase 4).
        "stealth":     [ { "s": "prepare_stealth", "d": "anim" }, { "s": "stealth", "d": "loop" } ]
    })

    // --- System signal thresholds (Phase 4) ---
    readonly property real cpuBusyThreshold: 0.5   // CPU busy fraction (all cores) that makes it run
    readonly property int  cpuPollMs: 2000         // how often to sample /proc/stat

    // Weighted choice made at the start of each idle dwell. "idle" is the plain
    // stand-and-wait; the others are the action sequences above. Weights are
    // relative (need not sum to 1).
    readonly property var idleWeights: [
        { "name": "idle", "weight": 14 },  // most stops are just a plain stand-still
        { "name": "sit",  "weight": 4 },
        { "name": "nap",  "weight": 2 },
        { "name": "box",  "weight": 1 }    // rare treat (~5%)
    ]
}
