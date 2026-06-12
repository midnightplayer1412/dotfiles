pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "brain.js" as Brain

// System signals the mascot reacts to. Exposes plain booleans so MascotBrain
// stays free of polling/IPC details.
Singleton {
    id: root

    // --- CPU busy (the cat runs while the machine works hard) ---
    // Sampled from two /proc/stat reads; the busy fraction between samples is
    // compared to a threshold (see brain.js cpuBusy/parseProcStat).
    property bool cpuBusy: false
    property var  _prevStat: null

    Process {
        id: statProc
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector { id: statOut }
        onExited: code => {
            if (code !== 0)
                return;
            const s = Brain.parseProcStat(statOut.text);
            if (root._prevStat)
                root.cpuBusy = Brain.cpuBusy(root._prevStat, s, MascotConfig.cpuBusyThreshold);
            root._prevStat = s;
        }
    }
    Timer {
        interval: MascotConfig.cpuPollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statProc.running = true
    }

    // --- Fullscreen focus (the cat hides/crouches so it isn't distracting) ---
    readonly property bool fullscreen: Hyprland.focusedWorkspace?.lastIpcObject?.hasfullscreen ?? false

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: Hyprland.refreshWorkspaces()
    }

    // Screencast/recording detection is a separate follow-up (best-effort).
    readonly property bool recording: false
}
