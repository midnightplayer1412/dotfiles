import QtQuick
import Quickshell.Services.UPower
import "../notifications" as Notif
import "brain.js" as Brain

Item {
    id: root

    // Geometry supplied by the host window.
    property real screenW: 1920
    property real screenH: 1080
    property real spriteW: 99
    property real spriteH: 96

    // Live position / motion (screen-space, top-left of sprite).
    property real posX: 100
    property real posY: 0
    property real vy: 0
    property int  facing: 1            // 1 = face right, -1 = face left
    property real targetX: 200

    // Mode flags.
    property bool dragging: false
    property bool airborne: false
    property bool paused: false
    property bool fleeing: false       // running away from the cursor

    // --- Sequence engine state (see brain.js) ---
    // `action` is a transient scripted sequence (pet, alert, later jump/sit/box)
    // that preempts movement and then falls back. `modePlayer` is a persistent
    // condition-driven sequence (low_battery, later stealth) entered on a rising
    // edge and cleared on the falling edge. Each is a brain.js "player" or null.
    property var    action: null
    property string actionName: ""
    property var    actionSteps: null   // steps array the current action is playing
    property var    modePlayer: null
    property string modeName: ""
    property bool   _animFinished: false   // set by the sprite, consumed next tick
    property bool   _idleAction: false     // current action is a dwell behavior (sit/nap)
    // Stealth-on-fullscreen runs the cat to a corner first, then crouches:
    // "none" -> "seeking" (running to the edge) -> "hidden" (crouched there).
    property string cover: "none"

    readonly property real floorY: screenH - spriteH

    // --- Battery (mirrors quickshell/bar/Battery.qml) ---
    property var battery: UPower.displayDevice
    readonly property bool batteryReady: battery && battery.ready
    readonly property bool isCharging: batteryReady
        ? (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged)
        : false
    readonly property int batteryPct: batteryReady ? Math.round((battery.percentage ?? 0) * 100) : 100
    readonly property bool lowBattery: batteryReady
        ? Brain.isLowBattery(batteryPct, isCharging, MascotConfig.lowBatteryThreshold)
        : false

    // --- Derived state ---
    // Wants to hide: a window is fullscreen and we're not busy sleeping.
    readonly property bool coverWanted: MascotSignals.fullscreen && !lowBattery

    // Locomotion is a run (faster + run clip) when fleeing the cursor, the CPU is
    // busy, or hurrying to cover; otherwise a walk.
    readonly property bool sprinting: fleeing || MascotSignals.cpuBusy || cover === "seeking"

    readonly property bool moving: !paused && !airborne && !dragging
        && action === null && modePlayer === null
        && Math.abs(targetX - posX) > MascotConfig.speed

    // Resolution order: drag > fall > action > mode > run/walk/idle.
    readonly property string state:
        dragging          ? "drag"
        : airborne        ? "fall"
        : action !== null ? action.state
        : modePlayer !== null ? modePlayer.state
        : !moving         ? "idle"
        : sprinting       ? "run"
        : "walk"

    Component.onCompleted: {
        posY = floorY;
        targetX = Brain.chooseTarget(0, Math.max(0, screenW - spriteW), Math.random());
        _notifPrev = notifCount;
    }

    // Play a prebuilt step array as the current action. Preempts any current
    // action; falls back to mode/base when it finishes.
    function triggerActionSteps(name, steps) {
        root.actionName = name;
        root.actionSteps = steps;
        root.action = Brain.seqEnter(steps, 0, Math.random());
    }

    // Capture a transient scripted action by name (pet, alert, ...).
    function triggerAction(name) {
        const steps = MascotConfig.actions[name];
        if (steps)
            triggerActionSteps(name, steps);
    }

    // Build a fresh, randomized box routine: jump in, a random count of antics
    // (random order, drawn from the pool), jump out. So every visit differs.
    function buildBoxSteps() {
        const pool = MascotConfig.boxAntics;
        const n = MascotConfig.boxAnticMin
            + Math.floor(Math.random() * (MascotConfig.boxAnticMax - MascotConfig.boxAnticMin + 1));
        const groups = [];
        for (let i = 0; i < n; i++)
            groups.push(pool[Math.floor(Math.random() * pool.length)]);
        return Brain.assembleRoutine(MascotConfig.boxIntro, groups, MascotConfig.boxOutro);
    }

    // A startled vertical hop (double-click). Reuses the gravity integrator: an
    // upward velocity arcs the cat up and back to the floor.
    function hop() {
        if (root.airborne || root.dragging)
            return;
        root.action = null;
        root._idleAction = false;
        root.vy = -MascotConfig.jumpVelocity;
        root.airborne = true;
    }

    // Bolt away from the cursor (fast swipe over the sprite). Runs to the far
    // edge; `fleeing` cleared on arrival.
    function startle(cursorX) {
        if (root.dragging || root.airborne || root.fleeing)
            return;
        root.action = null;
        root._idleAction = false;
        root.paused = false;
        root.fleeing = true;
        root.targetX = Brain.fleeTarget(cursorX, root.posX, root.spriteW, 0, Math.max(0, root.screenW - root.spriteW));
        root.facing = root.targetX > root.posX ? 1 : -1;
    }

    // Reported by the sprite when a one-shot clip finishes; consumed next tick.
    function noteAnimFinished() {
        root._animFinished = true;
    }

    // --- Physics / sequence / wander tick ---
    Timer {
        interval: 16; repeat: true; running: true
        onTriggered: {
            if (root.dragging) {
                // Picked up — abandon any in-progress action so the cat doesn't
                // resume a stale pose (e.g. sitting) after being dropped.
                root.action = null;
                root._idleAction = false;
                return;
            }
            if (root.airborne) {
                const g = Brain.gravityStep(root.posY, root.vy, root.floorY, MascotConfig.gravity);
                root.posY = g.y;
                root.vy = g.vy;
                if (g.landed)
                    root.airborne = false;
                return;
            }

            // Low battery is the top mode: sleep in place, overriding any cover.
            if (root.lowBattery) {
                if (root.modeName !== "low_battery") {
                    root.cover = "none";
                    root.modeName = "low_battery";
                    root.modePlayer = Brain.seqEnter(MascotConfig.modes["low_battery"], 0, Math.random());
                }
            } else {
                if (root.modeName === "low_battery") {   // woke up — charging / above threshold
                    root.modeName = "";
                    root.modePlayer = null;
                }
                // Cover (stealth-on-fullscreen) state machine.
                if (root.cover === "none" && root.coverWanted) {
                    // Start running to the nearest corner to hide.
                    root.cover = "seeking";
                    root.action = null;
                    root._idleAction = false;
                    root.paused = false;
                    root.targetX = Brain.nearestEdge(root.posX, 0, Math.max(0, root.screenW - root.spriteW));
                    root.facing = root.targetX > root.posX ? 1 : -1;
                } else if (root.cover === "seeking" && !root.coverWanted) {
                    root.cover = "none";   // gave up before reaching cover — just wander
                } else if (root.cover === "hidden" && !root.coverWanted) {
                    // Leaving fullscreen — play the cancel outro and resume.
                    root.cover = "none";
                    root.modeName = "";
                    root.modePlayer = null;
                    triggerAction("unstealth");
                }
            }

            const fin = root._animFinished;
            root._animFinished = false;

            // Active action owns the frame and pauses movement.
            if (root.action !== null) {
                const ra = Brain.seqTick(root.action, root.actionSteps,
                                         16, fin, Math.random());
                root.action = ra.player;   // null when the sequence ends
                // A finished idle behavior (sit/nap) hands control back to the
                // wander: pick a fresh target and walk on.
                if (ra.player === null && root._idleAction) {
                    root._idleAction = false;
                    root.targetX = Brain.chooseTarget(0, Math.max(0, root.screenW - root.spriteW), Math.random());
                    root.facing = root.targetX > root.posX ? 1 : -1;
                }
                return;
            }

            // Otherwise a mode sequence owns the frame (loop steps just hold).
            if (root.modePlayer !== null) {
                const rm = Brain.seqTick(root.modePlayer, MascotConfig.modes[root.modeName],
                                         16, fin, Math.random());
                root.modePlayer = rm.player;
                return;
            }

            // Base wander (faster while sprinting — fleeing or CPU-busy).
            const sp = root.sprinting ? MascotConfig.runSpeed : MascotConfig.speed;
            const s = Brain.walkStep(root.posX, root.targetX, sp);
            root.posX = s.x;
            if (s.dir !== 0)
                root.facing = s.dir;
            if (s.arrived) {
                root.fleeing = false;   // reached safety — back to normal
                // Reached the corner while seeking cover — crouch into stealth.
                if (root.cover === "seeking") {
                    root.cover = "hidden";
                    root.modeName = "stealth";
                    root.modePlayer = Brain.seqEnter(MascotConfig.modes["stealth"], 0, Math.random());
                    return;
                }
                // Choose what to do during this dwell: plain idle, or an idle
                // behavior sequence (sit / nap / box).
                const behavior = Brain.pickIdle(MascotConfig.idleWeights, Math.random());
                if (behavior === "idle") {
                    root.paused = true;
                    pauseTimer.interval = MascotConfig.pauseMinMs
                        + Math.floor(Math.random() * (MascotConfig.pauseMaxMs - MascotConfig.pauseMinMs));
                    pauseTimer.restart();
                } else if (behavior === "box") {
                    root._idleAction = true;
                    triggerActionSteps("box", buildBoxSteps());   // fresh random routine
                } else {
                    root._idleAction = true;
                    triggerAction(behavior);
                }
            }
        }
    }

    // After an idle dwell, pick a new wander target.
    Timer {
        id: pauseTimer
        repeat: false
        onTriggered: {
            root.targetX = Brain.chooseTarget(0, Math.max(0, root.screenW - root.spriteW), Math.random());
            root.facing = root.targetX > root.posX ? 1 : -1;
            root.paused = false;
        }
    }

    // --- Notification reaction ---
    property int _notifPrev: 0
    readonly property int notifCount: Notif.NotificationService.notifications.values.length
    onNotifCountChanged: {
        if (Brain.notificationArrived(_notifPrev, notifCount))
            triggerAction("attack");   // swat at the new notification
        _notifPrev = notifCount;
    }
}
