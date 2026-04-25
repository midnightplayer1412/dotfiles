import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import ".."

Rectangle {
    id: root

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

    radius: 12
    color: Theme.surfaceContainer
    border.color: Theme.outline
    border.width: 1

    Behavior on implicitHeight {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Album art / fallback
        Rectangle {
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56
            radius: 8
            color: Theme.surface
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
                text: "♪"
                color: Theme.outline
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
                    { glyph: "⏮", action: "previous", enabled: "canGoPrevious" },
                    { glyph: "⏯", action: "togglePlaying", enabled: "canTogglePlaying" },
                    { glyph: "⏭", action: "next", enabled: "canGoNext" }
                ]

                delegate: Rectangle {
                    id: btn
                    required property var modelData

                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 14

                    readonly property bool isEnabled: root.activePlayer
                        ? root.activePlayer[modelData.enabled] === true
                        : false

                    color: btnMouse.containsMouse && isEnabled
                        ? Theme.primary
                        : "transparent"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: btn.modelData.glyph
                        color: btnMouse.containsMouse && btn.isEnabled
                            ? Theme.primaryText
                            : (btn.isEnabled ? Theme.surfaceText : Theme.outline)
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: btn.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: btn.isEnabled
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
}
