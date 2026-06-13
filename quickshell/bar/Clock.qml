import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".."
import "../calendar" as Calendar

// Bar clock. Vertical bar: stacked HH / mm / weekday / day. Horizontal bar:
// compact "HH:mm" with weekday+day beside it. Click toggles the calendar.
Item {
    id: root
    property bool horizontal: false

    implicitWidth: (horizontal ? rowLay : colLay).implicitWidth
    implicitHeight: (horizontal ? rowLay : colLay).implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function toggleCalendar() {
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

    // ── Vertical (stacked) layout ──
    ColumnLayout {
        id: colLay
        anchors.centerIn: parent
        visible: !root.horizontal
        spacing: 2

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

    // ── Horizontal (compact) layout ──
    RowLayout {
        id: rowLay
        anchors.centerIn: parent
        visible: root.horizontal
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.bold: true
            color: Theme.primary
        }
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Qt.formatDateTime(clock.date, "ddd dd")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleCalendar()
    }
}
