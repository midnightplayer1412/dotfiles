import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".."

// Now-playing card. RELEVANT only when a player exists — the frame auto-hides it
// (and the desktop stack reflows) when nothing is playing.
Item {
    id: w
    readonly property bool relevant: player !== null

    readonly property var player: {
        const ps = Mpris.players.values;
        if (ps.length === 0) return null;
        for (const p of ps) if (p.playbackState === MprisPlaybackState.Playing) return p;
        return ps[0];
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12
        visible: w.player !== null

        Rectangle {
            Layout.preferredWidth: 64; Layout.preferredHeight: 64
            radius: 8; color: Qt.darker(Theme.surface, 1.3); clip: true
            Image {
                anchors.fill: parent
                source: w.player && w.player.trackArtUrl ? w.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true; elide: Text.ElideRight
                text: w.player ? (w.player.trackTitle || "—") : ""
                color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true
            }
            Text {
                Layout.fillWidth: true; elide: Text.ElideRight
                text: w.player ? (w.player.trackArtist || "") : ""
                color: Theme.surfaceText; opacity: 0.7; font.family: Theme.fontFamily; font.pixelSize: 12
            }
            RowLayout {
                spacing: 16
                Repeater {
                    model: [
                        { g: "\u{F04AE}", act: "prev" },
                        { g: "\u{F040A}", act: "toggle" },
                        { g: "\u{F04AD}", act: "next" }
                    ]
                    delegate: Text {
                        required property var modelData
                        text: modelData.g; font.family: Theme.glyphFont; font.pixelSize: 20; color: Theme.primary
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -6
                            onClicked: {
                                const p = w.player; if (!p) return;
                                if (modelData.act === "prev" && p.canGoPrevious) p.previous();
                                else if (modelData.act === "next" && p.canGoNext) p.next();
                                else if (modelData.act === "toggle" && p.canTogglePlaying) p.togglePlaying();
                            }
                        }
                    }
                }
            }
        }
    }
}
