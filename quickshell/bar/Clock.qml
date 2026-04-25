import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".."
import "../calendar" as Calendar

ColumnLayout {
    id: root
    spacing: 2

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: -1
        onClicked: {
            const monitorName = Hyprland.focusedMonitor?.name ?? "";
            for (const s of Quickshell.screens) {
                if (s.name === monitorName) {
                    Calendar.CalendarState.toggle(s);
                    return;
                }
            }
            if (Quickshell.screens.length > 0) {
                Calendar.CalendarState.toggle(Quickshell.screens[0]);
            }
        }
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
        color: Theme.surfaceText
    }
}
