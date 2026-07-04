pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: state

    // ── Panel visibility ─────────────────────────────────────────────
    property bool visible: false
    property var targetScreen: null

    function toggle(screen) {
        if (visible && targetScreen === screen) { close(); return; }
        open(screen);
    }
    function open(screen) {
        targetScreen = screen;
        visible = true;
        // Hyprland doesn't push position-changed events over live IPC, so
        // refresh once on open to pick up any moves done outside the overview.
        Hyprland.refreshToplevels();
        // Start sticky-mode selection on the focused window so HJKL has an anchor.
        navZone = "windows";
        navWs = -1;
        seedKeyboardSelection();
    }
    function close() {
        visible = false;
        armed = false;
        keyboardSelectedAddress = "";
        navZone = "windows";
        navWs = -1;
        clearTileGeometry();
        clearSpaceGeometry();
    }

    // Slow tick while the overview is open, in case the user repositions
    // windows in another tool (or via keybind) without closing the overview.
    Timer {
        interval: 750
        running: state.visible
        repeat: true
        onTriggered: Hyprland.refreshToplevels()
    }

    // ── Alt-Tab (armed) mode ─────────────────────────────────────────
    // Opened via Super+Alt+Tab. Unlike the sticky Super+Tab overview, this
    // commits on modifier release: a highlight walks the windows in MRU order
    // and the highlighted window is focused when the Hyprland submap exits.
    property bool armed: false
    property int highlightIndex: 0

    // All windows sorted by Hyprland's focusHistoryID (0 = current focus,
    // 1 = previous, …) so Tab walks most-recently-used order like real Alt-Tab.
    readonly property var cycleOrder: {
        const arr = toplevels.slice();
        arr.sort((a, b) => (a?.lastIpcObject?.focusHistoryID ?? 9999)
                         - (b?.lastIpcObject?.focusHistoryID ?? 9999));
        return arr;
    }

    readonly property var highlightedWindow:
        (armed && highlightIndex >= 0 && highlightIndex < cycleOrder.length)
            ? cycleOrder[highlightIndex] : null

    // First Super+Alt+Tab opens armed on the PREVIOUS window (focusHistoryID 1),
    // so a quick press+release flips to the last-used window. Further Tabs walk on.
    function openArmed(screen) {
        targetScreen = screen;
        armed = true;
        visible = true;
        Hyprland.refreshToplevels();
        highlightIndex = cycleOrder.length > 1 ? 1 : 0;
    }

    // dir: +1 = Tab (next), -1 = Shift+Tab (prev). Opens armed if not yet armed.
    function altTabStep(screen, dir) {
        if (!armed) { openArmed(screen); return; }
        const n = cycleOrder.length;
        if (n === 0) return;
        highlightIndex = (highlightIndex + dir + n) % n;
    }

    function altTabCommit() {
        const w = highlightedWindow;
        const addr = w?.address ? _addr(w.address) : "";
        // Commit is driven from QML (Super-release) while the Hyprland submap is
        // still active, so leave the submap AND focus the target in one batch
        // (two separate _run calls would clobber the shared Process).
        if (addr)
            _run(["--batch", `dispatch focuswindow address:${addr} ; dispatch submap reset`]);
        else
            _run(["dispatch", "submap", "reset"]);
        close();
    }

    function altTabCancel() {
        _run(["dispatch", "submap", "reset"]);  // no-op if not in a submap
        close();
    }

    // Close the highlighted window in place and keep cycling. Clamp the index
    // so it stays valid once the killed window drops out of cycleOrder.
    function altTabCloseHighlighted() {
        const w = highlightedWindow;
        if (!w?.address) return;
        killWindow(w.address);
        if (highlightIndex >= cycleOrder.length - 1)
            highlightIndex = Math.max(0, cycleOrder.length - 2);
        refreshTimer.restart();
    }

    // ── Sticky-mode keyboard selection (Super+Tab overview) ──────────
    // Geometric HJKL navigation, independent of the armed alt-tab above.
    // The highlight is driven by address (not an index) because the selection
    // jumps spatially across workspace cells rather than walking a list.
    property string keyboardSelectedAddress: ""

    // address (0x-normalized) -> { cx, cy } tile centers in OverviewWidget root
    // coords. Populated by each rendered tile (OverviewWidget.registerTile) and
    // cleared on close(). Read imperatively by selectStep at keypress time.
    property var tileGeometry: ({})

    readonly property var keyboardSelectedWindow:
        keyboardSelectedAddress
            ? (toplevels.find(t => _addr(t.address ?? "") === keyboardSelectedAddress) ?? null)
            : null

    // How strongly HJKL prefers an in-line window over a diagonal one.
    // score = along-axis distance + selectPerpWeight * perpendicular distance.
    readonly property real selectPerpWeight: 2

    // ── Two-tier nav (Mission Control: Spaces bar ⇄ windows) ─────────────
    // The sticky selection lives in one of two zones: the center windows
    // (default) or the top Spaces bar. K hops up into the bar, J drops back.
    // Inert for every other layout — they never call registerSpace(), so
    // spaceGeometry stays empty and _hasSpaces() is false.
    property string navZone: "windows"       // "windows" | "spaces"
    property int    navWs: -1                 // selected workspace id in "spaces"
    property var spaceGeometry: ({})          // wsId -> { cx, cy } in layout coords
    function registerSpace(wsId, cx, cy) { spaceGeometry[wsId] = { cx: cx, cy: cy }; }
    function clearSpaceGeometry() { spaceGeometry = ({}); }
    function _hasSpaces() { for (const k in spaceGeometry) return true; return false; }

    function registerTile(address, cx, cy) {
        if (!address) return;
        tileGeometry[_addr(address)] = { cx: cx, cy: cy };
    }

    function clearTileGeometry() { tileGeometry = ({}); }

    // Seed the selection on the currently-focused window (focusHistoryID 0).
    function seedKeyboardSelection() {
        const focused = toplevels.find(
            t => (t?.lastIpcObject?.focusHistoryID ?? -1) === 0);
        keyboardSelectedAddress = focused?.address ? _addr(focused.address) : "";
    }

    // dir: "h" left, "l" right, "k" up, "j" down. Move the selection to the
    // nearest registered window whose center lies in that direction. No-op if
    // there is none. Falls back to any registered tile if the current
    // selection's geometry isn't known yet (tiles register just after open).
    function selectStep(dir) {
        // ── Spaces zone (Mission Control top bar) ──
        if (navZone === "spaces") {
            if (dir === "h" || dir === "l") { _stepSpace(dir); return; }
            if (dir === "j") { _spacesToWindows(); return; }
            return;   // "k" — already at the top
        }

        // ── Windows zone (geometric; all layouts) ──
        const geom = tileGeometry;
        const cur = geom[keyboardSelectedAddress];
        if (!cur) {
            for (const a in geom) { keyboardSelectedAddress = a; return; }
            if (dir === "k" && _hasSpaces()) _windowsToSpaces(null);
            return;
        }
        const eps = 1;
        let best = "";
        let bestScore = Infinity;
        for (const a in geom) {
            if (a === keyboardSelectedAddress) continue;
            const dx = geom[a].cx - cur.cx;
            const dy = geom[a].cy - cur.cy;
            let along, perp;
            if (dir === "l")      { if (dx <= eps)  continue; along = dx;  perp = Math.abs(dy); }
            else if (dir === "h") { if (dx >= -eps) continue; along = -dx; perp = Math.abs(dy); }
            else if (dir === "j") { if (dy <= eps)  continue; along = dy;  perp = Math.abs(dx); }
            else if (dir === "k") { if (dy >= -eps) continue; along = -dy; perp = Math.abs(dx); }
            else continue;
            const score = along + selectPerpWeight * perp;
            if (score < bestScore) { bestScore = score; best = a; }
        }
        if (best) { keyboardSelectedAddress = best; return; }
        // Nothing that way. Going up with a Spaces bar present → hop into it.
        if (dir === "k" && _hasSpaces()) _windowsToSpaces(cur.cx);
    }

    // Enter the Spaces bar, selecting the space nearest horizontally to fromCx
    // (or the first space when fromCx is null).
    function _windowsToSpaces(fromCx) {
        let best = -1, bestD = Infinity;
        for (const id in spaceGeometry) {
            const d = fromCx === null ? 0 : Math.abs(spaceGeometry[id].cx - fromCx);
            if (d < bestD) { bestD = d; best = parseInt(id); }
        }
        if (best >= 0) { navWs = best; navZone = "spaces"; }
    }

    // Walk the Spaces bar left ("h") / right ("l"), ordered by screen x.
    function _stepSpace(dir) {
        const ids = Object.keys(spaceGeometry).map(k => parseInt(k))
            .sort((a, b) => spaceGeometry[a].cx - spaceGeometry[b].cx);
        if (ids.length === 0) return;
        const i = ids.indexOf(navWs);
        if (i < 0) { navWs = ids[0]; return; }
        navWs = dir === "l" ? ids[Math.min(ids.length - 1, i + 1)]
                            : ids[Math.max(0, i - 1)];
    }

    // Drop from the Spaces bar back to the window nearest the current space.
    function _spacesToWindows() {
        const sp = spaceGeometry[navWs];
        navZone = "windows";
        if (!sp) return;
        let best = "", bestD = Infinity;
        for (const a in tileGeometry) {
            const d = Math.abs(tileGeometry[a].cx - sp.cx);
            if (d < bestD) { bestD = d; best = a; }
        }
        if (best) keyboardSelectedAddress = best;
    }

    function selectCommit() {
        if (navZone === "spaces") {
            if (navWs >= 0) focusWorkspace(navWs);
            close();
            return;
        }
        if (keyboardSelectedAddress) focusWindow(keyboardSelectedAddress);
        close();
    }

    // ── Grid layout ──────────────────────────────────────────────────
    readonly property int rows: 2
    readonly property int columns: 5
    readonly property int workspacesShown: rows * columns

    // ── Hyprland data sources ────────────────────────────────────────
    // Hyprland.workspaces/toplevels are ObjectModels; .values is the JS array.
    readonly property var workspaces: Hyprland.workspaces.values
    readonly property var toplevels: Hyprland.toplevels.values

    // Workspace cells the grid renders. Defaults to ids 1..workspacesShown.
    // Future: could shift by "workspace group" like end-4 does for >10 wss.
    readonly property var workspaceIds: {
        const out = [];
        for (let i = 1; i <= workspacesShown; i++) out.push(i);
        return out;
    }

    function windowsForWorkspace(wsId) {
        return toplevels.filter(t => t.workspace && t.workspace.id === wsId);
    }

    // ── Dispatchers ──────────────────────────────────────────────────
    // Hyprland requires the 0x-prefixed address in its window selector; Quickshell
    // sometimes exposes the address without it, so normalize defensively.
    function _addr(a) { return a.startsWith("0x") ? a : "0x" + a; }

    // Shell out to hyprctl. Hyprland.dispatch() via IPC silently no-ops for
    // commands with comma-separated args (verified empirically: log shows the
    // dispatch fires but the window doesn't move), so use the CLI as a workaround.
    Process { id: hyprctlProc }

    function _run(args) {
        hyprctlProc.command = ["hyprctl"].concat(args);
        hyprctlProc.running = true;
    }

    // After movetoworkspacesilent across monitors, Hyprland repositions the
    // window but doesn't push a position-changed event to live IPC listeners
    // (it does on a kill+reload re-read). Pull a fresh snapshot ourselves
    // shortly after the dispatch so tile geometry updates without restarting.
    Timer {
        id: refreshTimer
        interval: 80
        onTriggered: Hyprland.refreshToplevels()
    }

    function moveWindow(address, wsId) {
        _run(["dispatch", "movetoworkspacesilent", `${wsId},address:${_addr(address)}`]);
        refreshTimer.restart();
    }
    function focusWindow(address) {
        _run(["dispatch", "focuswindow", `address:${_addr(address)}`]);
    }
    function killWindow(address) {
        _run(["dispatch", "killwindow", `address:${_addr(address)}`]);
    }
    function focusWorkspace(wsId) {
        _run(["dispatch", "workspace", `${wsId}`]);
    }
}
