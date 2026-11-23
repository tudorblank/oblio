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

    readonly property var args: [
        Theme.dark ? "dark" : "light",
        Theme.accentHex,
        Theme.luminance(Theme.accent) > 0.45 ? "#1a1a1a" : "#ffffff",
        nearestNamed(Theme.accent),
        Theme.fontUi,
        Theme.fontMono,
        String(Theme.fontSize),
    ]

    onArgsChanged: debounce.restart()
    Component.onCompleted: debounce.restart()

    Timer {
        id: debounce
        interval: 250
        onTriggered: {
            if (apply.running) return restart()
            apply.command = ["bash", Quickshell.shellDir + "/scripts/apply-theme"].concat(root.args)
            apply.running = true
        }
    }

    Process { id: apply }
}
