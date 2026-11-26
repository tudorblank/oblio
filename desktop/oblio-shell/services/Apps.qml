// SPDX-License-Identifier: GPL-3.0-or-later
// Apps and their icons: the one way the shell finds a desktop entry or an icon to draw.
// Desktop entries load in the background after start; bindings calling these re-run once they do.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    // the desktop entry for an id, or the best guess from an app id or name
    function entry(id) {
        DesktopEntries.applications.values
        if (!id) return null
        return DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id)
    }
    // something an Image can show for an icon name, a path, or an app id/name; the fallback
    // icon name when none is found ("" for nothing)
    function icon(name, fallback) {
        if (name) {
            if (name.startsWith("/")) return "file://" + name
            if (/^(file|image|https?):/.test(name)) return name
            const themed = Quickshell.iconPath(name, true)
            if (themed) return themed
            const e = entry(name)
            if (e && e.icon) return Quickshell.iconPath(e.icon, true) || ""
        }
        return fallback ? Quickshell.iconPath(fallback, true) : ""
    }
    // an app's own icon, by its desktop entry first
    function appIcon(id, fallback) {
        const e = entry(id)
        return icon(e && e.icon ? e.icon : id, fallback)
    }

    // the apps that match what's typed, best first: the name starting with it, then a word of the
    // name, then anywhere in the name, then the generic name, keywords or description
    function search(text) {
        const q = String(text ?? "").trim().toLowerCase()
        if (!q) return []
        const rank = e => {
            const name = (e.name ?? "").toLowerCase()
            if (name.startsWith(q)) return 0
            if (name.split(/[\s._-]+/).some(w => w.startsWith(q))) return 1
            if (name.includes(q)) return 2
            const more = [e.genericName, e.comment].concat(Array.from(e.keywords ?? []))
            return more.some(t => String(t ?? "").toLowerCase().includes(q)) ? 3 : -1
        }
        const seen = new Set(), found = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay || seen.has(e.id)) continue
            seen.add(e.id)
            const r = rank(e)
            if (r >= 0) found.push({ e, r })
        }
        return found.sort((a, b) => a.r - b.r || a.e.name.localeCompare(b.e.name)).map(f => f.e)
    }

    // the apps there are, by name: the window class each opens (cls), installed ones and open
    // windows of any other
    readonly property var installed: {
        const seen = new Set(), l = []
        const add = (cls, name) => {
            if (!cls || seen.has(cls.toLowerCase())) return
            seen.add(cls.toLowerCase())
            l.push({ cls, name })
        }
        for (const e of DesktopEntries.applications.values) if (!e.noDisplay) add(e.startupClass || e.id, e.name)
        for (const t of Hyprland.toplevels.values) add(t.wayland?.appId ?? "", t.wayland?.appId ?? "")
        return l.sort((a, b) => a.name.localeCompare(b.name))
    }
}
