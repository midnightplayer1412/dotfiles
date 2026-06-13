import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../lock" as Lock
import "../../wallpaper" as Wp
import "../../ui" as Ui
import "../.."

// Lock Screen settings: live preview (left) + scrollable grouped controls (right).
// Uses the repo's proven Flickable + ColumnLayout pattern (see audio/AudioPanel.qml)
// and an anchor-based split so width distribution is unambiguous.
Item {
    id: pane

    // ── Inline helpers ────────────────────────────────────────────────
    component SectionHeader: Text {
        Layout.topMargin: 6
        color: Theme.primary
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.bold: true
    }

    component ToggleRow: RowLayout {
        id: trow
        property string label: ""
        property bool checked: false
        signal toggled(bool v)
        Layout.fillWidth: true
        spacing: 12
        Text {
            Layout.fillWidth: true
            text: trow.label
            color: Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
        Ui.Toggle {
            checked: trow.checked
            onToggled: (v) => trow.toggled(v)
        }
    }

    // ── Live preview (scaled LockView), left ──────────────────────────
    Rectangle {
        id: preview
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 420
        radius: 14
        color: "black"
        clip: true
        border.color: Theme.outline
        border.width: 1

        Item {
            id: canvas
            width: 1280
            height: 800
            anchors.centerIn: parent
            scale: Math.min(parent.width / width, parent.height / height)

            Lock.LockView {
                anchors.fill: parent
                preview: true
            }
        }
        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            text: "Preview"
            color: "#aaffffff"
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }

    // ── Controls, right (scrollable) ──────────────────────────────────
    Flickable {
        id: ctrl
        anchors.left: preview.right
        anchors.leftMargin: 20
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 14

            // ── Components ──
            SectionHeader { text: "Components" }
            ToggleRow {
                label: "Media player"; checked: Lock.LockConfig.showMedia
                onToggled: (v) => { Lock.LockConfig.showMedia = v; Lock.LockConfig.save(); }
            }
            ToggleRow {
                label: "Battery"; checked: Lock.LockConfig.showBattery
                onToggled: (v) => { Lock.LockConfig.showBattery = v; Lock.LockConfig.save(); }
            }
            ToggleRow {
                label: "User identity"; checked: Lock.LockConfig.showIdentity
                onToggled: (v) => { Lock.LockConfig.showIdentity = v; Lock.LockConfig.save(); }
            }
            ToggleRow {
                label: "Date"; checked: Lock.LockConfig.showDate
                onToggled: (v) => { Lock.LockConfig.showDate = v; Lock.LockConfig.save(); }
            }

            // ── Clock & Date ──
            SectionHeader { text: "Clock & Date" }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Time format"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                ComboBox {
                    model: [ "24-hour", "12-hour" ]
                    currentIndex: Lock.LockConfig.clockFormat === "12h" ? 1 : 0
                    onActivated: {
                        Lock.LockConfig.clockFormat = currentIndex === 1 ? "12h" : "24h";
                        Lock.LockConfig.save();
                    }
                }
            }
            ToggleRow {
                label: "Show seconds"; checked: Lock.LockConfig.showSeconds
                onToggled: (v) => { Lock.LockConfig.showSeconds = v; Lock.LockConfig.save(); }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Date format"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                ComboBox {
                    id: dateCombo
                    model: [ "dddd, MMMM d", "ddd MMM d", "yyyy-MM-dd", "MMMM d, yyyy" ]
                    // Live binding so the combo re-syncs after hot-reload / external edits.
                    currentIndex: {
                        const i = model.indexOf(Lock.LockConfig.dateFormat);
                        return i >= 0 ? i : 0;
                    }
                    onActivated: {
                        Lock.LockConfig.dateFormat = model[currentIndex];
                        Lock.LockConfig.save();
                    }
                }
            }

            // ── Behavior ──
            SectionHeader { text: "Behavior" }
            ToggleRow {
                label: "Hide input entirely (no dots)"; checked: Lock.LockConfig.hideInput
                onToggled: (v) => { Lock.LockConfig.hideInput = v; Lock.LockConfig.save(); }
            }

            // ── Background (last — the wallpaper grid is the long one) ──
            SectionHeader { text: "Background" }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "Source"; color: Theme.surfaceText
                    font.family: Theme.fontFamily; font.pixelSize: 13
                    Layout.fillWidth: true
                }
                ComboBox {
                    id: srcCombo
                    model: [ "Lock image", "Current desktop wallpaper" ]
                    currentIndex: Lock.LockConfig.wallpaperSource === "current-desktop" ? 1 : 0
                    onActivated: {
                        Lock.LockConfig.wallpaperSource = currentIndex === 1 ? "current-desktop" : "lock-image";
                        Lock.LockConfig.save();
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Blur"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.preferredWidth: 60 }
                Ui.Slider {
                    Layout.fillWidth: true
                    from: 0; to: 10; stepSize: 1
                    value: Lock.LockConfig.blur
                    onMoved: (v) => Lock.LockConfig.blur = v
                    onReleased: Lock.LockConfig.save()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Dim"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.preferredWidth: 60 }
                Ui.Slider {
                    Layout.fillWidth: true
                    from: 0; to: 1; stepSize: 0.05
                    value: Lock.LockConfig.dim
                    onMoved: (v) => Lock.LockConfig.dim = v
                    onReleased: Lock.LockConfig.save()
                }
            }
            // Wallpaper grid — only for "lock image"; lazy-loaded thumbnails.
            Text {
                text: "Image"; color: Theme.surfaceText
                font.family: Theme.fontFamily; font.pixelSize: 13
                visible: Lock.LockConfig.wallpaperSource === "lock-image"
            }
            GridLayout {
                Layout.fillWidth: true
                visible: Lock.LockConfig.wallpaperSource === "lock-image"
                columns: 4
                columnSpacing: 8
                rowSpacing: 8
                Repeater {
                    model: Wp.WallpaperService.wallpapers
                    delegate: Rectangle {
                        id: thumb
                        required property var modelData
                        Layout.preferredWidth: 92
                        Layout.preferredHeight: 58
                        radius: 8
                        clip: true
                        color: Theme.surfaceContainer
                        border.width: Lock.LockConfig.wallpaperPath === modelData.path ? 2 : 0
                        border.color: Theme.primary

                        // Lazy load: only fetch the image once the thumb scrolls
                        // near the viewport, and keep it once loaded (no reload flicker).
                        property bool loaded: false
                        readonly property bool inView: {
                            const top = thumb.mapToItem(content, 0, 0).y;
                            return (top + height) > (ctrl.contentY - 600)
                                && top < (ctrl.contentY + ctrl.height + 600);
                        }
                        onInViewChanged: if (inView) loaded = true

                        Image {
                            anchors.fill: parent
                            source: thumb.loaded ? ("file://" + thumb.modelData.path) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: status === Image.Ready
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Lock.LockConfig.wallpaperPath = thumb.modelData.path;
                                Lock.LockConfig.save();
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }   // bottom spacer
        }
    }
}
