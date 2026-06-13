pragma Singleton

import Quickshell
import Quickshell.Services.Pam
import QtQuick

// PAM auth state shared by all lock surfaces. AuthField calls submit(); the lock
// root connects to unlocked().
Singleton {
    id: ctx

    property bool authenticating: false
    property string errorMessage: ""
    property int attempts: 0

    property string _pending: ""

    signal unlocked()

    function submit(password) {
        if (authenticating) return;
        errorMessage = "";
        ctx._pending = password;
        authenticating = true;
        pam.start();
    }

    PamContext {
        id: pam
        config: "login"     // /etc/pam.d/login

        // pamMessage fires for each PAM conversation step (the documented signal).
        // When PAM is waiting for input (responseRequired), answer with the password.
        onPamMessage: {
            if (pam.responseRequired) pam.respond(ctx._pending);
        }

        onCompleted: (result) => {
            ctx.authenticating = false;
            ctx._pending = "";
            if (result === PamResult.Success) {
                ctx.unlocked();
            } else {
                ctx.attempts += 1;
                ctx.errorMessage = (result === PamResult.MaxTries)
                    ? "Too many attempts" : "Incorrect password";
            }
        }
    }
}
