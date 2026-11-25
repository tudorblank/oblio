// SPDX-License-Identifier: GPL-3.0-or-later
// Pushes Theme to the rest of the system (GTK, icons, fonts, terminal) through
// scripts/apply-theme: once at start, then whenever the look changes.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // libadwaita's named accents and the hue (degrees) each one covers: apps follow the nearest
    // one live and the exact accent on their next start. Lime and chartreuse count as green.
    readonly property var named: ({ red: 0, orange: 25, yellow: 48, green: 110, teal: 185, blue: 215, purple: 280, pink: 330 })
    function nearestNamed(c) {
        const q = Qt.color(c)
        if (q.hslSaturation < 0.15) return "slate"
        const h = q.hslHue * 360
        let best = "blue", dist = 999
        for (const n in named) {
            const d = Math.min(Math.abs(named[n] - h), 360 - Math.abs(named[n] - h))
            if (d < dist) { dist = d; best = n }
        }
        return best
    }

    // #rrggbbaa: rofi's order (Qt's is #aarrggbb)
    function alphaLast(c) {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0")
        return "#" + h(c.r) + h(c.g) + h(c.b) + h(c.a)
    }

    // everything apply-theme needs, from Theme: the one place these values live
    readonly property var env: ({
        OBLIO_MODE: Theme.dark ? "dark" : "light",
        OBLIO_ACCENT: Theme.accentHex,
        OBLIO_ACCENT_FG: Theme.accentFgHex,
        OBLIO_ACCENT_NAMED: nearestNamed(Theme.accent),
        OBLIO_BG: alphaLast(Theme.background).slice(0, 7),
        OBLIO_FG: alphaLast(Theme.text).slice(0, 7),
        OBLIO_SUBTEXT: alphaLast(Theme.subtext).slice(0, 7),
        OBLIO_POPUP: alphaLast(Theme.popup),
        OBLIO_CARD: alphaLast(Theme.card),
        OBLIO_BORDER: alphaLast(Theme.border),
        OBLIO_HOVER: alphaLast(Theme.hover),
        OBLIO_FONT_UI: Theme.fontUi,
        OBLIO_FONT_MONO: Theme.fontMono,
        OBLIO_FONT_ICONS: Theme.iconFont,
        OBLIO_FONT_SIZE: String(Theme.fontSize),
        OBLIO_RADIUS: String(Theme.radius),
        OBLIO_LOCK_WALLPAPER: Wallpaper.lock,
        // a new profile picture (~/.face) runs it again
        OBLIO_FACE_VERSION: String(User.version),
    })

    onEnvChanged: debounce.restart()
    Component.onCompleted: debounce.restart()

    Timer {
        id: debounce
        interval: 250
        onTriggered: {
            if (apply.running) return restart()
            apply.environment = root.env
            apply.running = true
        }
    }

    Process {
        id: apply
        command: ["bash", Quickshell.shellDir + "/scripts/apply-theme"]
    }
}
