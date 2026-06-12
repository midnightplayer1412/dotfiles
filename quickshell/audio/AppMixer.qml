import QtQuick
import Quickshell.Services.Pipewire
import ".."
import "../audio"

// Per-application volume mixer. Lists every audio playback stream and keeps the
// nodes "bound" via PwObjectTracker so their volume/mute stay live and writable.
Column {
    id: mixer

    spacing: 10

    // Application playback streams (isStream + isSink + audio), newest first.
    readonly property var streams: {
        const out = [];
        const vals = Pipewire.nodes.values;
        for (let i = 0; i < vals.length; i++) {
            const n = vals[i];
            if (n && n.isStream && n.isSink && n.audio) out.push(n);
        }
        return out;
    }

    PwObjectTracker { objects: mixer.streams }

    Text {
        text: "Apps"
        color: Theme.surfaceText
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.bold: true
    }

    Text {
        visible: mixer.streams.length === 0
        text: "No apps playing audio"
        color: Theme.outline
        font.family: Theme.fontFamily
        font.pixelSize: 12
        topPadding: 4
        bottomPadding: 4
    }

    Repeater {
        model: mixer.streams

        delegate: AppVolumeRow {
            required property var modelData
            width: mixer.width
            node: modelData
        }
    }
}
