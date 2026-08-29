pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Touchpad runtime state (enabled, tap-to-click), persisted to
// ~/.config/quickshell/touchpad-config.json and edited from Settings → Input.
// The Super+Shift+T bind writes the `enabled` half of the same file.
//
// apply() funnels through hypr/scripts/apply-touchpad.sh — the single owner of
// the `hyprctl keyword device[...]` call. The same script runs from
// autostart.lua as a top-level exec, so the state survives login and reloads.
//
// watchChanges is what keeps the two control surfaces in sync: the keybind
// script writes this file directly, and the Settings switch follows without any
// IPC between them.
Singleton {
    id: cfg

    property alias enabled: adapter.enabled   // false = touchpad off
    property alias tapToClick: adapter.tapToClick   // false = physical press only

    function save() { view.writeAdapter(); }

    function apply() {
        applyProc.command = [
            Quickshell.env("HOME") + "/.config/hypr/scripts/apply-touchpad.sh"
        ];
        applyProc.running = true;
    }

    function setEnabled(v) { cfg.enabled = v; save(); apply(); }
    function toggle() { cfg.setEnabled(!cfg.enabled); }

    function setTapToClick(v) { cfg.tapToClick = v; save(); apply(); }

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
            // Defaults to off, matching `tap-to-click = false` in
            // hypr/touchpad.lua and the same default in apply-touchpad.sh.
            // Keep the three in step if this ever changes.
            property bool tapToClick: false
        }
    }
}
