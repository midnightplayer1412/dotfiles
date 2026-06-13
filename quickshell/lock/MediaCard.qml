import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".."

// Now-playing card (art + title/artist + transport). Visible only when a player
// exists. Mirrors the player-selection logic in notifications/MediaPlayer.qml.
Rectangle {
    id: card

    readonly property var player: {
        const ps = Mpris.players.values;
        if (ps.length === 0) return null;
        for (const p of ps) if (p.playbackState === MprisPlaybackState.Playing) return p;
        return ps[0];
    }
    readonly property bool playing:
        player && player.playbackState === MprisPlaybackState.Playing

    visible: player !== null
    implicitWidth: 360
    implicitHeight: 78
    radius: 14
    color: "#33000000"
    border.color: "#33ffffff"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Album art (falls back to a music glyph).
        Rectangle {
            Layout.preferredWidth: 58
            Layout.preferredHeight: 58
            radius: 10
            color: "#22ffffff"
            clip: true
            Image {
                anchors.fill: parent
                source: card.player && card.player.trackArtUrl ? card.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                asynchronous: true
                cache: true
            }
            Text {
                anchors.centerIn: parent
                visible: !card.player || !card.player.trackArtUrl
                text: "\u{F075A}"      // nf-md-music
                color: "white"
                font.family: Theme.glyphFont
                font.pixelSize: 26
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: card.player ? (card.player.trackTitle || "Unknown") : ""
                color: "white"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: card.player ? (card.player.trackArtist || "") : ""
                color: "#cccccc"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }

        // Transport controls
        RowLayout {
            spacing: 6
            Repeater {
                model: [
                    { glyph: "\u{F04AE}", act: "prev" },   // skip-previous
                    { glyph: "", act: "toggle" },          // play/pause — resolved reactively below
                    { glyph: "\u{F04AD}", act: "next" }    // skip-next
                ]
                delegate: Text {
                    required property var modelData
                    // Resolve play/pause in the binding so it tracks playbackState
                    // (an inline-array glyph would freeze at its initial value).
                    text: modelData.act === "toggle"
                        ? (card.playing ? "\u{F03E4}" : "\u{F040A}")
                        : modelData.glyph
                    color: tMouse.containsMouse ? Theme.primary : "white"
                    font.family: Theme.glyphFont
                    font.pixelSize: modelData.act === "toggle" ? 26 : 20
                    MouseArea {
                        id: tMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!card.player) return;
                            if (modelData.act === "prev" && card.player.canGoPrevious) card.player.previous();
                            else if (modelData.act === "next" && card.player.canGoNext) card.player.next();
                            else if (modelData.act === "toggle" && card.player.canTogglePlaying) card.player.togglePlaying();
                        }
                    }
                }
            }
        }
    }
}
