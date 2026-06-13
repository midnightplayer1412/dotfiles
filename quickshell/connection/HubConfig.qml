pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Persistent Connection Hub layout, backed by ~/.config/quickshell/hub-config.json.
// Stores one ordered array `tabs` of { key, enabled } — order AND visibility in a
// single list. The hub renders enabledOrdered(); the Settings "Connection Hub"
// pane mutates this and calls save(). Same FileView + JsonAdapter pattern as
// lock/LockConfig.qml and ui/UiStyle.qml.
Singleton {
    id: config

    // The tabs the hub knows how to render, in default order. Adding a new hub
    // tab here makes it appear automatically (appended enabled) even for users
    // whose saved file predates it. See resolvedTabs reconciliation below.
    readonly property var knownKeys: ["wifi", "bluetooth", "audio", "vpn"]
    readonly property var labels: ({
        "wifi": "Wi-Fi",
        "bluetooth": "Bluetooth",
        "audio": "Audio",
        "vpn": "VPN"
    })

    property alias tabs: adapter.tabs

    // Persisted tabs reconciled against knownKeys: drop unknown/legacy keys,
    // append any known key missing from the saved list (enabled). This is what
    // consumers should read.
    readonly property var resolvedTabs: {
        const known = config.knownKeys;
        const out = [];
        const seen = {};
        for (const t of (config.tabs || [])) {
            if (t && known.indexOf(t.key) >= 0 && !seen[t.key]) {
                out.push({ key: t.key, enabled: t.enabled !== false });
                seen[t.key] = true;
            }
        }
        for (const k of known) {
            if (!seen[k]) out.push({ key: k, enabled: true });
        }
        return out;
    }

    // Enabled tabs in display order — the model the hub renders.
    function enabledOrdered() {
        return config.resolvedTabs.filter(t => t.enabled);
    }

    // Set one tab's enabled flag and persist.
    function setEnabled(key, value) {
        const next = config.resolvedTabs.map(t =>
            ({ key: t.key, enabled: t.key === key ? value : t.enabled }));
        config.tabs = next;
        config.save();
    }

    // Reorder tabs to match `keyOrder` (array of keys), preserving each tab's
    // enabled flag, then persist.
    function setOrder(keyOrder) {
        const byKey = {};
        for (const t of config.resolvedTabs) byKey[t.key] = t;
        const next = [];
        for (const k of keyOrder) {
            if (byKey[k]) { next.push({ key: k, enabled: byKey[k].enabled }); delete byKey[k]; }
        }
        // Any leftover (shouldn't happen) appended in resolved order.
        for (const t of config.resolvedTabs) if (byKey[t.key]) next.push({ key: t.key, enabled: t.enabled });
        config.tabs = next;
        config.save();
    }

    function save() { view.writeAdapter(); }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/hub-config.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()   // first run: seed defaults

        JsonAdapter {
            id: adapter
            // Default layout: all four tabs, current hardcoded order, all on.
            property var tabs: [
                { "key": "wifi",      "enabled": true },
                { "key": "bluetooth", "enabled": true },
                { "key": "audio",     "enabled": true },
                { "key": "vpn",       "enabled": true }
            ]
        }
    }
}
