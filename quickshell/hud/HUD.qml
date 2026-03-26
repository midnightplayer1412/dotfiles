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
            if (match) {
                var newVolume = parseFloat(match[1]);
                if (Math.abs(newVolume - hudWindow.previousVolume) > 0.01) {
                    hudWindow.previousVolume = newVolume;
                    hudWindow.volumeValue = newVolume;
                    showHUD("volume");
                } else {
                    hudWindow.volumeValue = newVolume;
                }
            }
        }
    }

    Process {
        id: setVolumeProc
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
                    showHUD("brightness");
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
            getBrightnessProc.running = true;
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

    // Current display values
    property real displayValue: HudState.activeIndicator === "volume" ? volumeValue : brightnessValue
    property string displayIcon: HudState.activeIndicator === "volume" ? "󰕾" : "󰃟"
    property string displayPercent: Math.round(displayValue * 100) + "%"
    property color indicatorColor: HudState.activeIndicator === "volume" ? Theme.primary : Theme.secondary

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
            anchors.leftMargin: 20
            anchors.rightMargin: 20
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

            // Progress bar
            Rectangle {
                id: track
                width: parent.width - 24 - 46 - 28  // icon - percent text - spacing
                height: 8
                radius: 4
                color: Theme.surfaceContainer
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: parent.width * hudWindow.displayValue
                    height: parent.height
                    radius: 4
                    color: hudWindow.indicatorColor

                    Behavior on width {
                        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                    }
                }

                // Click to set value
                MouseArea {
                    anchors.fill: parent
                    onPositionChanged: (mouse) => {
                        let value = Math.max(0, Math.min(1, mouse.x / width));
                        if (HudState.activeIndicator === "volume")
                            hudWindow.setVolume(value);
                        else
                            hudWindow.setBrightness(value);
                    }
                    onPressed: (mouse) => {
                        let value = Math.max(0, Math.min(1, mouse.x / width));
                        if (HudState.activeIndicator === "volume")
                            hudWindow.setVolume(value);
                        else
                            hudWindow.setBrightness(value);
                    }
                }
            }

            // Percentage
            Text {
                text: hudWindow.displayPercent
                font.family: "MonaspiceKr NF"
                font.pixelSize: 14
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
                width: 46
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Component.onCompleted: {
        getVolumeProc.running = true;
        getBrightnessProc.running = true;
    }
}
