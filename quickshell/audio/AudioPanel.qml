import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../ui" as Ui
import ".."
import "../audio"

Item {
    id: root

    Component.onCompleted: AudioService.refresh()

    // Default sink, level-aware glyph for the master row.
    readonly property var masterSink: Pipewire.defaultAudioSink
    readonly property var masterAudio: masterSink && masterSink.audio ? masterSink.audio : null
    readonly property real masterVol: masterAudio ? masterAudio.volume : 0
    readonly property bool masterMuted: masterAudio ? masterAudio.muted : false
    readonly property string masterGlyph: {
        if (masterMuted || masterVol <= 0.001) return "\u{F0581}";   // volume-off
        if (masterVol < 0.34) return "\u{F057F}";                    // volume-low
        if (masterVol < 0.67) return "\u{F0580}";                    // volume-medium
        return "\u{F057E}";                                          // volume-high
    }

    // Keep the default sink bound so its volume/mute are live.
    PwObjectTracker {
        objects: root.masterSink ? [root.masterSink] : []
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        ScrollBar.vertical: Ui.ScrollBar {}
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 14

            Text {
                text: "Audio"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
            }

            // Error banner
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: errText.implicitHeight + 16
                visible: AudioService.lastError.length > 0
                radius: 8
                color: Qt.rgba(1.0, 0.4, 0.4, 0.15)
                border.color: Qt.rgba(1.0, 0.4, 0.4, 0.4)
                border.width: 1

                Text {
                    id: errText
                    anchors.fill: parent
                    anchors.margins: 8
                    text: AudioService.lastError
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AudioService.clearError()
                }
            }

            // ── Master volume ─────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Master"
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: root.masterGlyph
                        color: masterMuteMouse.containsMouse
                            ? Theme.primary
                            : (root.masterMuted ? Theme.outline : Theme.surfaceText)
                        font.family: Theme.glyphFont
                        font.pixelSize: 18
                        Layout.preferredWidth: 24
                        horizontalAlignment: Text.AlignHCenter

                        MouseArea {
                            id: masterMuteMouse
                            anchors.fill: parent
                            anchors.margins: -3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.masterAudio) root.masterAudio.muted = !root.masterAudio.muted
                        }
                    }

                    Ui.Slider {
                        Layout.fillWidth: true
                        value: root.masterVol
                        active: !root.masterMuted
                        onMoved: (v) => { if (root.masterAudio) root.masterAudio.volume = v; }
                    }

                    Text {
                        text: root.masterMuted ? "Muted" : Math.round(root.masterVol * 100) + "%"
                        color: root.masterMuted ? Theme.outline : Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        Layout.preferredWidth: 42
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.outline
                opacity: 0.4
            }

            // ── Output device ─────────────────────────────────────────
            Text {
                text: "Output"
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
            }

            Repeater {
                model: AudioService.sinks
                delegate: OutputRow { Layout.fillWidth: true }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.outline
                opacity: 0.4
            }

            // ── Per-app mixer ─────────────────────────────────────────
            AppMixer {
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }
        }
    }
}
