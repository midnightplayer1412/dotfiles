import QtQuick
import ".."
import "../ui" as Ui

// Three staggered pulsing dots, shown in the active-line slot during instrumental
// passages of a synced song (intro, breaks, outro — see LyricsService.instrumental).
// Signals "the music is playing, there just aren't words right now" instead of
// leaving a blank strip that reads as broken.
Row {
    id: dots
    property color dotColor: Ui.WidgetStyle.accent
    property real dotSize: 10
    spacing: dotSize * 0.9

    Repeater {
        model: 3
        delegate: Rectangle {
            required property int index
            width: dots.dotSize
            height: dots.dotSize
            radius: dots.dotSize / 2
            color: dots.dotColor
            opacity: 0.3

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                PauseAnimation { duration: index * 180 }
                NumberAnimation { to: 1.0; duration: 300; easing.type: Easing.OutQuad }
                NumberAnimation { to: 0.3; duration: 500; easing.type: Easing.InQuad }
                PauseAnimation { duration: (2 - index) * 180 }
            }
        }
    }
}
