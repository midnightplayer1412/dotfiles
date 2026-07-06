pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

QtObject {
    readonly property var commands: [
        {
            name: "/spotify",
            icon: "spotify",
            comment: "Search and play on Spotify",
            match: "spotify",
            takesArgs: true,
        },
        {
            name: "/ytmusic",
            icon: "youtube-music",
            comment: "Search and play on YouTube Music",
            match: "ytmusic",
            takesArgs: true,
        },
        {
            name: "/play",
            icon: "media-playback-start",
            comment: "Play / pause active media",
            match: "play",
        },
        {
            name: "/pause",
            icon: "media-playback-pause",
            comment: "Pause active media",
            match: "pause",
        },
        {
            name: "/next",
            icon: "media-skip-forward",
            comment: "Skip to next track",
            match: "next",
        },
        {
            name: "/prev",
            icon: "media-skip-backward",
            comment: "Previous track",
            match: "prev",
        },

        // Web search shortcuts — open a targeted search in the browser.
        { name: "/gh",   icon: "github",    comment: "Search GitHub",      match: "gh",   takesArgs: true },
        { name: "/yt",   icon: "youtube",   comment: "Search YouTube",     match: "yt",   takesArgs: true },
        { name: "/wiki", icon: "wikipedia", comment: "Search Wikipedia",   match: "wiki", takesArgs: true },
        { name: "/maps", icon: "maps",      comment: "Search Google Maps", match: "maps", takesArgs: true },
        { name: "/chatgpt", icon: "chatgpt", comment: "Ask ChatGPT (temporary chat)", match: "chatgpt", takesArgs: true },

        // Power / session — loginctl / systemctl / hyprctl.
        { name: "/lock",      icon: "system-lock-screen",       comment: "Lock the screen",           match: "lock" },
        { name: "/logout",    icon: "system-log-out",           comment: "Exit the Hyprland session", match: "logout" },
        { name: "/suspend",   icon: "system-suspend",           comment: "Suspend to RAM",            match: "suspend" },
        { name: "/hibernate", icon: "system-suspend-hibernate", comment: "Hibernate to disk",         match: "hibernate" },
        { name: "/reboot",    icon: "system-reboot",            comment: "Restart the system",        match: "reboot" },
        { name: "/shutdown",  icon: "system-shutdown",          comment: "Power off the system",      match: "shutdown" },
    ]

    function activePlayer() {
        const players = Mpris.players.values;
        if (players.length === 0) return null;
        for (const p of players) {
            if (p.playbackState === MprisPlaybackState.Playing) return p;
        }
        return players[0];
    }

    function execute(text) {
        const input = text.substring(1); // remove leading /
        const spaceIdx = input.indexOf(" ");
        const cmd = spaceIdx >= 0 ? input.substring(0, spaceIdx).toLowerCase() : input.toLowerCase();
        const args = spaceIdx >= 0 ? input.substring(spaceIdx + 1).trim() : "";

        if (cmd === "spotify") {
            if (args) {
                Qt.openUrlExternally("https://open.spotify.com/search/" + encodeURIComponent(args));
            } else {
                Qt.openUrlExternally("https://open.spotify.com");
            }
        } else if (cmd === "ytmusic") {
            if (args) {
                Qt.openUrlExternally("https://music.youtube.com/search?q=" + encodeURIComponent(args));
            } else {
                Qt.openUrlExternally("https://music.youtube.com");
            }
        } else if (cmd === "play") {
            const p = activePlayer();
            if (p && p.canTogglePlaying) p.togglePlaying();
        } else if (cmd === "pause") {
            const p = activePlayer();
            if (p && p.canPause) p.pause();
        } else if (cmd === "next") {
            const p = activePlayer();
            if (p && p.canGoNext) p.next();
        } else if (cmd === "prev") {
            const p = activePlayer();
            if (p && p.canGoPrevious) p.previous();
        } else if (cmd === "gh") {
            Qt.openUrlExternally(args
                ? "https://github.com/search?q=" + encodeURIComponent(args) + "&type=repositories"
                : "https://github.com");
        } else if (cmd === "yt") {
            Qt.openUrlExternally(args
                ? "https://www.youtube.com/results?search_query=" + encodeURIComponent(args)
                : "https://www.youtube.com");
        } else if (cmd === "wiki") {
            Qt.openUrlExternally(args
                ? "https://en.wikipedia.org/w/index.php?search=" + encodeURIComponent(args)
                : "https://en.wikipedia.org");
        } else if (cmd === "maps") {
            Qt.openUrlExternally(args
                ? "https://www.google.com/maps/search/" + encodeURIComponent(args)
                : "https://www.google.com/maps");
        } else if (cmd === "chatgpt") {
            // Temporary chat (temporary-chat=true) with the prompt prefilled (q=).
            Qt.openUrlExternally(args
                ? "https://chatgpt.com/?temporary-chat=true&q=" + encodeURIComponent(args)
                : "https://chatgpt.com/?temporary-chat=true");
        } else if (cmd === "lock") {
            // Same mechanism as SUPER+Escape (the Quickshell lockscreen).
            Quickshell.execDetached(["qs", "-p",
                Quickshell.env("HOME") + "/.config/quickshell/lock-screen.qml", "-d", "-n"]);
        } else if (cmd === "logout") {
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
        } else if (cmd === "suspend") {
            Quickshell.execDetached(["systemctl", "suspend"]);
        } else if (cmd === "hibernate") {
            Quickshell.execDetached(["systemctl", "hibernate"]);
        } else if (cmd === "reboot") {
            Quickshell.execDetached(["systemctl", "reboot"]);
        } else if (cmd === "shutdown") {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }
    }

    function filterShell(text) {
        const cmd = text.substring(1);
        return [{
            name: cmd ? "! " + cmd : "!",
            icon: "utilities-terminal",
            comment: "Run in terminal",
        }];
    }

    function runShell(text) {
        const cmd = text.substring(1).trim();
        if (!cmd) return;
        Quickshell.execDetached(["kitty", "sh", "-c", cmd + "; exec $SHELL"]);
    }

    function filter(text) {
        const input = text.substring(1).toLowerCase(); // remove leading /
        const spaceIdx = input.indexOf(" ");

        // If already typing args (space after command), show only the matched command
        if (spaceIdx >= 0) {
            const cmd = input.substring(0, spaceIdx);
            return commands.filter(c => c.match === cmd);
        }

        // Otherwise filter commands by prefix
        if (!input) return commands;
        return commands.filter(c => c.match.startsWith(input));
    }

    // ── Calculator (= prefix) ──────────────────────────────────────────
    // Safe recursive-descent arithmetic: + - * / % ^, unary +/-, parentheses,
    // decimals. No eval(). Returns a finite Number, or null on parse error.
    function calc(expr) {
        const s = (expr || "").replace(/\s+/g, "");
        if (!s) return null;
        let i = 0;
        function peek() { return s[i]; }
        function parseExpr() {
            let v = parseTerm();
            while (peek() === "+" || peek() === "-") {
                const op = s[i++]; const r = parseTerm();
                v = op === "+" ? v + r : v - r;
            }
            return v;
        }
        function parseTerm() {
            let v = parsePow();
            while (peek() === "*" || peek() === "/" || peek() === "%") {
                const op = s[i++]; const r = parsePow();
                v = op === "*" ? v * r : op === "/" ? v / r : v % r;
            }
            return v;
        }
        function parsePow() {
            const v = parseUnary();
            if (peek() === "^") { i++; return Math.pow(v, parsePow()); }
            return v;
        }
        function parseUnary() {
            if (peek() === "-") { i++; return -parseUnary(); }
            if (peek() === "+") { i++; return parseUnary(); }
            return parsePrimary();
        }
        function parsePrimary() {
            if (peek() === "(") {
                i++; const v = parseExpr();
                if (peek() === ")") i++; else throw new Error("unbalanced");
                return v;
            }
            let num = "";
            while (i < s.length && /[0-9.]/.test(s[i])) num += s[i++];
            if (num === "") throw new Error("bad token");
            return parseFloat(num);
        }
        try {
            const v = parseExpr();
            if (i < s.length) return null;        // trailing garbage
            return isFinite(v) ? v : null;
        } catch (e) {
            return null;
        }
    }

    function _fmtNum(v) {
        // Trim float noise; keep up to 10 significant digits.
        return parseFloat(v.toPrecision(10)).toString();
    }

    function filterCalc(text) {
        const v = calc(text.substring(1));
        if (v === null) {
            return [{ name: "Invalid expression", icon: "dialog-error",
                      comment: "", run: () => {} }];
        }
        const out = _fmtNum(v);
        return [{ name: "= " + out, icon: "accessories-calculator",
                  comment: "Press Enter to copy", run: () => copyResult(out) }];
    }

    function copyResult(value) {
        Quickshell.execDetached(["wl-copy", String(value)]);
        Quickshell.execDetached(["notify-send", "Calculator", "Copied " + value]);
    }

    // ── Web search fallback (engine configurable in Settings → Launcher) ─
    function webSearch(query) {
        Qt.openUrlExternally(LauncherConfig.engineUrl() + encodeURIComponent(query));
    }

    function webResult(query) {
        return { name: "Search the web for \"" + query + "\"",
                 icon: "system-search", comment: LauncherConfig.engineLabel(),
                 run: () => webSearch(query) };
    }
}
