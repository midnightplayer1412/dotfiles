import QtQuick
import QtQuick.Layouts
import "../ui" as Ui
import ".."
import "../audio"

Ui.SelectableRow {
    id: row

    required property var modelData

    readonly property bool isDefault: AudioService.defaultSink === modelData.name

    readonly property string glyph: {
        switch (modelData.kind) {
        case "bluetooth": return "\u{F0AB7}";   // bluetooth-audio
        case "hdmi":      return "\u{F0379}";   // monitor
        case "analog":
            if (modelData.portLabel === "Headphones") return "\u{F02CB}"; // headphones
            return "\u{F04C3}";                                            // speaker
        }
        return "\u{F057E}";                                                 // volume-high
    }

    readonly property string subtext: {
        if (modelData.kind === "bluetooth") return "Bluetooth";
        if (modelData.kind === "hdmi") return "HDMI";
        if (modelData.portLabel) return modelData.portLabel;
        return "";
    }

    implicitHeight: 48
    radius: 10
    selected: row.isDefault
    interactive: !row.isDefault
    selectedColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
    onClicked: AudioService.setDefault(row.modelData.name)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Text {
            text: row.glyph
            font.family: "Monaspace Argon NF"
            font.pixelSize: 20
            color: row.isDefault ? Theme.primary : Theme.surfaceText
            Layout.preferredWidth: 24
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: row.modelData.description
                color: Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            Text {
                visible: row.subtext.length > 0
                text: row.subtext
                color: Theme.outline
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        Text {
            visible: row.isDefault
            text: "Active"
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.bold: true
        }
    }
}
