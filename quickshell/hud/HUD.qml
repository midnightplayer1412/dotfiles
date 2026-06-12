import QtQuick
import Quickshell
import Quickshell.Io
import ".."

PanelWindow {
    id: hudWindow

    required property var screen

    // Bottom-center positioning
    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitWidth: screen.width
    implicitHeight: 100
    margins.bottom: 40
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // State
    property bool active: HudState.isVisibleOnScreen(screen)
    property bool mouseInside: false
    visible: active

    Connections {
        target: HudState
        function onActiveScreensChanged() {
            hudWindow.active = HudState.isVisibleOnScreen(screen);
        }
    }

    // Auto-hide timer
    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: {
            if (!hudWindow.mouseInside) {
                HudState.hide(screen);
            }
        }
    }

    // Volume and brightness values
    property real volumeValue: 0.5
    property real brightnessValue: 0.5
    property real previousVolume: 0.5
    property real previousBrightness: 0.5

    // Mute state — output sink and microphone source
    property bool muted: false
    property bool previousMuted: false
    property bool micMuted: false
    property bool previousMicMuted: false
    // Skip showing the OSD for the very first poll so a muted mic/sink at
    // login doesn't pop the HUD before the user has touched anything.
    property bool seeded: false

    // Volume process
    property string volumeOutput: ""

    Process {
        id: getVolumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

        stdout: SplitParser {
            onRead: data => {
                hudWindow.volumeOutput += data;
            }
        }

        onExited: code => {
            var output = hudWindow.volumeOutput.trim();
            hudWindow.volumeOutput = "";
            if (!output) return;

            var match = output.match(/Volume:\s+([\d.]+)/);
            if (!match) return;

            var newVolume = parseFloat(match[1]);
            var isMuted = output.indexOf("[MUTED]") >= 0;

            var volChanged = Math.abs(newVolume - hudWindow.previousVolume) > 0.01;
            var muteChanged = isMuted !== hudWindow.previousMuted;

            hudWindow.volumeValue = newVolume;
            hudWindow.muted = isMuted;

            if (hudWindow.seeded && (volChanged || muteChanged)) {
                showHUD("volume");
            }
            hudWindow.previousVolume = newVolume;
            hudWindow.previousMuted = isMuted;
        }
    }

    Process {
        id: setVolumeProc
    }

    // Microphone mute process — source has no level bar, only a mute flag
    property string micOutput: ""

    Process {
        id: getMicProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]

        stdout: SplitParser {
            onRead: data => {
                hudWindow.micOutput += data;
            }
        }

        onExited: code => {
            var output = hudWindow.micOutput.trim();
            hudWindow.micOutput = "";
            if (!output) return;

            var isMuted = output.indexOf("[MUTED]") >= 0;
            var changed = isMuted !== hudWindow.previousMicMuted;

            hudWindow.micMuted = isMuted;

            if (hudWindow.seeded && changed) {
                showHUD("mic");
            }
            hudWindow.previousMicMuted = isMuted;
        }
    }

    // Brightness processes
    property string brightnessCurrentOutput: ""

    Process {
        id: getBrightnessProc
        command: ["brightnessctl", "get"]

        stdout: SplitParser {
            onRead: data => {
                hudWindow.brightnessCurrentOutput += data;
            }
        }

        onExited: code => {
            var output = hudWindow.brightnessCurrentOutput.trim();
            if (!output) {
                hudWindow.brightnessCurrentOutput = "";
                return;
            }
            var current = parseInt(output);
            if (!isNaN(current)) {
                getBrightnessMaxProc.running = true;
            }
        }
    }

    property string brightnessMaxOutput: ""

    Process {
        id: getBrightnessMaxProc
        command: ["brightnessctl", "max"]

        stdout: SplitParser {
            onRead: data => {
                hudWindow.brightnessMaxOutput += data;
            }
        }

        onExited: code => {
            var maxOutput = hudWindow.brightnessMaxOutput.trim();
            var currentOutput = hudWindow.brightnessCurrentOutput.trim();
            hudWindow.brightnessMaxOutput = "";
            hudWindow.brightnessCurrentOutput = "";

            if (!maxOutput || !currentOutput) return;

            var max = parseInt(maxOutput);
            var current = parseInt(currentOutput);

            if (!isNaN(max) && !isNaN(current) && max > 0) {
                var newBrightness = current / max;
                if (Math.abs(newBrightness - hudWindow.previousBrightness) > 0.01) {
                    hudWindow.previousBrightness = newBrightness;
                    hudWindow.brightnessValue = newBrightness;
                    if (hudWindow.seeded) showHUD("brightness");
                } else {
                    hudWindow.brightnessValue = newBrightness;
                }
            }
        }
    }

    Process {
        id: setBrightnessProc
    }

    // Poll timer
    Timer {
        id: updateTimer
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            getVolumeProc.running = true;
            getMicProc.running = true;
            getBrightnessProc.running = true;
            // After the first full poll cycle, allow the HUD to surface.
            hudWindow.seeded = true;
        }
    }

    function setVolume(value) {
        volumeValue = value;
        setVolumeProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", value.toFixed(2)];
        setVolumeProc.running = true;
        showHUD("volume");
    }

    function setBrightness(value) {
        brightnessValue = value;
        var percentage = Math.round(value * 100);
        setBrightnessProc.command = ["brightnessctl", "set", percentage + "%"];
        setBrightnessProc.running = true;
        showHUD("brightness");
    }

    function showHUD(indicator) {
        HudState.show(screen, indicator);
        hideTimer.restart();
    }

    // ─── Display derivation ─────────────────────────────────────────
    readonly property string indicator: HudState.activeIndicator
    readonly property bool isMic: indicator === "mic"
    readonly property bool isVolume: indicator === "volume"
    readonly property bool isBrightness: indicator === "brightness"
    readonly property bool volumeMuted: isVolume && muted

    property real displayValue: isVolume ? volumeValue
        : isBrightness ? brightnessValue : 0
    property string displayIcon: {
        if (isMic) return micMuted ? "\u{F036D}" : "\u{F036C}";  // mic-off / mic
        if (isVolume) return muted ? "\u{F0581}" : "\u{F057E}";  // volume-off / volume-high
        return "\u{F00DF}";                                       // brightness
    }
    property string displayPercent: volumeMuted ? "Muted" : (Math.round(displayValue * 100) + "%")
    property string micLabel: micMuted ? "Microphone muted" : "Microphone on"
    property color indicatorColor: {
        if (isMic) return micMuted ? Theme.error : Theme.secondary;
        if (volumeMuted) return Theme.error;
        return isVolume ? Theme.primary : Theme.secondary;
    }

    // Main container — centered horizontal pill
    Rectangle {
        id: container
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 300
        height: 50
        color: Theme.surface
        radius: 25
        border.color: Theme.outline
        border.width: 1

        // Slide-up animation
        anchors.bottomMargin: active ? 0 : -60
        opacity: active ? 1.0 : 0.0

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true

            onEntered: hudWindow.mouseInside = true
            onExited: {
                hudWindow.mouseInside = false;
                hideTimer.restart();
            }

            onPressed: mouse => mouse.accepted = false
            onReleased: mouse => mouse.accepted = false
            onClicked: mouse => mouse.accepted = false
        }

        Row {
            anchors.centerIn: parent
            spacing: 14
            width: parent.width - 40

            // Icon
            Text {
                text: hudWindow.displayIcon
                font.family: "MonaspiceKr NF"
                font.pixelSize: 20
                color: hudWindow.indicatorColor
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                horizontalAlignment: Text.AlignHCenter
            }

            // Content area — level bar + percent (volume/brightness) or
            // a centered status label (microphone, which has no level).
            Item {
                width: parent.width - 24 - 14
                height: 24
                anchors.verticalCenter: parent.verticalCenter

                // Progress bar
                Rectangle {
                    id: track
                    visible: !hudWindow.isMic
                    width: parent.width - 56
                    height: 8
                    radius: 4
                    color: Theme.surfaceContainer
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: parent.width * hudWindow.displayValue
                        height: parent.height
                        radius: 4
                        color: hudWindow.indicatorColor
                        opacity: hudWindow.volumeMuted ? 0.5 : 1.0

                        Behavior on width {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }

                    // Click to set value (only meaningful for volume/brightness)
                    MouseArea {
                        anchors.fill: parent
                        onPositionChanged: (mouse) => {
                            let value = Math.max(0, Math.min(1, mouse.x / width));
                            if (hudWindow.isVolume)
                                hudWindow.setVolume(value);
                            else
                                hudWindow.setBrightness(value);
                        }
                        onPressed: (mouse) => {
                            let value = Math.max(0, Math.min(1, mouse.x / width));
                            if (hudWindow.isVolume)
                                hudWindow.setVolume(value);
                            else
                                hudWindow.setBrightness(value);
                        }
                    }
                }

                // Percentage / "Muted"
                Text {
                    visible: !hudWindow.isMic
                    text: hudWindow.displayPercent
                    font.family: "MonaspiceKr NF"
                    font.pixelSize: 14
                    color: hudWindow.volumeMuted ? Theme.error : Theme.primary
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 50
                    horizontalAlignment: Text.AlignRight
                }

                // Microphone status label
                Text {
                    visible: hudWindow.isMic
                    text: hudWindow.micLabel
                    font.family: "MonaspiceKr NF"
                    font.pixelSize: 14
                    color: hudWindow.indicatorColor
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Component.onCompleted: {
        getVolumeProc.running = true;
        getMicProc.running = true;
        getBrightnessProc.running = true;
    }
}
