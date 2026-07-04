import QtQuick
import Quickshell
import Quickshell.Hyprland
import "bar" as Bar
import "launcher" as Launcher
import "hud" as HUD
import "notifications" as Notifications
import "calendar" as Calendar
import "connection" as Connection
import "overview" as Overview
import "cheatsheet" as Cheatsheet
import "wallpaper" as Wallpaper
import "mascot" as Mascot
import "settings" as Settings
import "widgets" as Widgets

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

    // Armed alt-tab (Super+Alt+Tab). The Hyprland submap routes every key in the
    // held cycle here; commit fires on Super release (or Enter as a fallback).
    GlobalShortcut {
        name: "overview_altTabNext"
        onPressed: Overview.OverviewState.altTabStep(focusedScreen(), 1)
    }
    GlobalShortcut {
        name: "overview_altTabPrev"
        onPressed: Overview.OverviewState.altTabStep(focusedScreen(), -1)
    }
    GlobalShortcut {
        name: "overview_altTabCommit"
        onPressed: Overview.OverviewState.altTabCommit()
    }
    GlobalShortcut {
        name: "overview_altTabCancel"
        onPressed: Overview.OverviewState.altTabCancel()
    }
    GlobalShortcut {
        name: "overview_altTabClose"
        onPressed: Overview.OverviewState.altTabCloseHighlighted()
    }

    GlobalShortcut {
        name: "cheatsheet_toggle"
        onPressed: Cheatsheet.CheatsheetState.toggle(focusedScreen())
    }

    GlobalShortcut {
        name: "settings_toggle"
        onPressed: Settings.SettingsState.toggle(focusedScreen())
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

    // Keybinding cheatsheet — fullscreen overlay on target screen when visible
    Variants {
        model: {
            if (Cheatsheet.CheatsheetState.visible && Cheatsheet.CheatsheetState.targetScreen) {
                return [Cheatsheet.CheatsheetState.targetScreen];
            }
            return [];
        }

        Cheatsheet.Cheatsheet {
            required property var modelData
            screen: modelData
        }
    }

    // Settings panel — fullscreen overlay on target screen when visible
    Variants {
        model: {
            if (Settings.SettingsState.visible && Settings.SettingsState.targetScreen) {
                return [Settings.SettingsState.targetScreen];
            }
            return [];
        }

        Settings.SettingsWindow {
            required property var modelData
            screen: modelData
        }
    }

    // Connection / audio container — right-side, on the target screen when open.
    // A single container hosts either the unified connection panel or the audio
    // panel (ConnectionState.openPanel); bar icons toggle it.
    Variants {
        model: Connection.ConnectionState.visible
            ? [Connection.ConnectionState.targetScreen] : []

        Connection.Drawer {
            required property var modelData
            screen: modelData
        }
    }

    // Wallpaper picker — fullscreen overlay on target screen when visible
    Variants {
        model: {
            if (Wallpaper.WallpaperService.pickerVisible
                && Wallpaper.WallpaperService.targetScreen) {
                return [Wallpaper.WallpaperService.targetScreen];
            }
            return [];
        }

        Wallpaper.PickerWindow {
            required property var modelData
            screen: modelData
        }
    }

    // Desktop mascot — one window per screen (same pattern as the bar, for
    // reliable layer-shell output placement). Each window shows itself only on
    // the configured screen (MascotConfig.screenName), falling back to primary.
    Variants {
        model: Quickshell.screens

        Mascot.Mascot {
            required property var modelData
            screen: modelData
        }
    }

    // Desktop widgets — one bottom-layer window per screen; each self-gates to
    // the primary screen (v1), like the mascot.
    Variants {
        model: Quickshell.screens
        Widgets.DesktopLayer { required property var modelData; screen: modelData }
    }

    // Wake WallpaperService at startup so state.json is loaded and the
    // cycle Timer runs from boot. ShellRoot doesn't support attached
    // Component lifecycle, so host the wake-up on an inert Item.
    Item {
        visible: false
        Component.onCompleted: void Wallpaper.WallpaperService.statePath
    }
}
