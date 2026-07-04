pragma Singleton
import Quickshell
import QtQuick

// The single catalog. To add a widget: add a descriptor, an `ids` entry, a
// Component, and a componentFor() case (and the file + qmldir line).
Singleton {
    id: reg

    readonly property var descriptors: ({
        "clock":      { label: "Clock",    w: 200, h: 96,  desktop: { stack: "left",  order: 0 }, dashboard: { span: 1 } },
        "calendar":   { label: "Calendar", w: 236, h: 250, desktop: { stack: "left",  order: 1 }, dashboard: { span: 1 } },
        "sysmonitor": { label: "System",   w: 210, h: 110, desktop: { stack: "left",  order: 2 }, dashboard: { span: 1 } },
        "weather":    { label: "Weather",  w: 210, h: 150, desktop: { stack: "right", order: 0 }, dashboard: { span: 1 } },
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
