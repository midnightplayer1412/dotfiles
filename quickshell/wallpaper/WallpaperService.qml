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
    property string cycleOrder: "random"   // "random" | "sequential"

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

    // Cached small-JPG thumbnails live here (see gen-wallpaper-thumbs.sh).
    // Thumbs are named "<basename>.jpg" so the path is predictable without
    // hashing — basenames are unique within the flat wallpaper dir.
    readonly property string thumbDir:
        Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-thumbs"

    // Bumped whenever thumbnail generation finishes, so thumbnails that fell
    // back to the (slow) original while their thumb didn't exist yet retry.
    property int thumbRev: 0

    // Each entry: { path: string, basename: string, isGif: bool, thumb: string }
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
                        isGif: base.toLowerCase().endsWith(".gif"),
                        thumb: svc.thumbDir + "/" + base + ".jpg"
                    });
                }
                // Numeric-aware sort so "9.jpg" < "57.jpg" < "100.jpg"
                // instead of lexical order ("100" before "57").
                out.sort((a, b) => a.basename.localeCompare(b.basename, undefined, { numeric: true }));
                svc.wallpapers = out;

                // Drop queued picks whose files no longer exist, then top up.
                svc._queue = svc._queue.filter(p => out.some(w => w.path === p));
                svc._refillQueue();

                // Refresh the on-disk thumbnail cache (incremental — only
                // missing/stale thumbs are regenerated). Runs in the
                // background; thumbRev bumps when it finishes so the grid
                // retries any cells that fell back to the original.
                svc.generateThumbs();

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

    // ─── Thumbnail cache generation ────────────────────────────────
    readonly property string thumbScript:
        Quickshell.env("HOME") + "/.config/hypr/scripts/gen-wallpaper-thumbs.sh"

    Process {
        id: thumbProc
        command: ["true"]
        onExited: (code) => {
            if (code !== 0)
                console.warn("WallpaperService: gen-wallpaper-thumbs.sh exited with", code);
            svc.thumbRev += 1;   // tell delegates their thumbs may now exist
        }
    }

    function generateThumbs() {
        if (thumbProc.running) return;
        thumbProc.command = [svc.thumbScript, svc.wallpaperDir, svc.thumbDir];
        thumbProc.running = true;
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

    // ─── Lookahead queue ──────────────────────────────────────────
    // The cycle used to pick at tick time, which made prefetching impossible:
    // the next wallpaper didn't exist until the moment it was needed. We now
    // commit to the next N picks so the prefetch worker can warm them.
    // Depth 4 gives ~180s of lead at a 60s interval; the largest GIF needs
    // ~300s to decode, so a worst-case run of consecutive large GIFs still
    // degrades to a stall — the old behaviour, never anything worse.
    readonly property int _queueDepth: 4
    property var _queue: []

    function _refillQueue() {
        const q = svc._queue.slice();
        let guard = 0;
        while (q.length < svc._queueDepth && guard < 200) {
            guard += 1;
            const pick = svc.cycleOrder === "sequential"
                ? svc._pickSequentialAfter(q.length > 0 ? q[q.length - 1] : svc.currentPath)
                : svc._pickRandom();
            if (!pick) break;
            // Avoid duplicates within the queue; with few wallpapers this can
            // legitimately fail, hence the guard.
            if (q.indexOf(pick) === -1) q.push(pick);
        }
        svc._queue = q;
    }

    // Sequential successor of an arbitrary path (not just currentPath), so the
    // queue can be built several steps ahead.
    function _pickSequentialAfter(path) {
        const n = svc.wallpapers.length;
        if (n === 0) return null;
        const idx = svc.wallpapers.findIndex(w => w.path === path);
        return svc.wallpapers[(idx < 0 ? 0 : (idx + 1) % n)].path;
    }

    function _pickRandom() {
        const n = svc.wallpapers.length;
        if (n === 0) return null;
        if (n === 1) return svc.wallpapers[0].path;
        let i;
        do { i = Math.floor(Math.random() * n); }
        while (svc.wallpapers[i].path === svc.currentPath);
        return svc.wallpapers[i].path;
    }

    function _pickSequential() {
        return svc._pickSequentialAfter(svc.currentPath);
    }

    // Take the head of the queue, refill behind it.
    function _takeNext() {
        if (svc._queue.length === 0) svc._refillQueue();
        const q = svc._queue.slice();
        const next = q.shift();
        svc._queue = q;
        svc._refillQueue();
        return next ?? null;
    }

    // Shuffle now pops the QUEUE HEAD rather than picking fresh at random.
    // The head is already warm, so shuffle is instant instead of a guaranteed
    // 30-60s stall. Deliberate behaviour change.
    function shuffleNow() {
        const next = svc._takeNext();
        if (next) svc.applyWallpaper(next);
    }

    Timer {
        id: cycleTimer
        interval: svc.intervalSeconds * 1000
        running: svc.cycleEnabled && svc.wallpapers.length > 0
        repeat: true
        onTriggered: {
            const next = svc._takeNext();
            if (next) svc.applyWallpaper(next);
        }
    }

    Component.onCompleted: {
        console.log("BUILD: wallpaper queue v1");
        svc.rescan();
    }

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
        svc.cycleOrder      = (obj.order === "sequential" || obj.order === "random")
                              ? obj.order : "random";
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
            intervalSeconds: svc.intervalSeconds,
            order: svc.cycleOrder
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
    onCycleOrderChanged: persistState()

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
    function setCycleOrder(order) {
        svc.cycleOrder = order;
        // A sequential queue is meaningless after switching to random (and
        // vice versa) — discard and rebuild.
        svc._queue = [];
        svc._refillQueue();
    }

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
