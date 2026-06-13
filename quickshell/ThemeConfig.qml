pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Theme color source, persisted to ~/.config/quickshell/theme-config.json and
// edited from Settings → Appearance. "auto" derives the Material You palette
// from the wallpaper (default); "static" derives it from a fixed seed color.
//
// apply() funnels through hypr/scripts/apply-theme.sh, which runs Matugen and
// rewrites theme/colors.json — Theme.qml watches that file, so the whole shell
// (plus tmux / yazi / hyprlock) recolors live. The current mode/color are
// passed to the script as args to avoid racing the file we just saved.
Singleton {
    id: cfg

    property alias mode: adapter.mode     // "auto" | "static"
    property alias color: adapter.color   // seed hex "#rrggbb"

    // Curated accent seeds for the swatch row (the repo's cyan/green signature
    // first, then a spread across the wheel).
    readonly property var presets: [
        "#33ccff", "#00ff99", "#40c4ff", "#7c4dff",
        "#ff5c8a", "#ff6e40", "#ffd740", "#69f0ae"
    ]

    function save() { view.writeAdapter(); }

    function apply() {
        applyProc.command = [
            Quickshell.env("HOME") + "/.config/hypr/scripts/apply-theme.sh",
            cfg.mode,
            cfg.color
        ];
        applyProc.running = true;
    }

    function setMode(m) {
        cfg.mode = m;
        save();
        apply();
    }

    function setColor(c) {
        cfg.color = c;
        cfg.mode = "static";
        save();
        apply();
    }

    Process { id: applyProc }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/theme-config.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()

        JsonAdapter {
            id: adapter
            property string mode: "auto"
            property string color: "#33ccff"
        }
    }
}
