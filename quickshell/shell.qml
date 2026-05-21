import Quickshell
import Quickshell.Hyprland
import "bar" as Bar
import "launcher" as Launcher
import "hud" as HUD
import "notifications" as Notifications
import "calendar" as Calendar
import "connection" as Connection
import "overview" as Overview

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

    GlobalShortcut {
        name: "overview_toggle"
        onPressed: Overview.OverviewState.toggle(focusedScreen())
    }

    // Status bar on each screen
    Variants {
        model: Quickshell.screens

        Bar.Bar {
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

    // Overview — fullscreen panel on target screen when visible
    Variants {
        model: {
            if (Overview.OverviewState.visible && Overview.OverviewState.targetScreen) {
                return [Overview.OverviewState.targetScreen];
            }
            return [];
        }

        Overview.Overview {
            required property var modelData
            screen: modelData
        }
    }

    // Connection trigger zone — transparent, always per-screen
    Variants {
        model: Quickshell.screens

        Connection.HubTrigger {
            required property var modelData
            screen: modelData
        }
    }

    // Connection hub — only on the screen that's hovered or has the drawer open
    Variants {
        model: Connection.ConnectionState.hubVisible
            ? [Connection.ConnectionState.hubScreen] : []

        Connection.Hub {
            required property var modelData
            screen: modelData
        }
    }

    // Connection drawer — only on target screen when a tab is active
    Variants {
        model: {
            if (Connection.ConnectionState.activeTab !== ""
                && Connection.ConnectionState.targetScreen) {
                return [Connection.ConnectionState.targetScreen];
            }
            return [];
        }

        Connection.Drawer {
            required property var modelData
            screen: modelData
        }
    }
}
