import QtQuick
import QtQuick.Layouts
import ".."

// Month grid for the current month, today highlighted. Local-only, no source.
Item {
    id: w
    readonly property bool relevant: true

    property var today: new Date()
    Timer { interval: 60000; running: true; repeat: true; onTriggered: w.today = new Date() }

    readonly property bool sundayFirst: WidgetsConfig.setting("calendar", "weekStart") === "sun"
    readonly property int year: today.getFullYear()
    readonly property int month: today.getMonth()
    // JS getDay(): 0=Sun. Column of the 1st depends on the week-start setting.
    readonly property int firstCol: sundayFirst
        ? new Date(year, month, 1).getDay()
        : (new Date(year, month, 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

    ColumnLayout {
        anchors.fill: parent
        spacing: 4
        Text {
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(w.today, "MMMM yyyy")
            color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 15; font.bold: true
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 7; rowSpacing: 2; columnSpacing: 2
            Repeater {
                model: w.sundayFirst ? ["S", "M", "T", "W", "T", "F", "S"]
                                     : ["M", "T", "W", "T", "F", "S", "S"]
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                    text: modelData; color: Theme.surfaceText; opacity: 0.5
                    font.family: Theme.fontFamily; font.pixelSize: 11
                }
            }
            Repeater {
                model: w.firstCol + w.daysInMonth
                delegate: Item {
                    required property int index
                    readonly property int day: index - w.firstCol + 1
                    readonly property bool isToday: day === w.today.getDate()
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    Rectangle {
                        visible: parent.isToday
                        anchors.centerIn: parent
                        width: 20; height: 20; radius: 10; color: Theme.primary
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: parent.day >= 1
                        text: parent.day >= 1 ? parent.day : ""
                        color: parent.isToday ? Theme.surface : Theme.surfaceText
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }
            }
        }
    }
}
