pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: svc

    // ─── Public state (mirrors wallpaper-state.json) ───────────────
    property bool cycleEnabled: true
    property string currentPath: ""
    property int intervalSeconds: 300

    // Picker visibility (used by PickerWindow in later tasks)
    property bool pickerVisible: false
    property var targetScreen: null

    // Internal: suppress persistState() while we're applying values
    // freshly read from disk (otherwise FileView load → property change →
    // persistState → atomic write would cause a needless rewrite).
    property bool _loading: false

    // Set to true after the first scan completes; prevents boot-apply from
    // firing again on subsequent rescans.
    property bool _bootApplied: false

    readonly property string statePath:
        Quickshell.env("HOME") + "/.config/quickshell/wallpaper-state.json"

    // ─── Wallpaper directory scan ──────────────────────────────────
    readonly property string wallpaperDir: "/home/jp/dotfiles/wallpapers"

    // Each entry: { path: string, basename: string, isGif: bool }
    property var wallpapers: []

    Process {
        id: scanProc
        command: ["find", svc.wallpaperDir, "-maxdepth", "1", "-type", "f",
                  "(", "-iname", "*.jpg",
                       "-o", "-iname", "*.jpeg",
                       "-o", "-iname", "*.png",
                       "-o", "-iname", "*.webp",
                       "-o", "-iname", "*.gif",
                  ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of this.text.split("\n")) {
                    if (!line) continue;
                    const slash = line.lastIndexOf("/");
                    const base = slash >= 0 ? line.slice(slash + 1) : line;
                    out.push({
                        path: line,
                        basename: base,
                        isGif: base.toLowerCase().endsWith(".gif")
                    });
                }
                out.sort((a, b) => a.basename.localeCompare(b.basename));
                svc.wallpapers = out;

                // Boot-apply: re-pin currentPath on the FIRST scan after startup,
                // so the last wallpaper survives quickshell restarts and reboots.
                if (!svc._bootApplied) {
                    svc._bootApplied = true;
                    if (svc.currentPath) {
                        const found = out.find(w => w.path === svc.currentPath);
                        if (found) svc.applyWallpaper(svc.currentPath);
                        else console.warn("WallpaperService: currentPath no longer exists:", svc.currentPath);
                    }
                }
            }
        }
    }

    function rescan() {
        if (!scanProc.running) scanProc.running = true;
    }

    // ─── Apply ────────────────────────────────────────────────────
    readonly property string applyScript:
        Quickshell.env("HOME") + "/.config/hypr/scripts/apply-wallpaper.sh"

    // Latest path requested while an apply was in flight. Coalesces rapid
    // clicks: A→B→C while A is still running drops to C, so when A finishes
    // we jump straight to C (skipping B). awww img on a large GIF can take
    // 30–60 seconds, so dropping clicks during that window felt broken.
    property string _pendingApply: ""

    Process {
        id: applyProc
        command: ["true"]
        onExited: (code) => {
            if (code !== 0) {
                console.warn("WallpaperService: apply-wallpaper.sh exited with", code);
            }
            if (svc._pendingApply) {
                const next = svc._pendingApply;
                svc._pendingApply = "";
                svc.applyWallpaper(next);
            }
        }
    }

    function applyWallpaper(path) {
        if (!path) return;
        if (applyProc.running) {
            // Defer: latest queued path wins.
            svc._pendingApply = path;
            svc.currentPath = path;             // optimistic update so the
                                                // picker's selection ring
                                                // tracks the latest pick.
            return;
        }
        svc._pendingApply = "";
        applyProc.command = [svc.applyScript, path];
        applyProc.running = true;
        svc.currentPath = path;
    }

    function pinWallpaper(path) {
        svc.cycleEnabled = false;
        svc.applyWallpaper(path);
    }

    // ─── Cycle Timer ──────────────────────────────────────────────
    function _pickRandom() {
        if (svc.wallpapers.length === 0) return null;
        const i = Math.floor(Math.random() * svc.wallpapers.length);
        return svc.wallpapers[i].path;
    }

    Timer {
        id: cycleTimer
        interval: svc.intervalSeconds * 1000
        running: svc.cycleEnabled && svc.wallpapers.length > 0
        repeat: true
        onTriggered: {
            const next = svc._pickRandom();
            if (next) svc.applyWallpaper(next);
        }
    }

    Component.onCompleted: svc.rescan()

    // ─── Read ──────────────────────────────────────────────────────
    FileView {
        id: stateFile
        path: svc.statePath
        watchChanges: true
        preload: true

        onFileChanged: stateFile.reload()
        onLoaded: svc._loadFromText(stateFile.text())
    }

    function _loadFromText(text) {
        svc._loading = true;
        let obj;
        try {
            obj = JSON.parse(text);
        } catch (e) {
            console.warn("WallpaperService: cannot parse state.json, keeping declared defaults");
            svc._loading = false;
            return;
        }

        svc.cycleEnabled    = (typeof obj.cycle === "boolean") ? obj.cycle : true;
        svc.currentPath     = (typeof obj.current === "string") ? obj.current : "";
        svc.intervalSeconds = (typeof obj.intervalSeconds === "number" && obj.intervalSeconds > 0)
                              ? obj.intervalSeconds : 300;
        svc._loading = false;
    }

    // ─── Write (atomic via tmp + mv) ───────────────────────────────
    property bool _pendingWrite: false

    Process {
        id: writeProc
        command: ["true"]   // placeholder; real command assigned per-write in _doWrite
        onExited: {
            if (svc._pendingWrite) svc._doWrite();
        }
    }

    function persistState() {
        if (svc._loading) return;
        if (writeProc.running) { svc._pendingWrite = true; return; }
        svc._doWrite();
    }

    function _doWrite() {
        svc._pendingWrite = false;
        const json = JSON.stringify({
            cycle: svc.cycleEnabled,
            current: svc.currentPath,
            intervalSeconds: svc.intervalSeconds
        }, null, 2);
        writeProc.command = [
            "sh", "-c",
            'printf "%s" "$1" > "$2.tmp" && mv "$2.tmp" "$2"',
            "_",
            json,
            svc.statePath
        ];
        writeProc.running = true;
    }

    onCycleEnabledChanged: persistState()
    onCurrentPathChanged:  persistState()
    onIntervalSecondsChanged: persistState()

    // ─── IPC handler ──────────────────────────────────────────────
    IpcHandler {
        target: "wallpaper"
        function toggle() {
            // Pick the currently-focused screen so the picker pops where the user is.
            const monitorName = Hyprland.focusedMonitor?.name ?? "";
            for (const s of Quickshell.screens) {
                if (s.name === monitorName) { svc.togglePicker(s); return; }
            }
            svc.togglePicker(Quickshell.screens[0]);
        }
    }

    // ─── Public setters (used by picker in later tasks) ────────────
    function setCycle(enabled) { svc.cycleEnabled = enabled; }
    function setInterval(seconds) { svc.intervalSeconds = seconds; }

    function togglePicker(screen) {
        if (svc.pickerVisible && svc.targetScreen === screen) {
            svc.pickerVisible = false;
        } else {
            svc.targetScreen = screen;
            svc.pickerVisible = true;
            svc.rescan();   // pick up wallpapers added at runtime
        }
    }
}
