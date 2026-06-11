import QtQuick
import Quickshell
import Quickshell.Wayland

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
        }

        MouseArea {
            anchors.fill: parent
            property real grabDX: 0
            property real grabDY: 0
            property bool moved: false

            onPressed: mouse => {
                moved = false;
                grabDX = mouse.x;
                grabDY = mouse.y;
                brain.dragging = true;
            }
            onPositionChanged: mouse => {
                if (!brain.dragging)
                    return;
                moved = true;
                brain.posX = holder.x + mouse.x - grabDX;
                brain.posY = holder.y + mouse.y - grabDY;
            }
            onReleased: {
                brain.dragging = false;
                if (moved) {
                    brain.vy = 0;
                    brain.airborne = true;     // dropped — fall back to the floor
                }
            }
            onClicked: {
                if (!moved)
                    brain.triggerReaction("pet");
            }
        }
    }

    // Click-through everywhere except the sprite. While dragging, drop the mask
    // so fast cursor moves outside the sprite rect still reach the MouseArea.
    Region { id: spriteRegion; item: holder }
    mask: brain.dragging ? null : spriteRegion
}
