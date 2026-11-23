// SPDX-License-Identifier: GPL-3.0-or-later
//@ pragma IconTheme breeze
// Oblio's login screen: a greetd greeter, run by greetd inside a minimal Hyprland
// (/etc/greetd/oblio-hyprland.lua). Installed to /usr/share/oblio/greeter.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

ShellRoot {
    id: root

    readonly property color accent: "#dc2b2f"
    property var users: []          // [{ name, display }]
    property var sessions: []       // [{ id, name, exec, desktops }]
    property int userIndex: 0
    property int sessionIndex: 0
    property bool busy: false
    property string message: ""
    property string password: ""
    property bool rejected: false   // greetd also reports an error while tearing down a failed attempt

    readonly property var user: users[userIndex] ?? null
    readonly property var session: sessions[sessionIndex] ?? null

    signal failed()

    function login() {
        if (!user || !session || busy) return
        busy = true
        rejected = false
        message = ""
        if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession()
        Greetd.createSession(user.name)
    }

    function pickDefaults() {
        const u = users.findIndex(u => u.name === state.lastUser)
        if (u >= 0) userIndex = u
        const s = sessions.findIndex(s => s.id === state.lastSession)
        if (s >= 0) sessionIndex = s
        else {
            const h = sessions.findIndex(s => s.id === "hyprland")
            if (h >= 0) sessionIndex = h
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(root.password)
                root.password = ""
            } else if (message) {
                root.message = message
            }
        }

        function onAuthFailure(message) {
            root.rejected = true
            root.busy = false
            root.password = ""
            root.message = "Wrong password"
            root.failed()
        }

        function onError(error) {
            if (root.rejected) return
            root.busy = false
            root.message = error
            root.failed()
        }

        function onReadyToLaunch() {
            state.lastUser = root.user.name
            state.lastSession = root.session.id
            stateFile.writeAdapter()
            const s = root.session
            Greetd.launch(["/bin/sh", "-c", s.exec], [
                "XDG_SESSION_TYPE=wayland",
                "XDG_SESSION_DESKTOP=" + s.id,
                "XDG_CURRENT_DESKTOP=" + s.desktops,
            ])
        }
    }

    // last user and session, in a folder the greeter user owns
    FileView {
        id: stateFile
        path: "/var/lib/oblio-greeter/state.json"
        onLoaded: root.pickDefaults()
        onLoadFailed: root.pickDefaults()

        JsonAdapter {
            id: state
            property string lastUser
            property string lastSession
        }
    }

    // people: regular accounts with a login shell
    FileView {
        path: "/etc/passwd"
        onLoaded: {
            const list = []
            for (const line of text().split("\n")) {
                const f = line.split(":")
                const uid = parseInt(f[2])
                if (f.length < 7 || uid < 1000 || uid >= 60000 || /(nologin|false)$/.test(f[6])) continue
                list.push({ name: f[0], display: f[4].split(",")[0] || f[0] })
            }
            root.users = list
            root.pickDefaults()
        }
    }

    // sessions: every Wayland session installed (Hyprland, Plasma, ...) whose
    // program exists (TryExec, or the first word of Exec)
    Process {
        running: true
        command: ["sh", "-c", `
            for f in /usr/share/wayland-sessions/*.desktop; do
                t=$(sed -n 's/^TryExec=//p' "$f" | head -n1)
                e=$(sed -n 's/^Exec=//p' "$f" | head -n1)
                command -v "\${t:-\${e%% *}}" >/dev/null 2>&1 || continue
                grep -H -E '^(Name|Exec|DesktopNames|NoDisplay|Hidden)=' "$f"
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const byFile = {}
                for (const line of text.split("\n")) {
                    const m = line.match(/^(.*?\/([^\/]+)\.desktop):(\w+)=(.*)$/)
                    if (!m) continue
                    if (!byFile[m[1]]) byFile[m[1]] = { id: m[2] }
                    const e = byFile[m[1]]
                    e[m[3]] = m[4]
                }
                root.sessions = Object.values(byFile)
                    .filter(e => e.Exec && e.NoDisplay !== "true" && e.Hidden !== "true")
                    .map(e => ({
                        id: e.id,
                        name: e.Name || e.id,
                        exec: e.Exec.replace(/ %[a-zA-Z]/g, ""),
                        desktops: (e.DesktopNames || e.id).replace(/;$/, "").replace(/;/g, ":"),
                    }))
                    .sort((a, b) => a.name.localeCompare(b.name))
                root.pickDefaults()
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            readonly property bool main: modelData === Quickshell.screens[0]

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: main ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "oblio-greeter"
            color: "#0c0c0f"

            Backdrop { anchors.fill: parent; accent: root.accent }

            Loader {
                anchors.fill: parent
                active: win.main
                sourceComponent: Login { greeter: root }
            }
        }
    }
}
