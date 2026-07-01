import QtQuick
import QtQuick.Layouts
import Quickshell
import "../ui" as Ui
import ".."
import "../audio"

// One application playback stream: icon · name · volume slider · mute · route.
Item {
    id: row

    required property var node           // PwNode (audio output stream)
    property bool expanded: false        // routing picker open

    readonly property var audio: node && node.audio ? node.audio : null
    readonly property real vol: audio ? audio.volume : 0
    readonly property bool muted: audio ? audio.muted : false

    readonly property var props: node && node.properties ? node.properties : ({})
    readonly property string appName:
        props["application.name"] || (node ? (node.description || node.name) : "") || "Audio"
    readonly property string serial: props["object.serial"] || ""

    // Resolve an app icon by trying the reported icon-name, then the app/binary
    // name, each existence-checked (iconPath(_, true) returns "" when missing) so
    // a bad name yields the letter-avatar fallback instead of a broken-icon box.
    readonly property string resolvedIcon: {
        const cands = [];
        if (props["application.icon-name"]) cands.push(props["application.icon-name"]);
        if (appName) cands.push(appName.toLowerCase());
        if (props["application.process.binary"])
            cands.push(String(props["application.process.binary"]).toLowerCase());
        for (let i = 0; i < cands.length; i++) {
            const p = Quickshell.iconPath(cands[i], true);
            if (p) return p;
        }
        return "";
    }

    readonly property string volGlyph: {
        if (muted || vol <= 0.001) return "\u{F0581}";   // volume-off
        if (vol < 0.34) return "\u{F057F}";              // volume-low
        if (vol < 0.67) return "\u{F0580}";              // volume-medium
        return "\u{F057E}";                              // volume-high
    }

    implicitHeight: col.implicitHeight
    height: implicitHeight

    Column {
        id: col
        width: row.width
        spacing: 6

        // ── Line 1: icon · name · percent · mute ──────────────────────
        RowLayout {
            width: parent.width
            spacing: 10

            // App icon (theme icon → letter-avatar fallback)
            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 6
                color: iconImg.status === Image.Ready ? "transparent" : Theme.surfaceContainer
                clip: true

                Image {
                    id: iconImg
                    anchors.fill: parent
                    anchors.margins: 2
                    source: row.resolvedIcon
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready
                    asynchronous: true
                    cache: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: iconImg.status !== Image.Ready
                    text: (row.appName.charAt(0) || "?").toUpperCase()
                    color: Theme.primary
                    font.bold: true
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                }
            }

            Text {
                Layout.fillWidth: true
                text: row.appName
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                text: row.muted ? "Muted" : Math.round(row.vol * 100) + "%"
                color: row.muted ? Theme.outline : Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                Layout.preferredWidth: 42
                horizontalAlignment: Text.AlignRight
            }

            // Mute toggle (level-aware glyph)
            Text {
                text: row.volGlyph
                color: muteMouse.containsMouse
                    ? Theme.primary
                    : (row.muted ? Theme.outline : Theme.surfaceText)
                font.family: Theme.glyphFont
                font.pixelSize: 17
                Layout.preferredWidth: 22
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (row.audio) row.audio.muted = !row.audio.muted
                }
            }
        }

        // ── Line 2: slider · route ────────────────────────────────────
        RowLayout {
            width: parent.width
            spacing: 10

            Ui.Slider {
                Layout.fillWidth: true
                Layout.leftMargin: 36          // align under the name, past the icon
                value: row.vol
                active: !row.muted
                onMoved: (v) => { if (row.audio) row.audio.volume = v; }
            }

            // Route to another output
            Text {
                text: "\u{F04E1}"              // swap-horizontal
                color: (routeMouse.containsMouse || row.expanded)
                    ? Theme.primary : Theme.outline
                font.family: Theme.glyphFont
                font.pixelSize: 16
                Layout.preferredWidth: 22
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    id: routeMouse
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.expanded = !row.expanded
                }
            }
        }

        // ── Inline output picker ──────────────────────────────────────
        Column {
            width: parent.width
            visible: row.expanded
            spacing: 2
            leftPadding: 36
            topPadding: 2
            bottomPadding: 4

            Repeater {
                model: AudioService.sinks

                delegate: Ui.SelectableRow {
                    required property var modelData
                    width: parent.width - 36
                    height: 26
                    radius: 6
                    onClicked: {
                        AudioService.moveStream(row.serial, modelData.name);
                        row.expanded = false;
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.description
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
