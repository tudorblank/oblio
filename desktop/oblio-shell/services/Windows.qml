// SPDX-License-Identifier: GPL-3.0-or-later
// The shell's side of Hyprland's windows.lua: every window action the shell asks for goes through
// here, and so does its half of minimize and restore. windows.lua owns the windows, their phases
// and every timing; the shell only draws (dock/Genie.qml) and reports back. Messages from
// windows.lua arrive as numbered lines in $XDG_RUNTIME_DIR/oblio-fx (watched, so they take a
// millisecond, not a process start):
//   leave ADDR X Y W H ACTIVE  put a picture of the window exactly over it; report ready
//   arrive ADDR X Y W H        the window is coming back, invisible, to this place: ready a picture
//                              of it, unseen in the dock icon; report ready
//   go ADDR MS                 fly the picture (into the dock, or out of it into the window's
//                              place) in MS; report done
//   drop ADDR                  the picture goes
// Calls and reports go straight to Hyprland's socket. Reports carry the flight's way (out | in),
// so one about a dropped flight can't finish the next. Rects are in layout coordinates.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property string minimizedWorkspace: "special:minimized"

    signal leaving(string address, rect from, bool active)
    signal arriving(string address, rect to)
    signal going(string address, int duration)
    signal dropped(string address)

    // a toplevel's address as windows.lua takes it
    function address(t) { return t.address.startsWith("0x") ? t.address : "0x" + t.address }
    function isMinimized(t) { return t.workspace !== null && t.workspace.name === minimizedWorkspace }

    function call(fn, arg) { Hyprland.dispatch(`function() oblio.${fn}(${arg}) end`) }
    function list(toplevels) { return "{ " + toplevels.map(t => `"${address(t)}"`).join(", ") + " }" }

    // the dock's left click on a running app; see windows.lua
    function toggleApp(toplevels) { call("toggle_app", list(toplevels)) }
    function focus(t) { call("focus", `"${address(t)}"`) }
    function restore(t) { call("restore", `"${address(t)}"`) }
    function close(toplevels) { call("close", list(toplevels)) }
    // whether the desktop (desktop/DesktopWindow.qml) has the keyboard: a click on the active window
    // then gives it back
    function desktopKeys(on) { call("desktop_keys", on) }

    function ready(address, way) { call("ready", `"${address}", "${way}"`) }
    function done(address, way) { call("done", `"${address}", "${way}"`) }

    // the last message handled; -1 until the file is first read (what's in it then is old)
    property int last: -1

    function read(text) {
        const lines = text.split("\n").map(l => l.split(" ")).filter(f => f.length > 1)
        if (last < 0) {
            last = lines.reduce((m, f) => Math.max(m, parseInt(f[0])), 0)
            return
        }
        for (const f of lines) {
            const seq = parseInt(f[0])
            if (!(seq > last)) continue
            last = seq
            const n = i => parseInt(f[i])
            if (f[1] === "leave") leaving(f[2], Qt.rect(n(3), n(4), n(5), n(6)), f[7] === "true")
            else if (f[1] === "arrive") arriving(f[2], Qt.rect(n(3), n(4), n(5), n(6)))
            else if (f[1] === "go") going(f[2], n(3))
            else if (f[1] === "drop") dropped(f[2])
        }
    }

    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/oblio-fx"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.read(text())
        onLoadFailed: if (root.last < 0) root.last = 0
    }
}
