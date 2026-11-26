// SPDX-License-Identifier: GPL-3.0-or-later
// The shell's parts: everything it draws on a layer of its own, defined once here. A part is an id,
// a name and an icon (Settings, style pickers), its layer namespaces (the first is its own window's)
// and its options. Styles gives each part a look (services/Styles.qml), and Hyprland a rule for its
// layers; controls/Overlay.qml and controls/Card.qml draw a part from its id; a part with options
// gets a Settings page built from them (settings/PartPage.qml).
// options: key, label, kind (toggle | choice | list | number | text), default, then choices
// (choice, list) or from/to/step/unit (number); about is shown under the label (the same
// definitions as the bar's widgets, services/BarWidgets.qml). Values live in Settings.opts.parts,
// by part then key; option() falls back to the default here.
// floor: the alpha Hyprland doesn't blur under, so what a surface draws around itself stays clear.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var list: [
        { id: "bar", name: "Bar", icon: Icons.bar, namespaces: ["oblio-bar"] },
        { id: "dock", name: "Dock", icon: Icons.dock, namespaces: ["oblio-dock"] },
        // everything the shell opens over the desktop for a moment: the bar's popups, right-click
        // menus, the dock's window previews, notification cards, the color picker
        { id: "menus", name: "Menus", icon: Icons.menu, namespaces: ["oblio-popup", "oblio-previews", "oblio-notifications"] },
        { id: "settings", name: "Settings", icon: Icons.settings, namespaces: ["oblio-settings"], floor: 0.12 },
        { id: "search", name: "Search Tool", icon: Icons.search, namespaces: ["oblio-search"],
          subtitle: "Apps by name, description or keyword (SUPER+R)",
          options: [
            { key: "width", label: "Width", about: "While you type; it starts narrower", kind: "number",
              default: 560, from: 400, to: 900, step: 20, unit: " px" },
            { key: "rows", label: "Results shown", about: "More scroll", kind: "number", default: 6, from: 3, to: 12 },
            { key: "top", label: "Height on the screen", about: "How far down from the top it opens", kind: "number",
              default: 20, from: 5, to: 50, unit: "%" },
            { key: "details", label: "Descriptions", about: "What each app is, under its name", kind: "toggle", default: true },
          ] },
    ]
    function part(id) { return list.find(p => p.id === id) ?? null }
    // a part's own window's layer namespace
    function namespace(id) { return part(id)?.namespaces[0] ?? "" }

    // a part's option: what Settings has, else its default
    function option(id, key) {
        const saved = Settings.opts.parts?.[id]?.[key]
        if (saved !== undefined) return saved
        return (part(id)?.options ?? []).find(o => o.key === key)?.default
    }
    function set(id, key, value) {
        if (option(id, key) === value) return
        const all = JSON.parse(JSON.stringify(Settings.opts.parts ?? {}))
        all[id] = Object.assign(all[id] ?? {}, { [key]: value })
        Settings.set("parts", all)
    }
}
