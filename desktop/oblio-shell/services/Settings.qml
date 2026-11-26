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
        "layout", "gapsIn", "gapsOut", "borderSize", "rounding", "focusKeyboard", "focusScroll",
        "accent", "themeMode", "animations", "animationSpeed", "shadowOpacity", "shadowSize", "shadowSpread",
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
        -- black only ever darkens what's under it, like a shadow multiplied over the desktop
        shadow = {
            enabled = ${o.shadowOpacity > 0},
            range = ${o.shadowSize},
            render_power = ${o.shadowSpread},
            color = 0x${Math.round(o.shadowOpacity / 100 * 255).toString(16).padStart(2, "0")}000000,
        },
    },
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
-- animations on or off, and their speed (modules/animations.lua)
if oblio and oblio.animate then oblio.animate(${(100 / o.animationSpeed).toFixed(3)}, ${o.animations}) end
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

    // settings.lua: Hyprland's settings, monitors and the style rules (services/Styles.qml), also
    // written (and applied) at start so Hyprland has what the shell has
    function writeHypr() {
        hyprFile.setText("-- written by Oblio's settings (SUPER+I), edits here get overwritten\n"
            + hyprLua() + displaysLua() + "\n" + Styles.hyprRules + "\n")
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: {
            settingsFile.writeAdapter()
            root.writeHypr()
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
        // at start (and when the file changes) Hyprland gets them live too, not only at its next reload
        onLoaded: { root.writeHypr(); liveTimer.restart() }
        onLoadFailed: { root.writeHypr(); liveTimer.restart() }

        JsonAdapter {
            id: adapter

            // display: monitor key ("desc:..." or name) -> { resolution, rate, scale, transform, position, mirror, disabled }
            property var displays: ({})

            // edge panels (edges/EdgePanel.qml), the same settings for each prefix:
            //   Edge top|bottom|left|right, Shape floating|attached|full, Roundness 0..100 (square ..
            //   round ends), Length fit|fixed, LengthPercent (fixed: 0 just fits the content, 100 spans
            //   the edge), Mode always|autohide|smart, Size (thickness, px). Their look is a style.
            property bool barEnabled: true
            property string barEdge: "top"
            property string barShape: "floating"
            property int barRoundness: 100
            property string barLength: "fixed"
            property int barLengthPercent: 100
            property string barMode: "always"
            property int barSize: 35
            // floating bar: one surface (bar) or one per island (sections)
            property string barIslands: "sections"
            // services/BarWidgets.qml: the bar's islands in order, { uid, style, widgets: [{ uid, type, ...options }] }
            property var barWidgets: [
                { uid: "start", style: "continuous", widgets: [{ uid: "settings", type: "settings" }] },
                { uid: "center", style: "continuous", widgets: [
                    { uid: "brightness", type: "brightness" }, { uid: "volume", type: "volume" },
                    { uid: "spacer-left", type: "spacer", length: 132 },
                    { uid: "clock", type: "clock", format: "d MMM   HH:mm", language: "en_US" },
                    { uid: "workspaces", type: "workspaces" }, { uid: "media", type: "media", hideIdle: true },
                    { uid: "spacer-right", type: "spacer", length: 132 },
                    { uid: "notifications", type: "notifications" }, { uid: "network", type: "network" },
                    { uid: "bluetooth", type: "bluetooth" }, { uid: "battery", type: "battery" }] },
                { uid: "end", style: "continuous", widgets: [{ uid: "power", type: "power" }] },
            ]

            // notifications: Do Not Disturb keeps them in the list without showing cards
            property bool notifyDnd: false

            // dock: pinned apps are desktop file ids (without .desktop)
            property var dockPinned: ["org.gnome.Nautilus", "Alacritty"]
            property string dockEdge: "bottom"
            property string dockShape: "floating"
            property int dockRoundness: 100
            property string dockLength: "fit"
            property int dockLengthPercent: 40
            property string dockMode: "always"
            property int dockSize: 52
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
            // keyboard focus follows the pointer (follow_mouse 1); otherwise click to focus,
            // with scrolling still going to the window under the pointer (2) or not (0)
            property bool focusKeyboard: false
            property bool focusScroll: true

            // look (Theme.qml); a font that isn't installed falls back to Inter / monospace
            property string themeMode: "dark"    // dark | light
            property string accent: "#e6c784"
            property string fontUi: "SF Pro"
            property string fontMono: "JetBrains Mono"
            property int fontSize: 11            // points, for apps; the shell scales its own text
            // animations, and their speed (% of their own pace: 200 = twice as fast), for windows,
            // workspaces and the shell (Theme.ms)
            property bool animations: true
            property int animationSpeed: 100
            // windows' drop shadow: opacity (%, 0 = none), size (px), spread (1 soft .. 4 hard edge)
            property int shadowOpacity: 93
            property int shadowSize: 4
            property int shadowSpread: 3

            // the shell's parts' options (services/Parts.qml), by part then key: only the ones changed
            property var parts: ({})

            // styles (services/Styles.qml): Default first, then the ones made in Settings; targets are
            // shell parts (services/Parts.qml), "apps" or "app:CLASS"
            property var styles: [
                { uid: "default", name: "Default", material: "blur", opacity: 30, tint: "theme", tintLight: "theme",
                  blur: 6, contrast: 89, saturation: 112, noise: 6, targets: [] },
            ]

            // wallpaper (services/Wallpaper.qml): picture paths, "" = none; the lock screen shows
            // the desktop's while wallpaperLockSame; the folder Settings lists ("" = Pictures/Wallpapers)
            property string wallpaper: ""
            property string wallpaperLock: ""
            property bool wallpaperLockSame: true
            property string wallpaperFolder: ""

            // battery alerts (services/Battery.qml): low while discharging, high while charging (%)
            property bool batteryAlertLow: true
            property int batteryLow: 20
            property bool batteryAlertHigh: false
            property int batteryHigh: 80

            // input
            property real sensitivity: 0
            property bool naturalScroll: false
            property bool touchpadNaturalScroll: true
            property int repeatRate: 25
            property int repeatDelay: 600
        }
    }
}
