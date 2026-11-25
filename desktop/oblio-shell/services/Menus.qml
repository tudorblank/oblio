// SPDX-License-Identifier: GPL-3.0-or-later
// The shell's open menus (settings, popovers). While one is open Hyprland switches to the
// "oblio-menu" submap (binds.lua), where no keybind reaches the windows; SUPER+Q there closes them.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // each menu has close()
    property var open: []
    readonly property bool any: open.length > 0

    function add(menu) { if (!open.includes(menu)) open = open.concat([menu]) }
    function remove(menu) { open = open.filter(m => m !== menu) }
    function closeAll() { for (const m of open.slice()) m.close() }

    // opens Settings (SUPER+I), on a page by its title ("Bar") or where it was
    signal settingsRequested(string page)
    function openSettings(page) { settingsRequested(page ?? "") }

    function submap(name) { Hyprland.dispatch(`hl.dsp.submap("${name}")`) }
    onAnyChanged: submap(any ? "oblio-menu" : "reset")
    // a shell that restarted with a menu open
    Component.onCompleted: submap("reset")

    IpcHandler {
        target: "menus"
        function close(): void { root.closeAll() }
        // the right keybind mode for what's open (scripts/launcher, after rofi closes)
        function sync(): void { root.submap(root.any ? "oblio-menu" : "reset") }
    }
}
