pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Launcher preferences, persisted to ~/.config/quickshell/launcher-config.json.
// Edited from the Settings → Launcher tab. Same FileView + JsonAdapter pattern as
// the other *Config singletons.
Singleton {
    id: config

    property alias position: adapter.position             // "bottom" | "center"
    property alias recentsLayout: adapter.recentsLayout   // "rows" | "chips"
    property alias searchEngine: adapter.searchEngine     // engine key (see engines)

    // Web-search engines for the launcher's no-match fallback. {q} is the query.
    readonly property var engines: [
        { key: "google",     label: "Google",       url: "https://www.google.com/search?q=" },
        { key: "duckduckgo", label: "DuckDuckGo",   url: "https://duckduckgo.com/?q=" },
        { key: "bing",       label: "Bing",         url: "https://www.bing.com/search?q=" },
        { key: "brave",      label: "Brave Search", url: "https://search.brave.com/search?q=" }
    ]
    function _engine() {
        return config.engines.find(e => e.key === config.searchEngine) || config.engines[0];
    }
    function engineUrl()   { return config._engine().url; }
    function engineLabel() { return config._engine().label; }

    function save() { view.writeAdapter(); }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/launcher-config.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()

        JsonAdapter {
            id: adapter
            property string position: "bottom"
            property string recentsLayout: "rows"
            property string searchEngine: "google"
        }
    }
}
