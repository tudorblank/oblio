// SPDX-License-Identifier: GPL-3.0-or-later
// Oblio's settings: ~/.config/oblio/settings.json. Hyprland choices are applied
// live and also written to ~/.config/oblio/hyprland.lua, which oblio-desktop.lua
// loads at startup.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/oblio"
    readonly property alias opts: adapter
    readonly property color accent: adapter.accent === "hyprland" ? "#33ccff" : adapter.accent

    readonly property var hyprKeys: [
        "layout", "gapsIn", "gapsOut", "borderSize", "rounding", "inactiveOpacity", "focusFollowsMouse",
        "accent", "blur", "blurSize", "animations",
        "sensitivity", "naturalScroll", "touchpadNaturalScroll", "repeatRate", "repeatDelay",
    ]

    function set(key, value) {
        if (adapter[key] === value) return
        adapter[key] = value
        saveTimer.restart()
        if (hyprKeys.includes(key)) liveTimer.restart()
    }

    function hyprLua() {
        const o = adapter
        const border = o.accent === "hyprland"
            ? '{ colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }'
            : `"rgba(${o.accent.slice(1)}ee)"`
        return `hl.config({
    general = {
        layout = "${o.layout}",
        gaps_in = ${o.gapsIn},
        gaps_out = ${o.gapsOut},
        border_size = ${o.borderSize},
        col = { active_border = ${border} },
    },
    decoration = {
        rounding = ${o.rounding},
        inactive_opacity = ${(o.inactiveOpacity / 100).toFixed(2)},
        blur = { enabled = ${o.blur}, size = ${o.blurSize} },
    },
    animations = { enabled = ${o.animations} },
    input = {
        follow_mouse = ${o.focusFollowsMouse ? 1 : 0},
        sensitivity = ${o.sensitivity.toFixed(2)},
        natural_scroll = ${o.naturalScroll},
        repeat_rate = ${o.repeatRate},
        repeat_delay = ${o.repeatDelay},
        touchpad = { natural_scroll = ${o.touchpadNaturalScroll} },
    },
})
`
    }

    Timer {
        id: liveTimer
        interval: 40
        onTriggered: Quickshell.execDetached(["hyprctl", "dispatch", `function() ${root.hyprLua()} end`])
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: {
            settingsFile.writeAdapter()
            hyprFile.setText("-- written by Oblio's settings (SUPER+I), edits here get overwritten\n" + root.hyprLua())
        }
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    FileView {
        id: hyprFile
        path: root.dir + "/hyprland.lua"
        blockLoading: false
        preload: false
    }

    FileView {
        id: settingsFile
        path: root.dir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            // dock
            property int dockSize: 56
            property bool dockMagnify: true
            property bool dockAutoHide: false
            property bool dockDivider: true
            property int dockOpacity: 35

            // windows
            property string layout: "dwindle"
            property int gapsIn: 5
            property int gapsOut: 20
            property int borderSize: 2
            property int rounding: 10
            property int inactiveOpacity: 100
            property bool focusFollowsMouse: true

            // look
            property string accent: "hyprland"
            property bool blur: true
            property int blurSize: 8
            property bool animations: true

            // input
            property real sensitivity: 0
            property bool naturalScroll: false
            property bool touchpadNaturalScroll: false
            property int repeatRate: 25
            property int repeatDelay: 600
        }
    }
}
