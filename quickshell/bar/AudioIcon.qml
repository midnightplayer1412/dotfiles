import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import "../connection" as Conn
import ".."

// Default-sink audio. Headphones glyph (dimmed when muted); scroll adjusts
// volume; middle-click mutes; left-click toggles the Audio panel (full mixer).
Item {
    id: vol
    property bool horizontal: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var au: sink && sink.audio ? sink.audio : null
    readonly property real level: au ? au.volume : 0
    readonly property bool muted: au ? au.muted : false
    // Headphones glyph — cleaner than the speaker set. Mute is shown by the
    // dimmed colour below; scroll still adjusts volume and opens the mixer.
    readonly property string glyph: "\u{F02CB}"   // nf-md-headphones

    // Keep the sink bound so volume/mute stay live and writable.
    PwObjectTracker { objects: vol.sink ? [vol.sink] : [] }

    implicitWidth: Theme.barIconSize
    implicitHeight: Theme.barIconSize

    function panelScreen() {
        const name = Hyprland.focusedMonitor?.name ?? "";
        for (const s of Quickshell.screens) if (s.name === name) return s;
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    Text {
        anchors.centerIn: parent
        text: vol.glyph
        font.family: Theme.glyphFont
        font.pixelSize: Theme.barIconSize
        color: mouse.containsMouse ? Theme.primary
             : (vol.muted ? Theme.outline : Theme.surfaceText)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (m) => {
            if (m.button === Qt.MiddleButton) {
                if (vol.au) vol.au.muted = !vol.au.muted;
            } else {
                Conn.ConnectionState.toggle("audio", vol.panelScreen());
            }
        }
        onWheel: (w) => {
            if (!vol.au) return;
            const step = 0.05;
            const d = w.angleDelta.y > 0 ? step : -step;
            vol.au.volume = Math.max(0, Math.min(1, vol.au.volume + d));
        }
    }
}
