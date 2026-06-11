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
    property string currentReaction: ""   // "", "pet", or "alert"

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
    readonly property bool moving: !paused && !airborne && !dragging
        && currentReaction === "" && Math.abs(targetX - posX) > MascotConfig.speed
    readonly property string state: Brain.resolveState({
        "dragging": dragging,
        "airborne": airborne,
        "reaction": currentReaction,
        "lowBattery": lowBattery,
        "moving": moving
    })

    Component.onCompleted: {
        posY = floorY;
        targetX = Brain.chooseTarget(0, Math.max(0, screenW - spriteW), Math.random());
        _notifPrev = notifCount;
    }

    // --- Physics / wander tick ---
    Timer {
        interval: 16; repeat: true; running: true
        onTriggered: {
            if (root.dragging)
                return;
            if (root.airborne) {
                const g = Brain.gravityStep(root.posY, root.vy, root.floorY, MascotConfig.gravity);
                root.posY = g.y;
                root.vy = g.vy;
                if (g.landed)
                    root.airborne = false;
                return;
            }
            if (root.currentReaction !== "" || root.paused)
                return;
            const s = Brain.walkStep(root.posX, root.targetX, MascotConfig.speed);
            root.posX = s.x;
            if (s.dir !== 0)
                root.facing = s.dir;
            if (s.arrived) {
                root.paused = true;
                pauseTimer.interval = MascotConfig.pauseMinMs
                    + Math.floor(Math.random() * (MascotConfig.pauseMaxMs - MascotConfig.pauseMinMs));
                pauseTimer.restart();
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

    // One-shot reaction window.
    Timer {
        id: reactionTimer
        repeat: false
        interval: MascotConfig.reactionMs
        onTriggered: root.currentReaction = ""
    }
    function triggerReaction(name) {
        root.currentReaction = name;
        reactionTimer.restart();
    }

    // --- Notification reaction ---
    property int _notifPrev: 0
    readonly property int notifCount: Notif.NotificationService.notifications.values.length
    onNotifCountChanged: {
        if (Brain.notificationArrived(_notifPrev, notifCount))
            triggerReaction("alert");
        _notifPrev = notifCount;
    }
}
