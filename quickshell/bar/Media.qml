import QtQuick
import Quickshell.Services.Mpris
import ".."

// MPRIS transport. Horizontal bar: scrolling track title + previous/play-pause/
// next. Vertical bar: just the transport (a marquee can't fit a narrow strip).
// Collapses to 0 size when no player is present.
Item {
    id: media
    property bool horizontal: false
    readonly property int titleMaxW: 150     // marquee viewport before it scrolls

    // First actively-playing player, else the first available.
    readonly property var player: {
        const ps = Mpris.players.values;
        if (ps.length === 0) return null;
        for (const p of ps) if (p.playbackState === MprisPlaybackState.Playing) return p;
        return ps[0];
    }
    readonly property bool hasPlayer: player !== null
    readonly property string title: player?.trackTitle || ""

    visible: hasPlayer
    implicitWidth:  hasPlayer ? (horizontal ? rowL.implicitWidth : colL.implicitWidth) : 0
    implicitHeight: hasPlayer ? (horizontal ? rowL.implicitHeight : colL.implicitHeight) : 0

    // Reset the marquee to the start whenever the track changes.
    onTitleChanged: titleText.x = 0

    // One transport button (fixed square so the row/column align cleanly).
    component Xport: Item {
        property string act: ""
        property string glyph: ""
        property string enKey: ""
        width: Theme.barIconSize
        height: Theme.barIconSize
        readonly property bool isEnabled: media.player ? media.player[enKey] === true : false
        Text {
            anchors.centerIn: parent
            text: act === "toggle"
                ? (media.player?.playbackState === MprisPlaybackState.Playing ? "\u{F03E4}" : "\u{F040A}")
                : glyph
            font.family: Theme.glyphFont
            font.pixelSize: Theme.barIconSize - 2
            color: ma.containsMouse && isEnabled ? Theme.primary
                 : (isEnabled ? Theme.surfaceText : Theme.outline)
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            enabled: parent.isEnabled
            cursorShape: parent.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                const p = media.player;
                if (!p) return;
                if (act === "previous") p.previous();
                else if (act === "next") p.next();
                else p.togglePlaying();
            }
        }
    }

    // ── Horizontal: marquee title + transport ──
    Row {
        id: rowL
        visible: media.horizontal
        spacing: 6

        // Marquee viewport: clips the title; scrolls it when it overflows.
        Item {
            id: marquee
            visible: media.title.length > 0
            width: Math.min(titleText.implicitWidth, media.titleMaxW)
            height: Theme.barIconSize
            clip: true
            readonly property bool overflow: titleText.implicitWidth > width + 0.5

            Text {
                id: titleText
                text: media.title
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
                y: (marquee.height - height) / 2
                x: 0
            }

            // Ping-pong scroll: pause, slide left to reveal the tail, pause, slide
            // back. Speed scales with the overflow distance. Only runs when the
            // title overflows and the horizontal bar is showing.
            SequentialAnimation {
                running: marquee.overflow && media.horizontal
                loops: Animation.Infinite
                onStopped: titleText.x = 0
                PauseAnimation { duration: 1500 }
                NumberAnimation {
                    target: titleText; property: "x"
                    to: Math.min(0, marquee.width - titleText.implicitWidth)
                    duration: Math.max(1, titleText.implicitWidth - marquee.width) * 26
                    easing.type: Easing.InOutQuad
                }
                PauseAnimation { duration: 1500 }
                NumberAnimation {
                    target: titleText; property: "x"; to: 0
                    duration: Math.max(1, titleText.implicitWidth - marquee.width) * 26
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Xport { act: "previous"; glyph: "\u{F04AE}"; enKey: "canGoPrevious" }
        Xport { act: "toggle";                       enKey: "canTogglePlaying" }
        Xport { act: "next";     glyph: "\u{F04AD}"; enKey: "canGoNext" }
    }

    // ── Vertical: transport only ──
    Column {
        id: colL
        visible: !media.horizontal
        spacing: 2
        Xport { act: "previous"; glyph: "\u{F04AE}"; enKey: "canGoPrevious" }
        Xport { act: "toggle";                       enKey: "canTogglePlaying" }
        Xport { act: "next";     glyph: "\u{F04AD}"; enKey: "canGoNext" }
    }
}
