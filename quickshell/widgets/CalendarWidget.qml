import QtQuick
import QtQuick.Layouts
import ".."
import "../ui" as Ui

// Month grid for the current month, today highlighted. Local-only, no source.
// Today's marker follows the active widget style (filled / gradient / ring).
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

    readonly property string preset: Ui.WidgetStyle.preset
    readonly property color todayText: preset === "minimal" ? Theme.surfaceText
                                      : preset === "playful" ? Theme.primaryText
                                      : Theme.surface

    ColumnLayout {
        anchors.fill: parent
        spacing: 4
        // Title. Playful puts the month/year on a gradient band (dark text) to
        // echo the clock tile; other presets show plain accent-colored text.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: title.implicitHeight + (w.preset === "playful" ? 10 : 0)
            color: "transparent"
            radius: 8
            gradient: w.preset === "playful" ? todayGrad : null
            Text {
                id: title
                anchors.centerIn: parent
                text: Qt.formatDate(w.today, "MMMM yyyy")
                color: w.preset === "playful" ? Theme.primaryText : Ui.WidgetStyle.titleColor
                font.family: Theme.fontFamily
                font.pixelSize: 15; font.weight: Ui.WidgetStyle.titleWeight
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 7; rowSpacing: 5; columnSpacing: 4
            Repeater {
                model: w.sundayFirst ? ["S", "M", "T", "W", "T", "F", "S"]
                                     : ["M", "T", "W", "T", "F", "S", "S"]
                // Wrapped in a zero-preferred-width Item (like the day cells) so
                // every column splits the width equally — a bare Text would let
                // each letter's width set an uneven column base.
                delegate: Item {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData; color: Theme.surfaceText; opacity: Ui.WidgetStyle.subOpacity * 0.8
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }
            }
            Repeater {
                model: w.firstCol + w.daysInMonth
                delegate: Item {
                    required property int index
                    readonly property int day: index - w.firstCol + 1
                    readonly property bool isToday: day === w.today.getDate()
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    Rectangle {
                        visible: parent.isToday
                        anchors.centerIn: parent
                        width: 24; height: 24; radius: 12
                        color: w.preset === "minimal" ? "transparent"
                             : Ui.WidgetStyle.useGradient ? "transparent" : Ui.WidgetStyle.accent
                        border.width: w.preset === "minimal" ? 1.5 : 0
                        border.color: Theme.surfaceText
                        gradient: Ui.WidgetStyle.useGradient && w.preset !== "minimal" ? todayGrad : null
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: parent.day >= 1
                        text: parent.day >= 1 ? parent.day : ""
                        color: parent.isToday ? w.todayText : Theme.surfaceText
                        font.family: Theme.fontFamily; font.pixelSize: 15
                    }
                }
            }
        }
    }

    Gradient {
        id: todayGrad
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Ui.WidgetStyle.gradA }
        GradientStop { position: 1; color: Ui.WidgetStyle.gradB }
    }
}
