// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color text: "#f2f2f5"
    readonly property color subtext: "#9b9ba5"
    readonly property color panel: "#e0131316"
    readonly property color card: "#0dffffff"
    readonly property color hairline: "#17ffffff"
    readonly property color hover: "#0fffffff"
    readonly property color control: "#3a3a42"
    readonly property color onAccent: "#0d0d10"
    // ttf-nerd-fonts-symbols, or any other Nerd Font (Qt doesn't fall back to them by itself)
    readonly property string iconFont: {
        const all = Qt.fontFamilies()
        return all.includes("Symbols Nerd Font") ? "Symbols Nerd Font" : all.find(f => f.includes("Nerd Font")) ?? ""
    }
}
