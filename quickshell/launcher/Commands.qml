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
        Quickshell.execDetached(["ghostty", "-e", "sh", "-c", cmd + "; exec $SHELL"]);
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
}
