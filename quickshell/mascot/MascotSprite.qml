import QtQuick

Item {
    id: root

    // Logical state name from MascotConfig.animations (e.g. "idle", "walk").
    property string clip: "idle"

    width: MascotConfig.frameW * MascotConfig.scale
    height: MascotConfig.frameH * MascotConfig.scale

    // When a clip with an intro is requested, this holds the main clip to play
    // once the intro finishes.
    property string _pendingMain: ""

    AnimatedSprite {
        id: spr
        anchors.fill: parent
        source: MascotConfig.sheet
        frameWidth: MascotConfig.frameW
        frameHeight: MascotConfig.frameH
        frameX: 0
        smooth: false            // crisp pixel-art scaling
        running: false           // _apply() calls restart(), which starts it
    }

    function _apply(name) {
        const d = MascotConfig.animations[name];
        if (!d)
            return;
        spr.frameY = d.y;
        spr.frameCount = d.n;
        spr.frameDuration = d.dur;
        spr.loops = d.loop ? AnimatedSprite.Infinite : 1;
        spr.restart();
    }

    function _select(name) {
        const d = MascotConfig.animations[name] || MascotConfig.animations["idle"];
        if (d.intro) {
            root._pendingMain = name;
            _apply(d.intro);
        } else {
            root._pendingMain = "";
            _apply(name);
        }
    }

    onClipChanged: root._select(clip)
    Component.onCompleted: root._select(clip)

    Connections {
        target: spr
        function onFinished() {
            if (root._pendingMain !== "") {
                const m = root._pendingMain;
                root._pendingMain = "";
                root._apply(m);   // main clip loops; its own .intro is ignored here
            }
        }
    }
}
