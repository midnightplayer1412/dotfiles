import Quickshell
import Quickshell.Hyprland
import "bar" as Bar
import "launcher" as Launcher
import "hud" as HUD
import "notifications" as Notifications
import "calendar" as Calendar

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

    GlobalShortcut {
        name: "notifications_toggle"
        onPressed: Notifications.NotificationCenterState.toggle(focusedScreen())
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

    // HUD windows on each screen
    Variants {
        model: Quickshell.screens

        HUD.HUD {
            required property var modelData
            screen: modelData
        }
    }

    // Notification popups — focused screen only
    Variants {
        model: {
            const name = Hyprland.focusedMonitor?.name ?? "";
            for (const s of Quickshell.screens) {
                if (s.name === name) return [s];
            }
            return Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : [];
        }

        Notifications.Popups {
            required property var modelData
            screen: modelData
        }
    }

    // Notification center drawer — only on target screen when visible
    Variants {
        model: {
            if (Notifications.NotificationCenterState.visible
                && Notifications.NotificationCenterState.targetScreen) {
                return [Notifications.NotificationCenterState.targetScreen];
            }
            return [];
        }

        Notifications.Drawer {
            required property var modelData
            screen: modelData
        }
    }

    // Calendar popup — only on target screen when visible
    Variants {
        model: {
            if (Calendar.CalendarState.visible && Calendar.CalendarState.targetScreen) {
                return [Calendar.CalendarState.targetScreen];
            }
            return [];
        }

        Calendar.Calendar {
            required property var modelData
            screen: modelData
        }
    }
}
