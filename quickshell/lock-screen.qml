import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "lock" as Lock
import "."

// Dedicated lock instance. Launched on demand via:
//   qs -p ~/.config/quickshell/lock-screen.qml -d -n
//
// IMPORTANT: this entry lives at the quickshell/ root (not under lock/) so the
// config root is quickshell/ and the Theme singleton resolves. Rooting at lock/
// puts `import ".."` (→ Theme) above the config root, which Quickshell won't
// register — yielding "Theme is not defined" and unthemed (black) text.
//
// Locks immediately; on PAM success unlocks and quits the process.
ShellRoot {
    id: rootShell

    // While locked, force fcitx5 to a raw English keyboard so the password is
    // typed as plain ASCII regardless of the pre-lock input language (e.g. zh
    // pinyin). The pre-lock state is remembered and restored on unlock.
    //   fcitx5-remote prints: 1 = inactive (EN/raw), 2 = active (e.g. CN)
    //   fcitx5-remote -c = deactivate, -o = activate
    property string imePrev: "1"

    Process {
        id: imeQuery
        command: ["fcitx5-remote"]
        stdout: StdioCollector {
            onStreamFinished: {
                rootShell.imePrev = text.trim();
                imeOff.running = true;   // deactivate → raw English keyboard
            }
        }
    }
    Process { id: imeOff; command: ["fcitx5-remote", "-c"] }
    Process { id: imeRestore; command: ["fcitx5-remote", "-o"] }

    // ShellRoot has no attached Component.onCompleted; host the startup hook on
    // an inert Item instead.
    Item { Component.onCompleted: imeQuery.running = true }

    WlSessionLock {
        id: lock
        locked: true

        // One surface per screen. The focused monitor shows the input.
        WlSessionLockSurface {
            id: surface
            color: "black"

            readonly property bool isFocused:
                (Hyprland.focusedMonitor?.name ?? "") === (surface.screen?.name ?? "_")

            Lock.LockView {
                anchors.fill: parent
                preview: false
                context: Lock.LockContext
                showInput: surface.isFocused
            }
        }
    }

    // Unlock + exit when PAM succeeds. Restore the pre-lock input method first,
    // then quit after a short delay so fcitx5-remote dispatches before the
    // process exits.
    Connections {
        target: Lock.LockContext
        function onUnlocked() {
            lock.locked = false;
            if (rootShell.imePrev === "2") imeRestore.running = true;
            quitTimer.start();
        }
    }

    Timer { id: quitTimer; interval: 200; onTriggered: Qt.quit() }
}
