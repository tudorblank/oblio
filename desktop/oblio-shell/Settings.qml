// SPDX-License-Identifier: GPL-3.0-or-later
// Oblio's settings, saved in ~/.local/state/quickshell/by-shell/oblio/settings.json.
// Hyprland choices are applied live and also written to ~/.config/hypr/settings.lua,
// which hyprland.lua loads last.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string hyprDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hypr"
    readonly property alias opts: adapter
    readonly property color accent: adapter.accent === "hyprland" ? "#33ccff" : adapter.accent

    readonly property var hyprKeys: [
        "layout", "gapsIn", "gapsOut", "borderSize", "rounding", "inactiveOpacity", "focusKeyboard", "focusScroll",
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
        follow_mouse = ${o.focusKeyboard ? 1 : o.focusScroll ? 2 : 0},
        -- with click to focus, moving between tiled and floating windows mustn't move focus either
        float_switch_override_focus = ${o.focusKeyboard ? 1 : 0},
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

    // Settings > Display: one rule per monitor
    function displaysLua() {
        const keys = Object.keys(adapter.displays)
        if (!keys.length) return ""
        return "\n" + keys.map(k => Displays.rule(k, adapter.displays[k]) + "\n").join("")
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: {
            settingsFile.writeAdapter()
            hyprFile.setText("-- written by Oblio's settings (SUPER+I), edits here get overwritten\n"
                + root.hyprLua() + root.displaysLua())
        }
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Quickshell.stateDir])

    FileView {
        id: hyprFile
        path: root.hyprDir + "/settings.lua"
        blockLoading: false
        preload: false
    }

    FileView {
        id: settingsFile
        path: Quickshell.statePath("settings.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            // display: monitor key ("desc:..." or name) -> { resolution, rate, scale, transform, position, mirror, disabled }
            property var displays: ({})

            // dock: pinned apps are desktop file ids (without .desktop)
            property var dockPinned: ["Alacritty", "org.kde.dolphin"]
            property int dockSize: 56
            property bool dockMagnify: true
            property string dockMode: "always"   // always | autohide | smart
            property bool dockDivider: true
            property int dockOpacity: 35

            // windows
            property string layout: "dwindle"
            property int gapsIn: 5
            property int gapsOut: 20
            property int borderSize: 2
            property int rounding: 10
            property int inactiveOpacity: 100
            // keyboard focus follows the pointer (follow_mouse 1); otherwise click to focus,
            // with scrolling still going to the window under the pointer (2) or not (0)
            property bool focusKeyboard: false
            property bool focusScroll: true

            // look
            property string accent: "hyprland"
            property bool blur: true
            property int blurSize: 8
            property bool animations: true

            // input
            property real sensitivity: 0
            property bool naturalScroll: false
            property bool touchpadNaturalScroll: true
            property int repeatRate: 25
            property int repeatDelay: 600
        }
    }
}
