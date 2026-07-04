pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Persistent widget layout, backed by ~/.config/quickshell/widgets-config.json.
// Positions are NOT stored per widget — the desktop stores vertical "stacks"
// (ordered id lists anchored to a corner); on-screen y is computed flush by the
// host, so reorder/hide/swap never leave gaps.
Singleton {
    id: config

    // Weather needs coordinates (open-meteo). 0/0 => "set location in Settings".
    property alias weatherLat: adapter.weatherLat
    property alias weatherLon: adapter.weatherLon
    property alias weatherLabel: adapter.weatherLabel

    // ---- Defaults derived from the registry ----
    readonly property var defaultDesktop: {
        const byStack = ({});
        for (const id of WidgetRegistry.ids) {
            const d = WidgetRegistry.descriptors[id].desktop;
            (byStack[d.stack] = byStack[d.stack] || []).push({ id: id, order: d.order });
        }
        const mk = (key, anchor) => ({
            id: key, anchor: anchor, dx: 40, dy: 40,
            widgets: (byStack[key] || []).sort((a, b) => a.order - b.order).map(e => e.id)
        });
        const stacks = [];
        if (byStack["left"])  stacks.push(mk("left",  "top-left"));
        if (byStack["right"]) stacks.push(mk("right", "top-right"));
        const enabled = ({});
        for (const id of WidgetRegistry.ids) enabled[id] = true;
        return { stacks: stacks, enabled: enabled };
    }

    readonly property var defaultDashboard: {
        const enabled = ({});
        for (const id of WidgetRegistry.ids) enabled[id] = true;
        return { order: WidgetRegistry.ids.slice(), enabled: enabled };
    }

    // ---- Resolved: saved reconciled against the registry ----
    readonly property var resolvedDesktop: {
        const saved = adapter.desktop || {};
        const known = WidgetRegistry.ids;
        const savedStacks = (saved.stacks && saved.stacks.length) ? saved.stacks : defaultDesktop.stacks;
        const seen = ({});
        const stacks = [];
        for (const s of savedStacks) {
            const widgets = (s.widgets || []).filter(id => known.indexOf(id) >= 0 && !seen[id]);
            for (const id of widgets) seen[id] = true;
            stacks.push({ id: s.id, anchor: s.anchor || "top-left",
                          dx: s.dx === undefined ? 40 : s.dx,
                          dy: s.dy === undefined ? 40 : s.dy, widgets: widgets });
        }
        for (const id of known) {
            if (seen[id]) continue;
            const defStack = WidgetRegistry.descriptors[id].desktop.stack;
            let t = stacks.find(s => s.id === defStack);
            if (!t) { t = { id: defStack, anchor: defStack === "right" ? "top-right" : "top-left", dx: 40, dy: 40, widgets: [] }; stacks.push(t); }
            t.widgets.push(id); seen[id] = true;
        }
        const enabled = ({});
        for (const id of known) enabled[id] = (saved.enabled && saved.enabled[id] !== undefined) ? saved.enabled[id] : true;
        return { stacks: stacks.filter(s => s.widgets.length > 0), enabled: enabled };
    }

    readonly property var resolvedDashboard: {
        const saved = adapter.dashboard || {};
        const known = WidgetRegistry.ids;
        const order = (saved.order || known).filter(id => known.indexOf(id) >= 0);
        for (const id of known) if (order.indexOf(id) < 0) order.push(id);
        const enabled = ({});
        for (const id of known) enabled[id] = (saved.enabled && saved.enabled[id] !== undefined) ? saved.enabled[id] : true;
        return { order: order, enabled: enabled };
    }

    // ---- Mutators ----
    function _cloneDesktop() {
        const r = resolvedDesktop;
        return { stacks: r.stacks.map(s => ({ id: s.id, anchor: s.anchor, dx: s.dx, dy: s.dy, widgets: s.widgets.slice() })),
                 enabled: Object.assign({}, r.enabled) };
    }
    function _writeDesktop(o) { adapter.desktop = o; save(); }
    function _writeDashboard(o) { adapter.dashboard = o; save(); }

    function toggleDesktop(id) { const d = _cloneDesktop(); d.enabled[id] = !d.enabled[id]; _writeDesktop(d); }

    function toggleDashboard(id) {
        const r = resolvedDashboard; const e = Object.assign({}, r.enabled);
        e[id] = !e[id]; _writeDashboard({ order: r.order.slice(), enabled: e });
    }

    function setDashboardOrder(order) {
        const r = resolvedDashboard;
        _writeDashboard({ order: order.slice(), enabled: Object.assign({}, r.enabled) });
    }

    // Move id into targetStackId at index; "" => detach to a new free stack at (dx,dy).
    function moveWidget(id, targetStackId, index, dx, dy) {
        const d = _cloneDesktop();
        for (const s of d.stacks) { const i = s.widgets.indexOf(id); if (i >= 0) s.widgets.splice(i, 1); }
        if (targetStackId === "") {
            d.stacks.push({ id: "free-" + id, anchor: "top-left", dx: dx, dy: dy, widgets: [id] });
        } else {
            const t = d.stacks.find(s => s.id === targetStackId);
            if (t) t.widgets.splice(index, 0, id);
            else d.stacks.push({ id: targetStackId, anchor: "top-left", dx: dx, dy: dy, widgets: [id] });
        }
        d.stacks = d.stacks.filter(s => s.widgets.length > 0);
        _writeDesktop(d);
    }

    // Swap two widgets' slots (same or different stacks) — the gapless reorder.
    function swap(a, b) {
        const d = _cloneDesktop(); let pa = null, pb = null;
        for (const s of d.stacks) {
            const ia = s.widgets.indexOf(a); if (ia >= 0) pa = { s: s, i: ia };
            const ib = s.widgets.indexOf(b); if (ib >= 0) pb = { s: s, i: ib };
        }
        if (pa && pb) { pa.s.widgets[pa.i] = b; pb.s.widgets[pb.i] = a; _writeDesktop(d); }
    }

    // ---- Per-widget settings ----
    // Resolve a widget's settings against its descriptor schema: saved value or
    // the field default. Weather falls back to the legacy top-level
    // weatherLat/Lon/Label aliases when its per-widget keys aren't set yet, so an
    // existing config keeps its coordinates with no migration step.
    function resolvedSettings(id) {
        const schema = WidgetRegistry.descriptors[id].settings || [];
        const saved = (adapter.settings && adapter.settings[id]) || {};
        const out = ({});
        for (const f of schema)
            out[f.key] = (saved[f.key] !== undefined) ? saved[f.key] : f.default;
        if (id === "weather") {
            if (saved.lat === undefined && adapter.weatherLat !== 0) out.lat = adapter.weatherLat;
            if (saved.lon === undefined && adapter.weatherLon !== 0) out.lon = adapter.weatherLon;
            if (saved.label === undefined && adapter.weatherLabel) out.label = adapter.weatherLabel;
        }
        return out;
    }

    function setting(id, key) { return resolvedSettings(id)[key]; }

    function setSetting(id, key, value) {
        const all = Object.assign({}, adapter.settings || {});
        const one = Object.assign({}, all[id] || {});
        one[key] = value;
        all[id] = one;
        adapter.settings = all;
        save();
    }

    function restoreDefaults() {
        adapter.desktop = JSON.parse(JSON.stringify(defaultDesktop));
        adapter.dashboard = JSON.parse(JSON.stringify(defaultDashboard));
        adapter.settings = ({});
        save();
    }

    function save() { view.writeAdapter(); }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/widgets-config.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()
        JsonAdapter {
            id: adapter
            property var desktop: ({})
            property var dashboard: ({})
            property var settings: ({})
            // Legacy weather location (pre per-widget-settings). Kept so old
            // configs still parse and migrate via resolvedSettings("weather").
            property real weatherLat: 0
            property real weatherLon: 0
            property string weatherLabel: ""
        }
    }
}
