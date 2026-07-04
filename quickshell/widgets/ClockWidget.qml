import QtQuick
import ".."

// Presentational only: renders time/date, declares relevance. Knows nothing of
// its position or host.
Item {
    id: w
    readonly property bool relevant: true

    property var now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: w.now = new Date() }

    Column {
        anchors.centerIn: parent
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(w.now, "hh:mm")
            color: Theme.primary; font.family: Theme.fontFamily
            font.pixelSize: 38; font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(w.now, "ddd, d MMM")
            color: Theme.surfaceText; opacity: 0.8
            font.family: Theme.fontFamily; font.pixelSize: 14
        }
    }
}
