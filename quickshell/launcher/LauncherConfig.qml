pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Launcher preferences, persisted to ~/.config/quickshell/launcher-config.json.
// Edited from the Settings → Launcher tab. Same FileView + JsonAdapter pattern as
// the other *Config singletons.
Singleton {
    id: config

    property alias layout: adapter.layout                 // "bar" | "spotlight" | "sidebar" | "grid"
    property alias position: adapter.position             // "bottom" | "center"  (bar only)
    property alias sidebarEdge: adapter.sidebarEdge       // "left" | "right"     (sidebar only)
    property alias spotlightSize: adapter.spotlightSize   // "small" | "medium" | "large"
    property alias sidebarWidth: adapter.sidebarWidth     // "narrow" | "medium" | "wide"
    property alias gridColumns: adapter.gridColumns       // 5 | 6 | 7 | 8
    property alias gridIconSize: adapter.gridIconSize     // "small" | "medium" | "large"
    property alias gridLabels: adapter.gridLabels         // show app names under grid icons
    property alias recentsLayout: adapter.recentsLayout   // "rows" | "chips"     (list layouts)
    property alias maxRecents: adapter.maxRecents         // # of recent apps shown (1–10)
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
            property string layout: "bar"
            property string position: "bottom"
            property string sidebarEdge: "left"
            property string spotlightSize: "medium"
            property string sidebarWidth: "medium"
            property int gridColumns: 6
            property string gridIconSize: "medium"
            property bool gridLabels: true
            property string recentsLayout: "rows"
            property int maxRecents: 5
            property string searchEngine: "google"
        }
    }
}
