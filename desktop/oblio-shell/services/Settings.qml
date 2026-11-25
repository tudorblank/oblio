// SPDX-License-Identifier: GPL-3.0-or-later
// Oblio's settings, saved in ~/.local/state/quickshell/by-shell/oblio/settings.json.
// Hyprland choices are applied live and also written to ~/.config/hypr/settings.lua,
// which hyprland.lua loads last.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property string hyprDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hypr"
    readonly property alias opts: adapter

    readonly property var hyprKeys: [
        "layout", "gapsIn", "gapsOut", "borderSize", "rounding", "inactiveOpacity", "focusKeyboard", "focusScroll",
        "accent", "themeMode", "blur", "blurSize", "animations",
        "sensitivity", "naturalScroll", "touchpadNaturalScroll", "repeatRate", "repeatDelay",
    ]

    function set(key, value) {
        if (adapter[key] === value) return
        adapter[key] = value
        if (key === "barEdge" || key === "dockEdge" || key === "barEnabled") keepEdgesApart(key)
        saveTimer.restart()
        if (hyprKeys.includes(key)) liveTimer.restart()
    }

    // the bar and the dock never share an edge: the one that didn't just move goes to a free one
    function keepEdgesApart(changed) {
        const o = adapter
        if (!o.barEnabled || o.barEdge !== o.dockEdge) return
        const moveDock = changed !== "dockEdge"
        const order = moveDock ? ["bottom", "left", "right", "top"] : ["top", "bottom", "left", "right"]
        const free = order.find(e => e !== (moveDock ? o.barEdge : o.dockEdge))
        o[moveDock ? "dockEdge" : "barEdge"] = free
    }

    function hyprLua() {
        const o = adapter
        return `hl.config({
    general = {
        layout = "${o.layout}",
        gaps_in = ${o.gapsIn},
        gaps_out = ${o.gapsOut},
        border_size = ${o.borderSize},
        col = {
            active_border = "rgba(${Theme.accentHex.slice(1)}ee)",
            inactive_border = "${Theme.dark ? "rgba(595959aa)" : "rgba(b4b4bcaa)"}",
        },
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
        onTriggered: Hyprland.dispatch(`function() ${root.hyprLua()} end`)
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

            // edge panels (edges/EdgePanel.qml), the same settings for each prefix:
            //   Edge top|bottom|left|right, Shape floating|attached|full, Roundness 0..100 (square ..
            //   round ends), Material solid|blur|glass, Opacity (of the tint, %; 100 = opaque),
            //   Color / ColorLight theme|#rrggbb (the tint in dark / light mode), Length fit|fixed, LengthPercent (fixed: 0 just fits the
            //   content, 100 spans the edge),
            //   Mode always|autohide|smart, Size (thickness, px)
            property bool barEnabled: true
            property string barEdge: "top"
            property string barShape: "full"
            property int barRoundness: 65
            property string barMaterial: "blur"
            property int barOpacity: 35
            property string barColor: "theme"
            property string barColorLight: "theme"
            property string barLength: "fit"
            property int barLengthPercent: 50
            property string barMode: "always"
            property int barSize: 32
            // floating bar: one surface (bar) or one per island (sections)
            property string barIslands: "bar"
            // services/BarWidgets.qml: the bar's islands in order, { uid, style, widgets: [{ uid, type, ...options }] }
            property var barWidgets: [
                { uid: "start", style: "continuous", widgets: [{ uid: "workspaces", type: "workspaces" }, { uid: "window", type: "window" }] },
                { uid: "center", style: "continuous", widgets: [{ uid: "clock", type: "clock" }] },
                { uid: "end", style: "continuous", widgets: [
                    { uid: "media", type: "media" }, { uid: "tray", type: "tray" }, { uid: "notifications", type: "notifications" },
                    { uid: "network", type: "network" }, { uid: "bluetooth", type: "bluetooth" }, { uid: "volume", type: "volume" },
                    { uid: "brightness", type: "brightness" }, { uid: "battery", type: "battery" }, { uid: "power", type: "power" }] },
            ]

            // notifications: Do Not Disturb keeps them in the list without showing cards
            property bool notifyDnd: false

            // dock: pinned apps are desktop file ids (without .desktop)
            property var dockPinned: ["Alacritty", "thunar"]
            property string dockEdge: "bottom"
            property string dockShape: "floating"
            property int dockRoundness: 65
            property string dockMaterial: "blur"
            property int dockOpacity: 35
            property string dockColor: "theme"
            property string dockColorLight: "theme"
            property string dockLength: "fit"
            property int dockLengthPercent: 60
            property string dockMode: "always"
            property int dockSize: 56
            property bool dockMagnify: true
            property bool dockDivider: true
            // where the icons sit along a dock longer than they need (full, or a fixed length):
            // start (left / top) | center | end (right / bottom)
            property string dockAlign: "center"
            // previews of minimized windows in muted colors
            property bool dockMutedMinimized: true

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

            // look (Theme.qml); a font that isn't installed falls back to Inter / monospace
            property string themeMode: "dark"    // dark | light
            property string accent: "#b9e66c"
            property string fontUi: "SF Pro"
            property string fontMono: "JetBrains Mono"
            property int fontSize: 11            // points, for apps; the shell scales its own text
            property bool blur: true
            property int blurSize: 8
            property bool animations: true

            // wallpaper (services/Wallpaper.qml): picture paths, "" = none; the lock screen shows
            // the desktop's while wallpaperLockSame; the folder Settings lists ("" = Pictures/Wallpapers)
            property string wallpaper: ""
            property string wallpaperLock: ""
            property bool wallpaperLockSame: true
            property string wallpaperFolder: ""

            // input
            property real sensitivity: 0
            property bool naturalScroll: false
            property bool touchpadNaturalScroll: true
            property int repeatRate: 25
            property int repeatDelay: 600
        }
    }
}
