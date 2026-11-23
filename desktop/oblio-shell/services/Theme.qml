// SPDX-License-Identifier: GPL-3.0-or-later
// Oblio's look: light/dark mode, accent, the palette for both modes, fonts. The shell reads
// it directly; SystemTheme pushes it to GTK, icons, fonts, the terminal and Hyprland.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: t

    readonly property string defaultAccent: "#b9e66c"
    readonly property bool dark: Settings.opts.themeMode !== "light"
    readonly property color accent: /^#[0-9a-fA-F]{6}$/.test(Settings.opts.accent) ? Settings.opts.accent : defaultAccent
    readonly property string accentHex: String(accent).slice(0, 7)
    // dark text on light accents, white on dark ones
    readonly property color onAccent: luminance(accent) > 0.45 ? "#e6111114" : "#ffffff"

    function luminance(c) {
        const f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b)
    }
    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // surfaces: window-like backgrounds; card/hover/hairline sit on top of them
    readonly property color background: dark ? "#141417" : "#f4f4f6"
    readonly property color panel: dark ? "#e8131316" : "#eef6f6f8"
    readonly property color popup: dark ? "#f4161619" : "#f8fbfbfc"
    readonly property color glass: dark ? Qt.rgba(0.08, 0.08, 0.09, 1) : Qt.rgba(0.97, 0.97, 0.98, 1)
    readonly property color card: dark ? "#0dffffff" : "#b3ffffff"
    readonly property color hover: dark ? "#0fffffff" : "#0c000000"
    readonly property color hairline: dark ? "#17ffffff" : "#16000000"
    readonly property color border: dark ? "#24ffffff" : "#1f000000"
    readonly property color control: dark ? "#3a3a42" : "#d2d2d8"
    readonly property color knob: "#ffffff"
    readonly property color text: dark ? "#f2f2f5" : "#1c1c21"
    readonly property color subtext: dark ? "#9b9ba5" : "#6a6a74"
    readonly property color danger: dark ? "#ff8a8d" : "#d23a40"
    readonly property color scrim: dark ? "#4d000000" : "#33000000"

    // the font chosen in Settings, or Inter when it isn't installed
    readonly property var families: Qt.fontFamilies()
    function installed(name, fallback) { return families.includes(name) ? name : fallback }
    readonly property string fontUi: installed(Settings.opts.fontUi, "Inter")
    readonly property string fontMono: installed(Settings.opts.fontMono, "monospace")
    readonly property int fontSize: Settings.opts.fontSize

    // ttf-nerd-fonts-symbols, or any other Nerd Font (Qt doesn't fall back to them by itself)
    readonly property string iconFont: families.includes("Symbols Nerd Font") ? "Symbols Nerd Font" : families.find(f => f.includes("Nerd Font")) ?? ""
}
