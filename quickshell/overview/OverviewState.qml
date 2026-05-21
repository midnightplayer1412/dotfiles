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
    }
    function close() { visible = false; }

    // Slow tick while the overview is open, in case the user repositions
    // windows in another tool (or via keybind) without closing the overview.
    Timer {
        interval: 750
        running: state.visible
        repeat: true
        onTriggered: Hyprland.refreshToplevels()
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
    function focusWorkspace(wsId) {
        _run(["dispatch", "workspace", `${wsId}`]);
    }
}
