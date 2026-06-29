pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Keyboard Aura lighting config, persisted to
// ~/.config/quickshell/keyboard-config.json and edited from Settings →
// Appearance. The keyboard backlight follows the Matugen theme: in "theme"
// colorMode it uses the palette primary; in "custom" mode a fixed seed hex.
//
// apply() funnels through hypr/scripts/apply-keyboard.sh — the single owner of
// the asusctl command. That script is also called at the end of apply-theme.sh,
// so the keyboard re-tints automatically on every wallpaper / theme change.
// We call it directly here so an effect/color tweak doesn't need a full Matugen
// re-run. Disabled by default (opt-in; safe on machines with no ASUS keyboard).
Singleton {
    id: cfg

    property alias enabled: adapter.enabled       // master on/off
    property alias effect: adapter.effect         // see `effects` below
    property alias colorMode: adapter.colorMode   // "theme" | "custom"
    property alias color: adapter.color           // custom seed hex "#rrggbb"
    property alias speed: adapter.speed           // "low" | "med" | "high" (breathe)
    property alias brightness: adapter.brightness // "off" | "low" | "med" | "high"

    // Effects this board's firmware actually supports. asusctl's CLI advertises
    // more (highlight/laser/ripple/comet/flash), but the FX507ZU4 single-zone
    // keyboard returns NotSupported for those — so only the three that work.
    readonly property var effects: ["static", "breathe", "pulse"]

    // Curated accent seeds for the custom-color swatch row (mirrors ThemeConfig).
    readonly property var presets: [
        "#33ccff", "#00ff99", "#40c4ff", "#7c4dff",
        "#ff5c8a", "#ff6e40", "#ffd740", "#69f0ae"
    ]

    // Discrete levels asusctl accepts. Brightness applies to any effect; speed
    // only affects breathe (static/pulse ignore it).
    readonly property var brightnessLevels: ["off", "low", "med", "high"]
    readonly property var speeds: ["low", "med", "high"]

    function save() { view.writeAdapter(); }

    function apply() {
        applyProc.command = [
            Quickshell.env("HOME") + "/.config/hypr/scripts/apply-keyboard.sh"
        ];
        applyProc.running = true;
    }

    function setEnabled(v) { cfg.enabled = v; save(); apply(); }
    function setEffect(e)  { cfg.effect = e; save(); apply(); }
    function setColorMode(m) { cfg.colorMode = m; save(); apply(); }
    function setColor(c)   { cfg.color = c; cfg.colorMode = "custom"; save(); apply(); }
    function setSpeed(s)   { cfg.speed = s; save(); apply(); }
    function setBrightness(b) { cfg.brightness = b; save(); apply(); }

    Process { id: applyProc }

    FileView {
        id: view
        path: Quickshell.env("HOME") + "/.config/quickshell/keyboard-config.json"
        watchChanges: true
        onLoadFailed: (error) => view.writeAdapter()

        JsonAdapter {
            id: adapter
            property bool enabled: false
            property string effect: "static"
            property string colorMode: "theme"
            property string color: "#33ccff"
            property string speed: "med"
            property string brightness: "high"
        }
    }
}
