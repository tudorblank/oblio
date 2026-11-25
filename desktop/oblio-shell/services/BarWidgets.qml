// SPDX-License-Identifier: GPL-3.0-or-later
// The bar's widgets: what exists (catalog, one file each in bar/widgets/) and what sits where
// (Settings.opts.barWidgets: start/center/end lists of entries: uid, type and its options).
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var lanes: ["start", "center", "end"]
    readonly property var laneNames: ({ start: "Left", center: "Center", end: "Right" })

    // options: key, label, kind (toggle | choice | list | number | text), default, then
    // choices (choice, list) or from/to/step/unit (number). Optional: section (options are grouped
    // by it), about (shown under the label), keepOne (toggles sharing it can't all be off).
    readonly property var languages: [
        { value: "en_US", label: "English (US)" }, { value: "en_GB", label: "English (UK)" },
        { value: "ro_RO", label: "Română" }, { value: "de_DE", label: "Deutsch" },
        { value: "fr_FR", label: "Français" }, { value: "es_ES", label: "Español" },
        { value: "it_IT", label: "Italiano" }, { value: "pt_BR", label: "Português (Brasil)" },
        { value: "nl_NL", label: "Nederlands" }, { value: "pl_PL", label: "Polski" },
        { value: "hu_HU", label: "Magyar" }, { value: "cs_CZ", label: "Čeština" },
        { value: "ru_RU", label: "Русский" }, { value: "uk_UA", label: "Українська" },
        { value: "tr_TR", label: "Türkçe" }, { value: "ja_JP", label: "日本語" },
        { value: "zh_CN", label: "中文" },
    ]
    readonly property var catalog: [
        { type: "workspaces", file: "Workspaces", name: "Workspaces", icon: "\u{f0570}",
          about: "Switch workspaces; scroll to move through them",
          options: [
            { key: "style", label: "Style", kind: "choice", default: "pills",
              choices: [{ value: "pills", label: "Pills" }, { value: "numbers", label: "Numbers" }] },
            { key: "count", label: "Always shown", kind: "number", default: 5, from: 1, to: 10, unit: "" },
          ] },
        { type: "window", file: "WindowTitle", name: "Current app", icon: "\u{f05b2}",
          about: "The focused window's app icon and title",
          options: [
            { key: "icon", label: "App icon", kind: "toggle", default: true, section: "Shows", keepOne: "shows" },
            { key: "title", label: "Window title", kind: "toggle", default: true, section: "Shows", keepOne: "shows",
              about: "Not on a bar at the side of the screen" },
            { key: "maxLength", label: "Longest Size", kind: "number", default: 320, from: 100, to: 600, step: 20, unit: " px",
              section: "Size", about: "Longer titles are cut short with …" },
          ] },
        { type: "clock", file: "Clock", name: "Clock", icon: "\u{f0954}",
          about: "Date and time; click for a calendar",
          options: [
            { key: "format", label: "Format", kind: "text", default: "ddd d MMM   HH:mm",
              about: "d dd ddd dddd: day · M MM MMM MMMM: month · yy yyyy: year · H HH (24 h) h hh AP (12 h) · mm: minutes · ss: seconds" },
            { key: "language", label: "Language", kind: "list", default: "en_US",
              about: "For the names of days and months", choices: languages },
          ] },
        { type: "media", file: "Media", name: "Media player", icon: "\u{f0386}",
          about: "What's playing; click for controls and seeking",
          options: [
            { key: "art", label: "Album art", kind: "toggle", default: true },
            { key: "maxLength", label: "Longest Size", kind: "number", default: 240, from: 80, to: 480, step: 20, unit: " px" },
            { key: "hideIdle", label: "Hide when nothing plays", kind: "toggle", default: false },
          ] },
        { type: "tray", file: "Tray", name: "System tray", icon: "\u{f1294}",
          about: "Icons of apps running in the background",
          options: [{ key: "spacing", label: "Spacing", kind: "number", default: 2, from: 0, to: 16, unit: " px",
                      about: "Between the icons" }] },
        { type: "volume", file: "Volume", name: "Volume", icon: "\u{f057e}",
          about: "Scroll to change, middle click to mute, click for devices and apps",
          options: [{ key: "value", label: "Show the percentage", kind: "toggle", default: true }] },
        { type: "brightness", file: "Brightness", name: "Brightness", icon: "\u{f00e0}",
          about: "Screen brightness; scroll to change (laptops)",
          options: [{ key: "value", label: "Show the percentage", kind: "toggle", default: true }] },
        { type: "battery", file: "Battery", name: "Battery", icon: "\u{f0079}",
          about: "Charge and time left; click for power profiles",
          options: [{ key: "value", label: "Show the percentage", kind: "toggle", default: true }] },
        { type: "network", file: "Network", name: "Network", icon: "\u{f05a9}",
          about: "Cable and Wi-Fi; click to pick a network",
          options: [{ key: "name", label: "Show the network name", kind: "toggle", default: false }] },
        { type: "bluetooth", file: "Bluetooth", name: "Bluetooth", icon: "\u{f00af}",
          about: "Turn it on or off, connect and pair devices",
          options: [{ key: "name", label: "Show the connected device", kind: "toggle", default: false }] },
        { type: "notifications", file: "Notifications", name: "Notifications", icon: "\u{f009a}",
          about: "Unread notifications, Do Not Disturb; click for the list",
          options: [{ key: "count", label: "Show the unread count", kind: "toggle", default: true }] },
        { type: "power", file: "Power", name: "Power", icon: "\u{f0425}",
          about: "Log out, sleep, restart, shut down",
          options: [] },
        { type: "launcher", file: "Launcher", name: "Apps", icon: "\u{f003b}",
          about: "Opens the app launcher",
          options: [] },
        { type: "settings", file: "SettingsButton", name: "Settings", icon: "\u{f0493}",
          about: "Opens these settings",
          options: [] },
        { type: "spacer", file: "Spacer", name: "Spacer", icon: "\u{f084e}",
          about: "Empty space between widgets",
          options: [
            { key: "length", label: "Length", kind: "number", default: 16, from: 4, to: 200, step: 4, unit: " px" },
            { key: "expand", label: "Stretch", kind: "toggle", default: false,
              about: "Grows into the empty room of its section, pushing the widgets on its two sides apart. There's only empty room when the bar is longer than what it holds: Length set to Fixed, or the Full shape" },
          ] },
        { type: "separator", file: "Separator", name: "Separator", icon: "\u{f01d9}",
          about: "A thin line between widgets",
          options: [] },
    ]

    function info(type) { return catalog.find(c => c.type === type) ?? null }

    readonly property var layout: Settings.opts.barWidgets
    function uids(lane) { return (layout[lane] ?? []).map(e => e.uid) }
    function entry(uid) {
        for (const l of lanes) for (const e of layout[l] ?? []) if (e.uid === uid) return e
        return null
    }
    function option(e, key) {
        if (!e) return undefined
        if (e[key] !== undefined) return e[key]
        const o = (info(e.type)?.options ?? []).find(o => o.key === key)
        return o ? o.default : undefined
    }

    function copy() {
        const l = JSON.parse(JSON.stringify(layout))
        for (const k of lanes) l[k] = l[k] ?? []
        return l
    }
    function add(lane, type) {
        const l = copy()
        const uid = type + "-" + Date.now().toString(36)
        l[lane].push({ uid, type })
        Settings.set("barWidgets", l)
        return uid
    }
    function remove(uid) {
        const l = copy()
        for (const k of lanes) l[k] = l[k].filter(e => e.uid !== uid)
        Settings.set("barWidgets", l)
    }
    function move(uid, lane, index) {
        const l = copy()
        let e = null
        for (const k of lanes) {
            const i = l[k].findIndex(x => x.uid === uid)
            if (i < 0) continue
            e = l[k][i]
            l[k].splice(i, 1)
            if (k === lane && i < index) index--
        }
        if (!e) return
        l[lane].splice(Math.max(0, Math.min(index, l[lane].length)), 0, e)
        Settings.set("barWidgets", l)
    }
    function setOption(uid, key, value) {
        const l = copy()
        for (const k of lanes) for (const e of l[k]) if (e.uid === uid) e[key] = value
        Settings.set("barWidgets", l)
    }
}
