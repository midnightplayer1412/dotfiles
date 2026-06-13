import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import ".."

// Battery glyph + percentage. Hidden when no battery is present (desktops).
RowLayout {
    id: pill

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev && dev.isLaptopBattery && dev.isPresent
    readonly property real pct: present ? dev.percentage : 0
    readonly property bool charging:
        present && (dev.state === UPowerDeviceState.Charging
                 || dev.state === UPowerDeviceState.FullyCharged)

    visible: present
    spacing: 6

    // Level-aware nf-md battery glyph (verified codepoints).
    readonly property string glyph: {
        if (charging) return "\u{F0084}";          // battery-charging
        const p = pct;
        if (p >= 0.95) return "\u{F0079}";          // battery (full)
        if (p >= 0.80) return "\u{F0082}";          // battery-80
        if (p >= 0.60) return "\u{F0080}";          // battery-60
        if (p >= 0.40) return "\u{F007E}";          // battery-40
        if (p >= 0.20) return "\u{F007C}";          // battery-20
        return "\u{F007A}";                         // battery-alert (low)
    }

    Text {
        text: pill.glyph
        color: "white"
        font.family: Theme.glyphFont
        font.pixelSize: 18
    }
    Text {
        text: Math.round(pill.pct * 100) + "%"
        color: "white"
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }
}
