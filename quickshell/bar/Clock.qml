import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 2

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "HH")
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.primary
    }

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 4; height: 4; radius: 2
        color: Theme.primary
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "mm")
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.primary
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 8
        text: Qt.formatDateTime(clock.date, "ddd")
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.outline
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "dd")
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMedium
        font.bold: true
        color: Theme.onSurface
    }
}
