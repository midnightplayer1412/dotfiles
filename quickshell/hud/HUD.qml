import QtQuick
import Quickshell
import Quickshell.Io
import ".."

PanelWindow {
    id: hudWindow

    required property var screen

    // Positioning
    anchors {
        right: true
        top: true
        bottom: true
    }

    // Window properties
    implicitWidth: 100
    implicitHeight: 300
    margins.right: 20
    margins.top: (screen.height - implicitHeight) / 2
    margins.bottom: (screen.height - implicitHeight) / 2
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // State to hide/show
    property bool active: HudState.isVisibleOnScreen(screen)
    property bool mouseInside: false
    visible: active

    // Watch for state changes
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
            // Only hide if mouse is not inside
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

    // Process for getting volume
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
            hudWindow.volumeOutput = ""; // Clear buffer

            if (!output) return;

            var match = output.match(/Volume:\s+([\d.]+)/);
            if (match) {
                var newVolume = parseFloat(match[1]);
                // Show HUD if volume changed
                if (Math.abs(newVolume - hudWindow.previousVolume) > 0.01) {
                    hudWindow.previousVolume = newVolume;
                    hudWindow.volumeValue = newVolume;
                    showHUD();
                } else {
                    hudWindow.volumeValue = newVolume;
                }
            }
        }
    }

    // Process for setting volume
    Process {
        id: setVolumeProc
        // command set dynamically
    }

    // Process for getting brightness current value
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

    // Process for getting brightness max value
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
            hudWindow.brightnessMaxOutput = ""; // Clear buffer
            hudWindow.brightnessCurrentOutput = ""; // Clear current buffer too

            if (!maxOutput || !currentOutput) return;

            var max = parseInt(maxOutput);
            var current = parseInt(currentOutput);

            if (!isNaN(max) && !isNaN(current) && max > 0) {
                var newBrightness = current / max;
                // Show HUD if brightness changed
                if (Math.abs(newBrightness - hudWindow.previousBrightness) > 0.01) {
                    hudWindow.previousBrightness = newBrightness;
                    hudWindow.brightnessValue = newBrightness;
                    showHUD();
                } else {
                    hudWindow.brightnessValue = newBrightness;
                }
            }
        }
    }

    // Process for setting brightness
    Process {
        id: setBrightnessProc
        // command set dynamically
    }

    // Update timer - poll volume/brightness periodically
    Timer {
        id: updateTimer
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            getVolumeProc.running = true;
            getBrightnessProc.running = true;
        }
    }

    function setVolume(value) {
        volumeValue = value;
        setVolumeProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", value.toFixed(2)];
        setVolumeProc.running = true;
        showHUD();
    }

    function setBrightness(value) {
        brightnessValue = value;
        var percentage = Math.round(value * 100);
        setBrightnessProc.command = ["brightnessctl", "set", percentage + "%"];
        setBrightnessProc.running = true;
        showHUD();
    }

    function showHUD() {
        HudState.show(screen);
        hideTimer.restart();
    }

    // Main container
    Rectangle {
        anchors.centerIn: parent
        width: 80
        height: 250
        color: Theme.surface
        radius: Theme.barRadius
        border.color: Theme.outline
        border.width: 1

        // Mouse area to detect hover
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true

            onEntered: {
                hudWindow.mouseInside = true;
            }

            onExited: {
                hudWindow.mouseInside = false;
                hideTimer.restart();
            }

            // Block mouse events from propagating to children
            onPressed: mouse => mouse.accepted = false
            onReleased: mouse => mouse.accepted = false
            onClicked: mouse => mouse.accepted = false
        }

        Row {
            anchors.centerIn: parent
            spacing: 20

            // Volume Slider
            Column {
                spacing: 8

                Text {
                    text: "🎧"
                    font.family: "MonaspiceKr NF"
                    font.pixelSize: 16
                    color: Theme.primary
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    id: volumeTrack
                    width: 20
                    height: 200
                    color: Theme.surfaceContainer
                    radius: 10

                    // Volume level indicator
                    Rectangle {
                        width: parent.width
                        height: parent.height * hudWindow.volumeValue
                        color: Theme.primary
                        radius: 10
                        anchors.bottom: parent.bottom
                    }

                    // Interaction
                    MouseArea {
                        anchors.fill: parent
                        onPositionChanged: (mouse) => {
                            let rawValue = 1.0 - (mouse.y / height);
                            let clampedValue = Math.max(0, Math.min(1, rawValue));
                            hudWindow.setVolume(clampedValue);
                        }
                        onPressed: showHUD()
                    }
                }
            }

            // Brightness Slider
            Column {
                spacing: 8

                Text {
                    text: "☀︎"
                    font.family: "MonaspiceKr NF"
                    font.pixelSize: 16
                    color: Theme.primary
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    id: brightnessTrack
                    width: 20
                    height: 200
                    color: Theme.surfaceContainer
                    radius: 10

                    // Brightness level indicator
                    Rectangle {
                        width: parent.width
                        height: parent.height * hudWindow.brightnessValue
                        color: Theme.secondary
                        radius: 10
                        anchors.bottom: parent.bottom
                    }

                    // Interaction
                    MouseArea {
                        anchors.fill: parent
                        onPositionChanged: (mouse) => {
                            let rawValue = 1.0 - (mouse.y / height);
                            let clampedValue = Math.max(0, Math.min(1, rawValue));
                            hudWindow.setBrightness(clampedValue);
                        }
                        onPressed: showHUD()
                    }
                }
            }
        }
    }

    // Initialize on startup
    Component.onCompleted: {
        getVolumeProc.running = true;
        getBrightnessProc.running = true;
    }
}
