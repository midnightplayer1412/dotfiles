pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Persistent bar settings, backed by ~/.config/quickshell/bar-config.json.
//
// Layout is data-driven: `layout` holds three ordered arrays of widget keys
// (start / center / end). A widget's zone AND order are its position in a list;
// a widget absent from all three lists is hidden. This mirrors connection/
// HubConfig.qml's reconcilable-list pattern, generalized to three zones.
Singleton {
    id: config

    // Screen edge: "left" | "right" | "top" | "bottom".
    property alias position: adapter.position
    readonly property bool horizontal: position === "top" || position === "bottom"

    // Appearance.
    property alias thickness: adapter.thickness     // bar cross-axis size (px)
    property alias bgOpacity: adapter.bgOpacity     // 0..1 background alpha
    property alias radius: adapter.radius           // corner radius (px)
    property alias endPadding: adapter.endPadding   // inner inset at the bar's two ends along its length (px)

    // Ordered widget lists per zone.
    property alias layout: adapter.layout

    // Every widget the bar knows how to render, in default order. Adding a key
    // here (plus a case in BarZone's registry) makes it available everywhere.
    readonly property var knownKeys: ["workspaces", "clock", "battery", "tray", "volume", "network", "resources", "media", "window"]
    readonly property var labels: ({
        "workspaces": "Workspaces",
        "clock":      "Clock",
        "battery":    "Battery",
        "tray":       "System Tray",
        "volume":     "Volume",
        "network":    "Network",
        "resources":  "Resources",
        "media":      "Media",
        "window":     "App Name"
    })

    // Reconcile the saved layout against knownKeys: keep only known keys, drop
    // duplicates (first zone wins), so a stale/edited file can't double-place or
    // surface an unknown widget. New known keys land in `hidden` until placed.
    readonly property var resolved: {
        const lay = config.layout || {};
        const used = ({});
        const pick = (zoneKeys) => {
            const out = [];
            for (const k of (zoneKeys || [])) {
                if (config.knownKeys.indexOf(k) >= 0 && !used[k]) { used[k] = true; out.push(k); }
            }
            return out;
        };
        return ({ start: pick(lay.start), center: pick(lay.center), end: pick(lay.end) });
    }

    // Known widgets not placed in any zone.
    readonly property var hidden: {
        const r = config.resolved;
        const placed = ({});
        for (const z of ["start", "center", "end"]) for (const k of r[z]) placed[k] = true;
        return config.knownKeys.filter((k) => !placed[k]);
    }

    // The zone a key currently lives in, or "hidden".
    function zoneOf(key) {
        const r = config.resolved;
        for (const z of ["start", "center", "end"]) if (r[z].indexOf(key) >= 0) return z;
        return "hidden";
    }

    // Known-good baseline — the classic left bar. Must mirror the JsonAdapter
    // defaults below; resetDefaults() restores it so a bad fine-tune is one
    // click away from working again.
    readonly property var defaults: ({
        position: "left",
        thickness: 48,
        bgOpacity: 1.0,
        radius: 12,
        endPadding: 4,
        layout: ({ start: ["workspaces"], center: ["clock"], end: ["battery"] })
    })

    function resetDefaults() {
        adapter.position = config.defaults.position;
        adapter.thickness = config.defaults.thickness;
        adapter.bgOpacity = config.defaults.bgOpacity;
        adapter.radius = config.defaults.radius;
        adapter.endPadding = config.defaults.endPadding;
        adapter.layout = JSON.parse(JSON.stringify(config.defaults.layout));   // deep copy
        config.save();
    }

    function save() { view.writeAdapter(); }

    // Commit a whole layout object (settings pane builds it from drag/drop).
    function setLayout(obj) { adapter.layout = obj; save(); }

    // Move `key` to `zone` ("start"|"center"|"end"|"hidden"), appended at end.
    // Rebuilds from `resolved` so the write is always clean.
    function setZone(key, zone) {
        const r = config.resolved;
        const next = ({ start: [], center: [], end: [] });
        for (const z of ["start", "center", "end"])
            next[z] = r[z].filter((k) => k !== key);
        if (zone !== "hidden") next[zone].push(key);
        config.setLayout(next);
    }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/bar-config.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()

        JsonAdapter {
            id: adapter
            property string position: "left"
            property int thickness: 48
            property real bgOpacity: 1.0
            property int radius: 12
            property int endPadding: 4
            property var layout: ({ start: ["workspaces"], center: ["clock"], end: ["battery"] })
        }
    }
}
