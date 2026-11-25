// SPDX-License-Identifier: GPL-3.0-or-later
// Apps and their icons: the one way the shell finds a desktop entry or an icon to draw.
// Desktop entries load in the background after start; bindings calling these re-run once they do.
pragma Singleton

import QtQuick
import Quickshell

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
}
