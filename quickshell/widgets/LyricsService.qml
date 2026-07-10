pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// The lyrics brain. Tracks the active MPRIS player (same selection rule as
// MediaWidget), resolves synced/plain lyrics, parses the LRC into a sorted
// [{t, text}] array, and computes the current line from player.position.
//
// Resolution happens in ONE shell process, highest priority first:
//   1. local .lrc sidecar next to the track file (from xesam:url)
//   2. local .lrc in the configured lyrics folder ("Artist - Title.lrc")
//   3. LRCLIB disk cache
//   4. LRCLIB /api/get -> /api/search
// Hits are cached; misses write a "notfound" marker (7-day TTL) so a lyric-less
// track isn't re-fetched on every play but self-heals if LRCLIB gains it later.
// The command prints a one-line tag (LRC | JSON) so ingest() knows how to read
// the body. Local file paths are passed as positional args (never interpolated)
// so arbitrary filenames need no escaping. No API key.
Singleton {
    id: svc

    readonly property var player: {
        const ps = Mpris.players.values;
        if (ps.length === 0) return null;
        for (const p of ps) if (p.playbackState === MprisPlaybackState.Playing) return p;
        return ps[0];
    }
    readonly property bool playing: player !== null && player.playbackState === MprisPlaybackState.Playing

    readonly property string title:  player ? (player.trackTitle  || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album:  player ? (player.trackAlbum  || "") : ""
    readonly property real   len:    player && player.length ? player.length : 0

    // Track file URL from MPRIS metadata. Local-file players (mpd/mpv/vlc/…) give
    // a file:// URL; streaming players give a non-file URI (no sidecar applies).
    readonly property string trackUrl: {
        if (!player) return "";
        const md = player.metadata;
        return (md && md["xesam:url"]) ? md["xesam:url"] : "";
    }
    readonly property bool isLocalFile: trackUrl.indexOf("file://") === 0

    // Identity — any change refetches. Delimited so fields never run together.
    readonly property string trackKey:
        title + " :: " + artist + " :: " + album + " :: " + Math.round(len)

    // Parsed state.
    property var lines: []          // [{t, text}] for synced lyrics
    property string plainText: ""   // plain lyrics fallback (no timing)
    property string rawSynced: ""   // original .lrc body (for save-to-disk)
    property bool synced: false     // have timestamped lines
    property bool available: false  // have lyrics to show
    property bool loading: false    // a fetch is in flight for the current track
    property int currentIndex: -1   // active synced line

    // Instrumental: synced lyrics are playing but the current position has no
    // words — the intro before the first line, or a break/outro whose line is
    // empty or note-glyph-only. Drives the pulsing-dots indicator in the views.
    readonly property bool instrumental:
        svc.synced && svc.playing
        && (svc.currentIndex < 0
            || svc.isNoteOnly(svc.lines[svc.currentIndex] ? svc.lines[svc.currentIndex].text : ""))

    // True for empty text or a line made only of musical-note glyphs / dashes —
    // how LRC files mark instrumental stretches.
    function isNoteOnly(text) {
        return text.replace(/[\s♪♫♬♩·・．.\-—–_]/g, "").length === 0;
    }

    // A real track is loaded in a player (playing or paused). Drives whether the
    // strip should be on screen at all (with lyrics, or the empty-state label).
    readonly property bool active: player !== null && title.length > 0

    readonly property int offsetMs: LyricsConfig.offsetMs

    onTrackKeyChanged: svc.reload()
    onOffsetMsChanged: svc.recompute()
    Component.onCompleted: svc.reload()

    // Filesystem-safe cache key from the track identity.
    function safeKey() {
        const raw = svc.artist + "_" + svc.title + "_" + svc.album + "_" + Math.round(svc.len);
        return raw.replace(/[^a-zA-Z0-9]+/g, "_").replace(/^_+|_+$/g, "").slice(0, 180) || "unknown";
    }

    // Sidecar .lrc next to the audio file: swap the extension for .lrc. "" if the
    // track isn't a local file.
    function sidecarPath() {
        if (!svc.isLocalFile) return "";
        let p;
        try { p = decodeURIComponent(svc.trackUrl.slice(7)); }   // drop "file://"
        catch (e) { p = svc.trackUrl.slice(7); }
        const dot = p.lastIndexOf("."), slash = p.lastIndexOf("/");
        if (dot > slash) p = p.slice(0, dot);
        return p + ".lrc";
    }

    // Candidate paths in the configured lyrics folder: "Artist - Title.lrc" then
    // "Title.lrc". Needs only metadata, so it works for streaming players too.
    function folderPaths() {
        let dir = LyricsConfig.lyricsDir || "";
        if (!dir) return [];
        if (dir.indexOf("~") === 0) dir = Quickshell.env("HOME") + dir.slice(1);
        if (dir.length > 1 && dir.charAt(dir.length - 1) === "/") dir = dir.slice(0, -1);
        const out = [];
        if (svc.artist && svc.title) out.push(dir + "/" + svc.artist + " - " + svc.title + ".lrc");
        if (svc.title) out.push(dir + "/" + svc.title + ".lrc");
        return out;
    }

    function reload() {
        // Drop stale lyrics immediately so the previous song never lingers.
        svc.lines = [];
        svc.plainText = "";
        svc.rawSynced = "";
        svc.synced = false;
        svc.available = false;
        svc.currentIndex = -1;
        svc.saveStatus = "";
        if (!svc.title) { svc.loading = false; return; }
        svc.loading = true;

        const q = (s) => encodeURIComponent(s || "");
        const dur = Math.round(svc.len);
        const getUrl = "https://lrclib.net/api/get?artist_name=" + q(svc.artist)
            + "&track_name=" + q(svc.title) + "&album_name=" + q(svc.album)
            + (dur > 0 ? "&duration=" + dur : "");
        const searchUrl = "https://lrclib.net/api/search?q=" + q(svc.artist + " " + svc.title);

        const cacheFile = Quickshell.env("HOME") + "/.cache/quickshell/lyrics/" + svc.safeKey() + ".json";

        // Local candidates (empty string = "skip this slot"). Only consulted when
        // the user has local files enabled.
        const useLocal = LyricsConfig.useLocalFiles;
        const sidecar = useLocal ? svc.sidecarPath() : "";
        const folder = useLocal ? svc.folderPaths() : [];

        // Positional args ($1 sidecar, $2/$3 folder, $4 cache, $5 get, $6 search)
        // so arbitrary filenames never need shell escaping. First output line is a
        // tag: LRC (raw .lrc body) or JSON (LRCLIB envelope).
        const script =
            'for f in "$1" "$2" "$3"; do'
            + '  if [ -n "$f" ] && [ -s "$f" ]; then printf "LRC\\n"; cat "$f"; exit 0; fi;'
            + 'done;'
            + 'if [ -s "$4" ]; then '
            +   'if [ "$(cat "$4")" = notfound ] && [ -n "$(find "$4" -mtime +7)" ]; then rm -f "$4"; '
            +   'else printf "JSON\\n"; cat "$4"; exit 0; fi; '
            + 'fi;'
            + 'mkdir -p "$(dirname "$4")";'
            // Prefer REAL synced lyrics. Match "syncedLyrics":"…" (a non-null string),
            // NOT the bare key — /api/get returns "syncedLyrics":null for plain-only
            // tracks, so keying on the field name alone wrongly skips /api/search.
            + 'g=$(curl -sf --max-time 8 "$5");'
            + "case \"$g\" in *'\"syncedLyrics\":\"'*) r=$g ;; *) "
            +   's=$(curl -sf --max-time 8 "$6"); '
            +   "case \"$s\" in *'\"syncedLyrics\":\"'*) r=$s ;; *) "
            +     'case "$g" in *plainLyrics*) r=$g ;; *) r=$s ;; esac '
            +   ';; esac '
            + ';; esac;'
            + 'printf "JSON\\n%s" "$r";'
            + "case \"$r\" in *'\"syncedLyrics\":\"'*|*'\"plainLyrics\":\"'*) printf \"%s\" \"$r\" > \"$4\" ;; "
            +   '*) printf notfound > "$4" ;; esac';

        proc.running = false;
        proc.command = ["sh", "-c", script, "lyrics",
            sidecar, folder[0] || "", folder[1] || "", cacheFile, getUrl, searchUrl];
        proc.running = true;
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: svc.ingest(text)
        }
    }

    // Wipe the LRCLIB disk cache (both positive hits and "notfound" markers). The
    // current track re-resolves as soon as the wipe finishes, so a mis-cached or
    // stale-negative track picks up fresh lyrics without a restart. Local .lrc
    // files aren't touched (they're not cache).
    function clearCache() {
        clearProc.running = false;
        clearProc.running = true;
    }

    Process {
        id: clearProc
        command: ["sh", "-c", 'rm -rf "$HOME/.cache/quickshell/lyrics"']
        onExited: svc.reload()
    }

    // ── Save lyrics to a persistent .lrc file ──────────────────────────────
    // Writes the fetched lyrics next to the track (local files) or into the
    // configured lyrics folder as "Artist - Title.lrc", so they survive a cache
    // wipe and stay available offline. Synced (timed) text is preferred; plain
    // lyrics save as an untimed .lrc.
    property string saveStatus: ""   // "" | "saving" | "saved" | "failed"

    // Where a save would land, or "" if there's nowhere to put it (streaming
    // track with no lyrics folder set). Drives the button's enabled state.
    readonly property string saveTarget: {
        if (!svc.available) return "";
        if (svc.isLocalFile) return svc.sidecarPath();
        const fp = svc.folderPaths();
        return fp.length > 0 ? fp[0] : "";
    }
    readonly property bool canSaveLrc: svc.saveTarget.length > 0

    function saveLrc() {
        if (!svc.canSaveLrc) return;
        const body = svc.rawSynced || svc.plainText;
        if (!body) return;
        svc.saveStatus = "saving";
        // Content + path as positional args so arbitrary filenames/text never
        // need shell escaping.
        saveProc.command = ["sh", "-c",
            'mkdir -p "$(dirname "$2")" && printf "%s" "$1" > "$2"',
            "savelrc", body, svc.saveTarget];
        saveProc.running = false;
        saveProc.running = true;
    }

    Process {
        id: saveProc
        onExited: (code) => { svc.saveStatus = code === 0 ? "saved" : "failed"; }
    }

    // First line is the source tag; the rest is the body.
    function ingest(text) {
        svc.loading = false;
        const nl = text.indexOf("\n");
        const tag = nl >= 0 ? text.slice(0, nl) : "";
        const body = nl >= 0 ? text.slice(nl + 1) : text;
        if (tag === "LRC") svc.ingestLrc(body);
        else svc.ingestJson(body);
    }

    // Raw .lrc from a local file — timestamped lines, or plain text if untimed.
    function ingestLrc(lrc) {
        const parsed = svc.parseLrc(lrc);
        if (parsed.length > 0) {
            svc.lines = parsed;
            svc.synced = true;
            svc.plainText = "";
            svc.rawSynced = lrc.replace(/\s+$/, "");
        } else {
            svc.lines = [];
            svc.synced = false;
            svc.plainText = lrc.trim();
        }
        svc.available = svc.synced || svc.plainText.length > 0;
        svc.recompute();
    }

    // LRCLIB envelope ({syncedLyrics, plainLyrics}); /api/search returns an array.
    function ingestJson(text) {
        let data;
        try { data = JSON.parse(text); } catch (e) { svc.available = false; return; }
        if (Array.isArray(data))
            data = data.find(d => d && d.syncedLyrics) || data.find(d => d && d.plainLyrics) || data[0] || {};
        if (!data) { svc.available = false; return; }

        const sy = data.syncedLyrics || "";
        const pl = data.plainLyrics || "";
        if (sy) {
            svc.lines = svc.parseLrc(sy);
            svc.synced = svc.lines.length > 0;
            if (svc.synced) svc.rawSynced = sy.replace(/\s+$/, "");
        }
        svc.plainText = pl;
        svc.available = svc.synced || pl.length > 0;
        svc.recompute();
    }

    // Parse LRC ("[mm:ss.xx] text", possibly multiple stamps per line) into a
    // sorted [{t, text}]. Metadata tags ([ar:], [ti:], …) don't match and drop.
    function parseLrc(lrc) {
        const rx = /\[(\d+):(\d+)(?:[.:](\d+))?\]/g;
        const out = [];
        for (const line of lrc.split("\n")) {
            rx.lastIndex = 0;
            const stamps = [];
            let m;
            while ((m = rx.exec(line)) !== null) {
                const frac = m[3] ? parseInt(m[3]) / Math.pow(10, m[3].length) : 0;
                stamps.push(parseInt(m[1]) * 60 + parseInt(m[2]) + frac);
            }
            if (stamps.length === 0) continue;
            const text = line.replace(rx, "").trim();
            for (const t of stamps) out.push({ t: t, text: text });
        }
        out.sort((a, b) => a.t - b.t);
        return out;
    }

    // Active line = last one whose time <= position (+ offset).
    function recompute() {
        if (!svc.synced || !svc.player) { svc.currentIndex = -1; return; }
        const t = svc.player.position + svc.offsetMs / 1000;
        const ls = svc.lines;
        let res = -1;
        for (let i = 0; i < ls.length; i++) {
            if (ls[i].t <= t) res = i; else break;
        }
        svc.currentIndex = res;
    }

    // Reading player.position refetches over DBus; 250ms keeps the highlight
    // tight without hammering it. Runs only while synced lyrics are playing.
    Timer {
        interval: 250; repeat: true
        running: svc.synced && svc.playing
        onTriggered: svc.recompute()
    }
}
