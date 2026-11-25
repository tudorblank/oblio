// SPDX-License-Identifier: GPL-3.0-or-later
//@ pragma IconTheme breeze
// Oblio's login screen: a greetd greeter, run by greetd inside a minimal Hyprland
// (/etc/greetd/oblio-hyprland.lua). Installed to /usr/share/oblio/greeter.
// Each user's lock screen wallpaper, profile picture and look (light/dark, accent) come from
// /var/lib/oblio-greeter/users/NAME, where their shell copies them (scripts/apply-theme).

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

ShellRoot {
    id: root

    property var users: []          // [{ name, display }]
    property var sessions: []       // [{ id, name, exec, desktops }]
    property int userIndex: 0
    property int sessionIndex: 0
    property bool busy: false
    property string message: ""
    property string password: ""
    property bool rejected: false   // greetd also reports an error while tearing down a failed attempt
    // PAM's first hidden prompt gets the password; anything it asks after that (a one-time code,
    // a new password) is shown in the field and answered on its own
    property bool answered: false
    property string prompt: ""
    property bool promptEcho: false

    readonly property var user: users[userIndex] ?? null
    readonly property var session: sessions[sessionIndex] ?? null
    readonly property string userDir: user ? "/var/lib/oblio-greeter/users/" + user.name : ""

    // the shell's palette (services/Theme.qml), in this user's mode and accent
    readonly property QtObject theme: QtObject {
        readonly property bool dark: look.mode !== "light"
        readonly property color accent: /^#[0-9a-fA-F]{6}$/.test(look.accent) ? look.accent : "#b9e66c"
        readonly property color accentFg: root.luminance(accent) > 0.45 ? "#1a1a1d" : "#ffffff"
        readonly property color accentHover: Qt.lighter(accent, 1.12)
        readonly property color card: dark ? "#b8161619" : "#c8fbfbfc"
        readonly property color popup: dark ? "#f4161619" : "#f8fbfbfc"
        readonly property color field: dark ? "#12ffffff" : "#99ffffff"
        readonly property color hover: dark ? "#14ffffff" : "#0f000000"
        readonly property color hairline: dark ? "#17ffffff" : "#16000000"
        readonly property color border: dark ? "#24ffffff" : "#1f000000"
        readonly property color text: dark ? "#f2f2f5" : "#1c1c21"
        readonly property color subtext: dark ? "#9b9ba5" : "#6a6a74"
        readonly property color danger: dark ? "#ff8a8d" : "#d23a40"
        readonly property color background: dark ? "#141417" : "#e4e4e8"
        readonly property int radius: 22
        readonly property int control: 30
        readonly property string font: "Inter"
        readonly property string iconFont: {
            const all = Qt.fontFamilies()
            return all.includes("Symbols Nerd Font") ? "Symbols Nerd Font" : all.find(f => f.includes("Nerd Font")) ?? ""
        }
    }
    function luminance(c) {
        const f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b)
    }

    signal failed()

    function login() {
        if (!user || !session) return
        if (prompt) {
            Greetd.respond(password)
            password = ""
            prompt = ""
            busy = true
            return
        }
        if (busy) return
        busy = true
        rejected = false
        answered = false
        message = ""
        if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession()
        Greetd.createSession(user.name)
    }

    function reset() {
        busy = false
        prompt = ""
        password = ""
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

    onUserIndexChanged: {
        if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession()
        reset()
        message = ""
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (!responseRequired) {
                if (message) root.message = message
            } else if (!echoResponse && !root.answered) {
                root.answered = true
                Greetd.respond(root.password)
                root.password = ""
            } else {
                root.prompt = message || "Answer"
                root.promptEcho = echoResponse
                root.busy = false
            }
        }

        function onAuthFailure(message) {
            root.rejected = true
            root.reset()
            root.message = "Wrong password"
            root.failed()
        }

        function onError(error) {
            if (root.rejected) return
            root.reset()
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

    // the chosen user's look
    FileView {
        path: root.userDir ? root.userDir + "/look.json" : ""
        onLoadFailed: { look.mode = ""; look.accent = "" }

        JsonAdapter {
            id: look
            property string mode
            property string accent
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
            color: root.theme.background

            Backdrop {
                id: wall
                anchors.fill: parent
                theme: root.theme
                source: root.userDir ? "file://" + root.userDir + "/wallpaper" : ""
            }

            Loader {
                anchors.fill: parent
                active: win.main
                sourceComponent: Login { greeter: root; backdrop: wall }
            }
        }
    }
}
