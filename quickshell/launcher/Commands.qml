pragma Singleton

import QtQuick

QtObject {
    readonly property var commands: [
        {
            name: "/spotify",
            icon: "spotify",
            comment: "Search and play on Spotify",
            match: "spotify",
        },
        {
            name: "/ytmusic",
            icon: "youtube-music",
            comment: "Search and play on YouTube Music",
            match: "ytmusic",
        },
    ]

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
        }
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
