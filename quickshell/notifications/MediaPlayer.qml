import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import ".."
import "../ui" as Ui

Ui.Surface {
    id: root
    level: 1
    radius: 12

    // Pick the first player that's actively playing, otherwise the first paused one.
    readonly property var activePlayer: {
        const players = Mpris.players.values;
        if (players.length === 0) return null;
        for (const p of players) {
            if (p.playbackState === MprisPlaybackState.Playing) return p;
        }
        return players[0];
    }

    visible: activePlayer !== null
    implicitHeight: visible ? layout.implicitHeight + 20 : 0

    Behavior on implicitHeight {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Album art / fallback
        Ui.Surface {
            level: 0
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56
            radius: 8
            clip: true

            Image {
                anchors.fill: parent
                source: root.activePlayer?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: "\u{F075A}"   // nf-md-music
                color: Theme.outline
                font.family: Theme.glyphFont
                font.pixelSize: 24
                visible: !root.activePlayer?.trackArtUrl
                    || parent.children[0].status !== Image.Ready
            }
        }

        // Title / artist
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.activePlayer?.trackTitle || "Unknown"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.activePlayer?.trackArtist || ""
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
                visible: text.length > 0
            }

            Text {
                Layout.fillWidth: true
                text: root.activePlayer?.identity || ""
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideRight
                visible: text.length > 0 && !root.activePlayer?.trackArtist
            }
        }

        // Transport controls
        RowLayout {
            spacing: 4

            Repeater {
                model: [
                    { glyph: "\u{F04AE}", action: "previous", enabled: "canGoPrevious" },        // skip-previous
                    { glyph: "", action: "togglePlaying", enabled: "canTogglePlaying" },          // play/pause (state-aware)
                    { glyph: "\u{F04AD}", action: "next", enabled: "canGoNext" }                  // skip-next
                ]

                delegate: Ui.IconButton {
                    id: btn
                    required property var modelData

                    bg: "bare"
                    glyphSize: 14

                    enabled: root.activePlayer
                        ? root.activePlayer[modelData.enabled] === true
                        : false

                    // play/pause reflects current playback state; others are static
                    glyph: btn.modelData.action === "togglePlaying"
                        ? (root.activePlayer?.playbackState === MprisPlaybackState.Playing
                            ? "\u{F03E4}"   // pause
                            : "\u{F040A}")  // play
                        : btn.modelData.glyph

                    onClicked: {
                        const p = root.activePlayer;
                        if (!p) return;
                        if (btn.modelData.action === "previous") p.previous();
                        else if (btn.modelData.action === "next") p.next();
                        else if (btn.modelData.action === "togglePlaying") p.togglePlaying();
                    }
                }
            }
        }
    }
}
