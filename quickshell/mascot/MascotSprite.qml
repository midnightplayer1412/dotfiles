import QtQuick

Item {
    id: root

    // Logical state name from MascotConfig.animations (e.g. "idle", "walk").
    // The brain owns all sequencing; this component is a dumb player that just
    // shows the requested clip and reports when a one-shot clip completes.
    property string clip: "idle"

    // Emitted when a non-looping clip finishes playing, so the brain can advance
    // a scripted sequence (e.g. sleep_down -> low_battery, or a box routine).
    signal finished()

    width: MascotConfig.frameW * MascotConfig.scale
    height: MascotConfig.frameH * MascotConfig.scale

    AnimatedSprite {
        id: spr
        anchors.fill: parent
        source: MascotConfig.sheet
        frameWidth: MascotConfig.frameW
        frameHeight: MascotConfig.frameH
        frameX: 0
        smooth: false            // crisp pixel-art scaling
        running: false           // _apply() calls restart(), which starts it
        onFinished: root.finished()   // only fires for non-looping clips
    }

    function _apply(name) {
        const d = MascotConfig.animations[name] || MascotConfig.animations["idle"];
        spr.frameY = d.y;
        spr.frameCount = d.n;
        spr.frameDuration = d.dur;
        spr.loops = d.loop ? AnimatedSprite.Infinite : 1;
        spr.restart();
    }

    onClipChanged: root._apply(clip)
    Component.onCompleted: root._apply(clip)
}
