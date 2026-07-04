pragma Singleton
import Quickshell
import QtQuick

// The single catalog. To add a widget: add a descriptor, an `ids` entry, a
// Component, and a componentFor() case (and the file + qmldir line).
Singleton {
    id: reg

    readonly property var descriptors: ({
        "clock": { label: "Clock", w: 200, h: 96, desktop: { stack: "left", order: 0 }, dashboard: { span: 1 } }
    })

    readonly property var ids: ["clock"]

    Component { id: cClock; ClockWidget {} }

    function componentFor(id) {
        switch (id) {
            case "clock": return cClock;
        }
        return null;
    }
}
