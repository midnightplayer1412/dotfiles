import Quickshell
import Quickshell.Hyprland
import "bar" as Bar
import "launcher" as Launcher

ShellRoot {
    function focusedScreen() {
        const monitorName = Hyprland.focusedMonitor?.name ?? "";
        for (const s of Quickshell.screens) {
            if (s.name === monitorName) return s;
        }
        return Quickshell.screens[0];
    }

    GlobalShortcut {
        name: "launcher_toggle"
        onPressed: LauncherState.toggle(focusedScreen())
    }

    // Status bar on each screen
    Variants {
        model: Quickshell.screens

        Bar.Bar {
            required property var modelData
            screen: modelData
        }
    }

    // Hover trigger zone on each screen
    Variants {
        model: Quickshell.screens

        Launcher.HoverZone {
            required property var modelData
            screen: modelData
        }
    }

    // Launcher panel — only on target screen when visible
    Variants {
        model: {
            if (LauncherState.visible && LauncherState.targetScreen) {
                return [LauncherState.targetScreen];
            }
            return [];
        }

        Launcher.Launcher {
            required property var modelData
            screen: modelData
        }
    }
}
