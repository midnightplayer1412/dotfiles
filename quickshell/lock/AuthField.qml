import QtQuick
import QtQuick.Controls
import ".."

// Password input. Live when `context` is set; static when null (preview).
Column {
    id: auth

    property var context: null          // LockContext or null (preview)
    property bool hideInput: false      // fully hide vs dots
    property bool preview: context === null

    readonly property bool busy: context ? context.authenticating : false
    readonly property string errorMessage: context ? context.errorMessage : ""
    readonly property int attempts: context ? context.attempts : 0

    spacing: 8
    width: 320

    signal submitted(string password)

    function _submit() {
        if (auth.preview || auth.busy) return;
        if (field.text.length === 0) return;   // skip empty submits (no wasted PAM round-trip / attempt bump)
        auth.submitted(field.text);
        if (auth.context) auth.context.submit(field.text);
        field.text = "";
    }

    // Shake on failure: when attempts increments, run the animation.
    onAttemptsChanged: if (auth.attempts > 0) shake.restart()

    Item {
        width: parent.width
        height: 44

        Rectangle {
            id: box
            anchors.fill: parent
            radius: 22
            color: "#1a1a1aee"
            border.width: 2

            // Plain property the pulse animation drives. border.color reads it
            // only while authenticating, so the declarative error/focus logic is
            // preserved (animating border.color directly would clobber its binding).
            property color pulseColor: "#88ffffff"
            border.color: auth.busy ? pulseColor
                : (auth.errorMessage.length > 0 ? Theme.error
                   : (field.activeFocus ? Theme.primary : "#88ffffff"))

            // Pulse the ring while authenticating.
            SequentialAnimation {
                running: auth.busy
                loops: Animation.Infinite
                ColorAnimation { target: box; property: "pulseColor"; to: Theme.primary; duration: 500 }
                ColorAnimation { target: box; property: "pulseColor"; to: "#88ffffff"; duration: 500 }
            }

            TextField {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                verticalAlignment: TextInput.AlignVCenter
                echoMode: auth.hideInput ? TextInput.NoEcho : TextInput.Password
                passwordCharacter: "•"
                enabled: !auth.preview && !auth.busy
                color: "white"
                font.family: Theme.fontFamily
                font.pixelSize: 16
                background: null
                focus: !auth.preview
                // Grab keyboard focus as soon as the live field appears so the
                // user can type immediately (on the real lock surface, and to fix
                // the floating auth-test window not auto-focusing).
                Component.onCompleted: if (!auth.preview) field.forceActiveFocus()
                // In preview, reflect hideInput: show sample dots normally, or
                // nothing when "hide input entirely" is on, so the toggle is visible.
                placeholderText: auth.preview ? (auth.hideInput ? "no echo" : "Password") : ""
                placeholderTextColor: "#88ffffff"
                text: auth.preview ? (auth.hideInput ? "" : "••••••") : ""
                onAccepted: auth._submit()
            }
        }

        transform: Translate { id: shakeT; x: 0 }
        SequentialAnimation {
            id: shake
            NumberAnimation { target: shakeT; property: "x"; to: 12;  duration: 50 }
            NumberAnimation { target: shakeT; property: "x"; to: -12; duration: 50 }
            NumberAnimation { target: shakeT; property: "x"; to: 8;   duration: 50 }
            NumberAnimation { target: shakeT; property: "x"; to: -8;  duration: 50 }
            NumberAnimation { target: shakeT; property: "x"; to: 0;   duration: 50 }
        }
    }

    // Fail text + attempt count.
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: auth.errorMessage.length > 0
        text: auth.errorMessage + (auth.attempts > 1 ? "  (" + auth.attempts + ")" : "")
        color: Theme.error
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.bold: true
    }
}
