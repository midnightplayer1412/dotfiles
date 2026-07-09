pragma Singleton
import Quickshell
import QtQuick

// The single catalog. To add a widget: add a descriptor, an `ids` entry, a
// Component, and a componentFor() case (and the file + qmldir line).
Singleton {
    id: reg

    // A descriptor's optional `settings` array declares the widget's own options.
    // Each field: { key, label, type: "toggle"|"enum"|"text"|"number", default,
    // options?: [{value,label}] }. The Settings → Widgets gear renders them
    // generically; the widget reads values via WidgetsConfig.setting(id, key).
    readonly property var descriptors: ({
        "clock":      { label: "Clock",    w: 200, h: 96,  desktop: { stack: "left",  order: 0 }, dashboard: { span: 1 },
            settings: [
                { key: "format24",    label: "24-hour",      type: "toggle", default: true },
                { key: "showSeconds", label: "Show seconds", type: "toggle", default: false },
                { key: "showDate",    label: "Show date",    type: "toggle", default: true }
            ] },
        "calendar":   { label: "Calendar", w: 236, h: 285, desktop: { stack: "left",  order: 1 }, dashboard: { span: 1 },
            settings: [
                { key: "weekStart", label: "Week starts", type: "enum", default: "mon",
                  options: [{ value: "mon", label: "Mon" }, { value: "sun", label: "Sun" }] }
            ] },
        "sysmonitor": { label: "System",   w: 210, h: 110, desktop: { stack: "left",  order: 2 }, dashboard: { span: 1 },
            settings: [
                { key: "showCpu", label: "Show CPU", type: "toggle", default: true },
                { key: "showRam", label: "Show RAM", type: "toggle", default: true }
            ] },
        "weather":    { label: "Weather",  w: 210, h: 150, desktop: { stack: "right", order: 0 }, dashboard: { span: 1 },
            settings: [
                { key: "units", label: "Units", type: "enum", default: "c",
                  options: [{ value: "c", label: "°C" }, { value: "f", label: "°F" }] },
                { key: "lat",   label: "Latitude",  type: "number", default: 0 },
                { key: "lon",   label: "Longitude", type: "number", default: 0 },
                { key: "label", label: "Label",     type: "text",   default: "" }
            ] },
        "media":      { label: "Media",    w: 320, h: 96,  desktop: { stack: "right", order: 1 }, dashboard: { span: 2 } }
    })

    readonly property var ids: ["clock", "calendar", "sysmonitor", "weather", "media"]

    Component { id: cClock;      ClockWidget      {} }
    Component { id: cCalendar;   CalendarWidget   {} }
    Component { id: cSysmonitor; SysMonitorWidget {} }
    Component { id: cWeather;    WeatherWidget    {} }
    Component { id: cMedia;      MediaWidget      {} }

    function componentFor(id) {
        switch (id) {
            case "clock":      return cClock;
            case "calendar":   return cCalendar;
            case "sysmonitor": return cSysmonitor;
            case "weather":    return cWeather;
            case "media":      return cMedia;
        }
        return null;
    }
}
