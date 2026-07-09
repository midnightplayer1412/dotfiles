import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".."
import "../ui" as Ui

// Now-playing card. RELEVANT only when a player exists — the frame auto-hides it
// (and the desktop stack reflows) when nothing is playing. Look follows the
// active widget style; the Data-dense preset adds a scrub bar with times.
Item {
    id: w
    readonly property bool relevant: player !== null

    readonly property var player: {
        const ps = Mpris.players.values;
        if (ps.length === 0) return null;
        for (const p of ps) if (p.playbackState === MprisPlaybackState.Playing) return p;
        return ps[0];
    }
    readonly property bool playing: player !== null && player.playbackState === MprisPlaybackState.Playing

    readonly property string preset: Ui.WidgetStyle.preset
    readonly property bool dense: Ui.WidgetStyle.dense

    // Live position (dense scrub bar). Reading player.position refetches over DBus.
    property real pos: 0
    readonly property real len: player && player.length ? player.length : 0
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: w.dense && w.playing && w.len > 0
        onTriggered: w.pos = w.player ? w.player.position : 0
    }

    function fmt(t) {
        if (!t || t < 0) return "0:00";
        const s = Math.floor(t % 60), m = Math.floor(t / 60);
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        visible: w.player !== null

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Album art (or a themed placeholder — gradient on Playful).
            Rectangle {
                Layout.preferredWidth: w.preset === "playful" ? 52 : w.dense ? 44 : 56
                Layout.preferredHeight: w.preset === "playful" ? 52 : w.dense ? 44 : 56
                Layout.alignment: Qt.AlignVCenter
                radius: w.preset === "playful" ? 12 : 8
                clip: true
                color: Qt.darker(Theme.surface, 1.3)
                gradient: (w.preset === "playful" && !artReady) ? artGrad : null
                readonly property bool artReady: art.status === Image.Ready
                Image {
                    id: art
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
                    color: Theme.surfaceText; font.family: Theme.fontFamily
                    font.pixelSize: 14; font.weight: w.preset === "minimal" ? Font.Normal : Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true; elide: Text.ElideRight
                    text: w.player ? (w.player.trackArtist || "") : ""
                    color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity
                    font.family: Theme.fontFamily; font.pixelSize: 12
                }
                RowLayout {
                    spacing: w.preset === "playful" ? 12 : 16
                    Layout.topMargin: 2
                    Repeater {
                        model: [
                            { g: "\u{F04AE}", act: "prev",   pill: false },
                            { g: w.playing ? "\u{F03E4}" : "\u{F040A}", act: "toggle", pill: true },
                            { g: "\u{F04AD}", act: "next",   pill: false }
                        ]
                        delegate: Item {
                            required property var modelData
                            readonly property bool pill: modelData.pill && w.preset === "playful"
                            implicitWidth: pill ? 30 : ctl.implicitWidth
                            implicitHeight: pill ? 30 : ctl.implicitHeight
                            Layout.alignment: Qt.AlignVCenter
                            Rectangle {
                                anchors.fill: parent
                                visible: parent.pill
                                radius: width / 2
                                color: Ui.WidgetStyle.accent
                            }
                            Text {
                                id: ctl
                                anchors.centerIn: parent
                                text: modelData.g
                                font.family: Theme.glyphFont
                                font.pixelSize: parent.pill ? 16 : 20
                                color: parent.pill ? Theme.primaryText : Ui.WidgetStyle.accent
                            }
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

        // Dense: scrub bar with elapsed / remaining times.
        RowLayout {
            Layout.fillWidth: true
            visible: w.dense && w.len > 0
            spacing: 8
            Text {
                text: w.fmt(w.pos); color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity
                font.family: Theme.fontFamily; font.pixelSize: 11
            }
            Rectangle {
                Layout.fillWidth: true; height: 4; radius: 2
                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.15)
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, w.len > 0 ? w.pos / w.len : 0))
                    height: parent.height; radius: parent.radius; color: Ui.WidgetStyle.accent
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
            Text {
                text: w.fmt(w.len); color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity
                font.family: Theme.fontFamily; font.pixelSize: 11
            }
        }
    }

    Gradient {
        id: artGrad
        orientation: Gradient.Vertical
        GradientStop { position: 0; color: Ui.WidgetStyle.gradA }
        GradientStop { position: 1; color: Ui.WidgetStyle.gradB }
    }
}
