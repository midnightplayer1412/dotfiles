import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../ui" as Ui

// Full-screen karaoke overlay (Super+Shift+Y). A dimmed, blurred backdrop with
// the whole lyric sheet rendered as one column that glides upward line by line:
// the active line sits centered, big and accented, while neighbours shrink and
// fade by distance. Advancing a line animates the glide + the size/colour swap,
// so it reads as motion rather than a hard text swap. Grabs keyboard focus;
// click-outside / ESC / the keybind again closes it (same pattern as the SUPER+W
// dashboard). Plain-only tracks fall back to a large scrollable block;
// instrumental passages show the pulsing dots over the centre.
PanelWindow {
    id: root
    required property var screen

    readonly property var svc: LyricsService
    readonly property int idx: svc.currentIndex

    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: Ui.Surfaces.blurNamespace
    color: "transparent"

    // Click-outside / ESC close, matching the dashboard.
    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: LyricsState.closeKaraoke()
    }

    Rectangle {
        anchors.fill: parent
        color: "#e6000000"
        // Claim keyboard focus so Esc closes the overlay (the focus grab only
        // clears on click-outside, not on key presses).
        focus: true
        Keys.onEscapePressed: LyricsState.closeKaraoke()
        MouseArea { anchors.fill: parent; onClicked: LyricsState.closeKaraoke() }
    }

    // ── Synced: one gliding column, active line centred & enlarged ──────────
    Item {
        id: viewport
        anchors.centerIn: parent
        width: Math.min(root.screen.width - 200, 1200)
        height: root.screen.height * 0.72
        visible: root.svc.synced
        clip: true

        // Centre of the active line within the column's own coordinates. Tracks
        // live: as the active line grows (font animates) its centre shifts, and
        // when the active index changes it jumps to the new line — the column's
        // Behavior turns both into a smooth glide.
        readonly property real activeCenter: {
            const it = krep.itemAt(root.idx);
            return it ? it.y + it.height / 2 : 0;
        }

        Column {
            id: kcol
            width: viewport.width
            spacing: 20
            // Park the active line on the viewport's vertical centre.
            y: viewport.height / 2 - viewport.activeCenter
            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.InOutCubic } }

            Repeater {
                id: krep
                model: root.svc.lines.map(l => l.text)
                delegate: Text {
                    required property int index
                    required property var modelData
                    readonly property bool current: index === root.idx
                    readonly property int dist: Math.abs(index - root.idx)
                    width: kcol.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    // Blank the active line while the instrumental dots stand in.
                    text: (current && root.svc.instrumental) ? "" : modelData
                    color: current ? Ui.WidgetStyle.accent : Theme.surfaceText
                    opacity: current ? 1.0 : Math.max(0.15, 0.5 - dist * 0.1)
                    font.family: Theme.fontFamily
                    font.weight: current ? Font.Bold : Font.Medium
                    font.pixelSize: current ? 52 : (dist === 1 ? 32 : 26)
                    Behavior on opacity        { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on font.pixelSize { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on color          { ColorAnimation  { duration: 250 } }
                }
            }
        }

        // Instrumental dots sit at the viewport centre (over the active line).
        InstrumentalDots {
            anchors.centerIn: parent
            visible: root.svc.instrumental
            dotSize: 20
        }
    }

    // ── Plain-only: large scrollable block ─────────────────────────────────
    Flickable {
        anchors.centerIn: parent
        width: Math.min(root.screen.width - 200, 1000)
        height: root.screen.height * 0.7
        visible: root.svc.available && !root.svc.synced
        contentWidth: width
        contentHeight: plainCol.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: plainCol
            width: parent.width
            spacing: 12
            Repeater {
                model: root.svc.plainText ? root.svc.plainText.split("\n") : []
                delegate: Text {
                    required property var modelData
                    width: plainCol.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: modelData
                    color: Theme.surfaceText
                    opacity: 0.85
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                }
            }
        }
    }

    // ── Nothing available ──────────────────────────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        visible: !root.svc.available
        spacing: 14
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\u{F0387}"   // nf-md-music
            font.family: Theme.glyphFont; font.pixelSize: 64
            color: Theme.surfaceText; opacity: 0.4
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.svc.loading ? "Searching lyrics…"
                : root.svc.active ? "No lyrics found"
                : "Nothing playing"
            color: Theme.surfaceText; opacity: 0.7
            font.family: Theme.fontFamily; font.pixelSize: 26
        }
    }

    // Track title / artist, small and dimmed, pinned near the bottom.
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        visible: root.svc.active
        spacing: 2
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.svc.title
            color: Theme.surfaceText; opacity: 0.75
            font.family: Theme.fontFamily; font.pixelSize: 18; font.bold: true
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.svc.artist.length > 0
            text: root.svc.artist
            color: Theme.surfaceText; opacity: 0.55
            font.family: Theme.fontFamily; font.pixelSize: 15
        }
    }

    // Hint: how to close.
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 28
        text: "Esc to close"
        color: Theme.surfaceText; opacity: 0.4
        font.family: Theme.fontFamily; font.pixelSize: 13
    }
}
