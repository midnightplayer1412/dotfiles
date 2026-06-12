import QtQuick
import Quickshell
import Quickshell.Wayland
import "brain.js" as Brain

PanelWindow {
    id: win

    // `screen` is the inherited PanelWindow property (set by the mount via
    // `screen: modelData`). Do NOT redeclare it — and the window is mounted
    // once per screen (like the bar) for reliable output placement; only the
    // window on the configured screen (or the primary, as a fallback) shows.
    readonly property string targetName: {
        for (const s of Quickshell.screens)
            if (s.name === MascotConfig.screenName)
                return s.name;
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
    }
    visible: win.screen && win.screen.name === targetName

    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MascotBrain {
        id: brain
        screenW: win.screen.width
        screenH: win.screen.height
        spriteW: sprite.width
        spriteH: sprite.height
    }

    Item {
        id: holder
        x: brain.posX
        y: brain.posY
        width: sprite.width
        height: sprite.height

        MascotSprite {
            id: sprite
            clip: brain.state
            transform: Scale {
                origin.x: sprite.width / 2
                xScale: brain.facing < 0 ? -1 : 1
            }
            onFinished: brain.noteAnimFinished()
        }

        MouseArea {
            id: petArea
            anchors.fill: parent
            hoverEnabled: true
            // Press origin (sprite-local) used to tell a click from a drag.
            property real pressX: 0
            property real pressY: 0
            property real grabDX: 0
            property real grabDY: 0
            // Pixels the cursor must travel before a press becomes a pick-up;
            // below this, a release is a click (pet). Prevents incidental
            // pointer jitter during a click from being read as a drag.
            readonly property real dragThreshold: 8
            // Taps counted within doubleClickMs: 1 = pet, 2+ = hop.
            property int tapCount: 0
            // Last hover sample + current motion burst, to measure the cursor's
            // average speed over the sprite (a fast swipe = a startling swat).
            property real hoverX: 0
            property real hoverY: 0
            property real hoverT: 0      // time of the last hover event
            property real burstT: 0      // start time of the current motion burst
            property real burstDist: 0   // distance accumulated this burst

            onPressed: mouse => {
                pressX = mouse.x;
                pressY = mouse.y;
                grabDX = mouse.x;
                grabDY = mouse.y;
                // Do NOT enter dragging yet — wait until movement exceeds the
                // threshold so a plain click can still register as a pet.
            }
            onPositionChanged: mouse => {
                if (pressed) {
                    if (!brain.dragging) {
                        if (!Brain.exceedsDragThreshold(mouse.x - pressX, mouse.y - pressY, dragThreshold))
                            return;
                        brain.dragging = true;   // crossed the threshold — pick up
                    }
                    brain.posX = holder.x + mouse.x - grabDX;
                    brain.posY = holder.y + mouse.y - grabDY;
                } else {
                    // Hovering (no button): a fast swipe over the cat scares it.
                    // Average speed over a motion burst — per-event dt is too
                    // noisy (tiny gaps read as huge speed on ordinary moves).
                    const now = Date.now();
                    const dx = mouse.x - hoverX;
                    const dy = mouse.y - hoverY;
                    if (hoverT === 0 || now - hoverT > MascotConfig.startleGapMs) {
                        burstT = now;          // just entered, or paused — new burst
                        burstDist = 0;
                    } else {
                        burstDist += Math.sqrt(dx * dx + dy * dy);
                    }
                    if (Brain.exceedsSwipeSpeed(burstDist, now - burstT,
                                                MascotConfig.startleMinSpanMs, MascotConfig.startleSpeed)) {
                        brain.startle(holder.x + mouse.x);
                        burstT = now; burstDist = 0;   // reset so it doesn't re-fire
                    }
                    hoverX = mouse.x; hoverY = mouse.y; hoverT = now;
                }
            }
            onReleased: {
                if (brain.dragging) {
                    brain.dragging = false;
                    brain.vy = 0;
                    brain.airborne = true;     // dropped — fall back to the floor
                } else {
                    tapCount += 1;             // defer: 1 tap = pet, 2 = hop
                    tapTimer.restart();
                }
            }

            // Resolve a tap once the double-click window closes.
            Timer {
                id: tapTimer
                interval: MascotConfig.doubleClickMs
                repeat: false
                onTriggered: {
                    if (petArea.tapCount === 1)
                        brain.triggerAction("pet");
                    else if (petArea.tapCount >= 2)
                        brain.hop();
                    petArea.tapCount = 0;
                }
            }
        }
    }

    // Click-through everywhere except the sprite. While dragging, drop the mask
    // so fast cursor moves outside the sprite rect still reach the MouseArea.
    Region { id: spriteRegion; item: holder }
    mask: brain.dragging ? null : spriteRegion
}
