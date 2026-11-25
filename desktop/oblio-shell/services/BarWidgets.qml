// SPDX-License-Identifier: GPL-3.0-or-later
// The bar's widgets: what exists (catalog, one file each in bar/widgets/) and what sits where.
// Settings.opts.barWidgets is the list of the bar's islands, in order along it: an island is a
// group of widgets, a uid, its style (continuous | scattered: one island per widget, on a bar
// split into its islands), its spacing (px between its widgets, not at its ends) and its widgets (entries: uid, type and the widget's options). The
// layout from before islands (three lists: start, center, end) reads as three islands.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root


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
            { key: "size", label: "Size", kind: "number", default: 40, from: 25, to: 75, step: 5, unit: " %",
              about: "Of the bar's thickness, so it always fits" },
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
            { key: "hideIdle", label: "Hide when nothing plays", kind: "toggle", default: false,
              about: "It stays a moment after playing stops, so skipping or seeking doesn't make it blink" },
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
          about: "Charge, charging or not, time left; click for power profiles",
          options: [
            { key: "value", label: "Show the percentage", kind: "toggle", default: true },
            { key: "time", label: "Show the time left", kind: "toggle", default: false,
              about: "Until empty, or until full while charging" },
          ] },
        { type: "network", file: "Network", name: "Network", icon: "\u{f05a9}",
          about: "Cable and Wi-Fi; click to pick a network",
          options: [{ key: "name", label: "Show the network name", kind: "toggle", default: false }] },
        { type: "bluetooth", file: "Bluetooth", name: "Bluetooth", icon: "\u{f00af}",
          about: "Turn it on or off, connect and pair devices",
          options: [
            { key: "name", label: "Show the connected device", kind: "toggle", default: false },
            { key: "battery", label: "Show its battery", kind: "toggle", default: false,
              about: "For devices that report it (headphones, mice, controllers)" },
          ] },
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

    readonly property var islands: {
        const v = Settings.opts.barWidgets ?? []
        // (what the settings file gives back is a list, but not a JS Array)
        if (v.length === undefined) return ["start", "center", "end"].map(k => ({ uid: k, style: "continuous", widgets: v[k] ?? [] }))
        return Array.from(v)
    }
    readonly property var islandUids: islands.map(i => i.uid)
    function island(uid) { return islands.find(i => i.uid === uid) ?? null }
    function uids(island) { return (root.island(island)?.widgets ?? []).map(e => e.uid) }
    function entry(uid) {
        for (const i of islands) for (const e of i.widgets) if (e.uid === uid) return e
        return null
    }
    function option(e, key) {
        if (!e) return undefined
        if (e[key] !== undefined) return e[key]
        const o = (info(e.type)?.options ?? []).find(o => o.key === key)
        return o ? o.default : undefined
    }

    // changes: each works on a copy and saves it whole
    function newUid(kind) { return kind + "-" + Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36) }
    function change(fn) {
        const l = JSON.parse(JSON.stringify(islands))
        const r = fn(l)
        Settings.set("barWidgets", l)
        return r
    }
    function add(island, type) {
        return change(l => {
            const uid = newUid(type)
            l.find(i => i.uid === island)?.widgets.push({ uid, type })
            return uid
        })
    }
    function remove(uid) {
        change(l => { for (const i of l) i.widgets = i.widgets.filter(e => e.uid !== uid) })
    }
    function move(uid, island, index) {
        change(l => {
            let e = null
            for (const i of l) {
                const at = i.widgets.findIndex(x => x.uid === uid)
                if (at < 0) continue
                e = i.widgets[at]
                i.widgets.splice(at, 1)
                if (i.uid === island && at < index) index--
            }
            const to = l.find(i => i.uid === island)
            if (e && to) to.widgets.splice(Math.max(0, Math.min(index, to.widgets.length)), 0, e)
        })
    }
    function setOption(uid, key, value) {
        change(l => { for (const i of l) for (const e of i.widgets) if (e.uid === uid) e[key] = value })
    }

    function addIsland() {
        return change(l => {
            const uid = newUid("island")
            l.push({ uid, style: "continuous", widgets: [] })
            return uid
        })
    }
    // with its widgets; the bar keeps at least one
    function removeIsland(uid) {
        if (islands.length > 1) change(l => l.splice(l.findIndex(i => i.uid === uid), 1))
    }
    function moveIsland(uid, by) {
        change(l => {
            const at = l.findIndex(i => i.uid === uid), to = at + by
            if (at < 0 || to < 0 || to >= l.length) return
            l.splice(to, 0, l.splice(at, 1)[0])
        })
    }
    function setSpacing(uid, px) {
        change(l => { const i = l.find(i => i.uid === uid); if (i) i.spacing = px })
    }
    function setStyle(uid, style) {
        change(l => { const i = l.find(i => i.uid === uid); if (i) i.style = style })
    }
}
