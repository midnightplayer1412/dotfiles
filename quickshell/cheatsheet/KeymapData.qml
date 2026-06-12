pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Loads every per-app keymap from cheatsheet/keymaps/*.json into `apps`.
// Each file is a JSON object { app, id, binds: [...] }; a small shell pipeline
// concatenates them into one JSON array so a new file = a new tab, no code
// change. Glob order is alphabetical, so hyprland.json lands first.
Singleton {
    id: data

    // [{ app: string, id: string, binds: [{key, mods, category, desc}] }, ...]
    property var apps: []

    readonly property string keymapDir: Quickshell.shellDir + "/cheatsheet/keymaps"

    function bindsFor(id) {
        for (const a of apps)
            if (a.id === id) return a.binds || [];
        return [];
    }

    // All binds in the active app whose key matches `sym` (case-insensitive).
    function bindsForKey(id, sym) {
        const up = (sym || "").toUpperCase();
        return bindsFor(id).filter(b => (b.key || "").toUpperCase() === up);
    }

    // Whether any bind in the active app uses modifier `mod`.
    function modActive(id, mod) {
        const up = mod.toUpperCase();
        return bindsFor(id).some(b => (b.mods || []).some(m => m.toUpperCase() === up));
    }

    Process {
        id: loadProc
        running: true
        command: ["sh", "-c",
            "cd '" + data.keymapDir + "' 2>/dev/null && first=1; printf '['; " +
            "for f in *.json; do [ -f \"$f\" ] || continue; " +
            "[ \"$first\" = 1 ] || printf ','; cat \"$f\"; first=0; done; printf ']'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    data.apps = JSON.parse(this.text);
                } catch (e) {
                    console.warn("KeymapData: could not parse keymaps:", e);
                    data.apps = [];
                }
            }
        }
    }
}
