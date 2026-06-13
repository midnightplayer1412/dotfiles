import QtQuick
import Quickshell
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

    // Unlock + exit when PAM succeeds.
    Connections {
        target: Lock.LockContext
        function onUnlocked() {
            lock.locked = false;
            Qt.quit();
        }
    }
}
