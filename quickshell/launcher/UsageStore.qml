pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Launch frequency/recency ("frecency") store, persisted to
// ~/.config/quickshell/launcher-usage.json. Maps a DesktopEntry id to
// { count, lastUsed(ms) }. The launcher records a launch and ranks results by
// score(); empty-query "Recent" uses topIds(). FileView + JsonAdapter, same
// pattern as lock/LockConfig.qml and connection/HubConfig.qml.
Singleton {
    id: store

    property alias usage: adapter.usage   // { id: { count, lastUsed } }

    // Bump an app's counter and persist.
    function record(id) {
        if (!id) return;
        const next = Object.assign({}, adapter.usage);
        const cur = next[id] || { count: 0, lastUsed: 0 };
        next[id] = { count: cur.count + 1, lastUsed: Date.now() };
        adapter.usage = next;
        view.writeAdapter();
    }

    // Frecency: raw count plus a recency boost that decays to 0 over ~14 days.
    function score(id) {
        const u = adapter.usage[id];
        if (!u) return 0;
        const ageDays = (Date.now() - (u.lastUsed || 0)) / 86400000;
        const recency = Math.max(0, 1 - ageDays / 14);
        return (u.count || 0) + recency * 5;
    }

    // Ids with any usage, highest score first, capped at n.
    function topIds(n) {
        const ids = Object.keys(adapter.usage);
        ids.sort((a, b) => store.score(b) - store.score(a));
        return ids.slice(0, n);
    }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/launcher-usage.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()   // seed {} on first run

        JsonAdapter {
            id: adapter
            property var usage: ({})
        }
    }
}
