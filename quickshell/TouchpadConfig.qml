pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Touchpad enabled/disabled state, persisted to
// ~/.config/quickshell/touchpad-config.json and edited from Settings → Input
// or the Super+Shift+T bind.
//
// apply() funnels through hypr/scripts/apply-touchpad.sh — the single owner of
// the `hyprctl keyword device[...]` call. The same script runs from
// autostart.conf as `exec =`, so the state survives login and config reloads.
//
// watchChanges is what keeps the two control surfaces in sync: the keybind
// script writes this file directly, and the Settings switch follows without any
// IPC between them.
Singleton {
    id: cfg

    property alias enabled: adapter.enabled   // false = touchpad off

    function save() { view.writeAdapter(); }

    function apply() {
        applyProc.command = [
            Quickshell.env("HOME") + "/.config/hypr/scripts/apply-touchpad.sh"
        ];
        applyProc.running = true;
    }

    function setEnabled(v) { cfg.enabled = v; save(); apply(); }
    function toggle() { cfg.setEnabled(!cfg.enabled); }

    Process { id: applyProc }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/touchpad-config.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()

        JsonAdapter {
            id: adapter
            // Defaults to on — a missing or unreadable config must never leave
            // the user without a pointer.
            property bool enabled: true
        }
    }
}
