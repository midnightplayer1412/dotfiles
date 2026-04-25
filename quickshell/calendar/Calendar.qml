import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

PanelWindow {
    id: root

    required property var screen

    anchors {
        left: true
        top: true
        bottom: true
    }

    margins.left: Theme.barWidth + Theme.barMargin + 8

    implicitWidth: 300

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: CalendarState.close()
    }

    // Currently displayed month
    property date today: new Date()
    property int displayYear: today.getFullYear()
    property int displayMonth: today.getMonth() // 0-11

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var weekdayNames: ["S", "M", "T", "W", "T", "F", "S"]

    function buildCells(year, month) {
        const firstDay = new Date(year, month, 1).getDay();
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const cells = [];
        for (let i = 0; i < firstDay; i++) cells.push(0);
        for (let d = 1; d <= daysInMonth; d++) cells.push(d);
        while (cells.length < 42) cells.push(0);
        return cells;
    }

    readonly property var cells: buildCells(displayYear, displayMonth)

    function prevMonth() {
        if (displayMonth === 0) {
            displayMonth = 11;
            displayYear -= 1;
        } else {
            displayMonth -= 1;
        }
    }

    function nextMonth() {
        if (displayMonth === 11) {
            displayMonth = 0;
            displayYear += 1;
        } else {
            displayMonth += 1;
        }
    }

    Rectangle {
        id: panel

        width: parent.width - 8
        height: 340
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        color: Theme.surface
        radius: 16
        border.color: Theme.outline
        border.width: 1
        clip: true

        // entry animation
        opacity: 0
        x: -20
        Component.onCompleted: entryAnim.start()
        ParallelAnimation {
            id: entryAnim
            NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "x"; from: -20; to: 0; duration: 180; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            // Header: ◀ Month Year ▶
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    color: prevMouse.containsMouse ? Theme.surfaceContainer : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "◀"
                        color: Theme.surfaceText
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.prevMonth()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.monthNames[root.displayMonth] + " " + root.displayYear
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    color: nextMouse.containsMouse ? Theme.surfaceContainer : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "▶"
                        color: Theme.surfaceText
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextMonth()
                    }
                }
            }

            // Weekday headers
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 0
                columnSpacing: 0

                Repeater {
                    model: root.weekdayNames

                    delegate: Item {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: Theme.outline
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }
            }

            // Day grid
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: root.cells

                    delegate: Item {
                        id: cell
                        required property int modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        readonly property bool isEmpty: modelData === 0
                        readonly property bool isToday: !isEmpty
                            && modelData === root.today.getDate()
                            && root.displayMonth === root.today.getMonth()
                            && root.displayYear === root.today.getFullYear()

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) - 2
                            height: width
                            radius: width / 2
                            color: cell.isToday ? Theme.primary : "transparent"
                            visible: cell.isToday
                        }

                        Text {
                            anchors.centerIn: parent
                            text: cell.isEmpty ? "" : cell.modelData
                            color: cell.isToday ? Theme.primaryText : Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: cell.isToday
                        }
                    }
                }
            }
        }
    }
}
