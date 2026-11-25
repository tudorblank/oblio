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
    // dark text on light accents, white on dark ones (apply-theme gets the same, for GTK)
    readonly property string accentFgHex: luminance(accent) > 0.45 ? "#1a1a1d" : "#ffffff"
    readonly property color accentFg: accentFgHex
    readonly property color accentHover: Qt.lighter(accent, 1.12)
    // the accent as text or an icon on the theme's surfaces: darkened when it's too light to read
    readonly property color accentText: !dark && luminance(accent) > 0.35 ? Qt.darker(accent, 1.9) : accent

    function luminance(c) {
        const f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b)
    }
    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    // one size for every control (buttons, fields, dropdowns, segmented, chips), and how a
    // disabled one looks
    readonly property int controlHeight: 30
    readonly property real disabledOpacity: 0.4
    // type scale for the shell's own text
    readonly property int textCaption: 11
    readonly property int textLabel: 12
    readonly property int textBody: 13
    readonly property int textTitle: 14
    readonly property int textHeading: 22

    // edge panels' corners: roundness 0..100 % of fully round ends, for a thickness
    function rounded(percent, thick) { return Math.round(percent / 100 * thick / 2) }

    // the settings' cards of rows (SettingGroup)
    readonly property int groupRadius: 14

    // corners of the shell's cards (settings, popovers, notifications, the launcher); something
    // inside a card, padding away from its edge, follows the same curve with inner(padding)
    readonly property int radius: 22
    function inner(padding) { return Math.max(4, radius - padding) }

    // surfaces: window-like backgrounds; card/hover/hairline sit on top of them
    readonly property color background: dark ? "#141417" : "#f4f4f6"
    readonly property color panel: dark ? "#e8131316" : "#eef6f6f8"
    readonly property color popup: dark ? "#f4161619" : "#f8fbfbfc"
    readonly property color solid: dark ? "#1c1c20" : "#f2f2f4"
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
    // numbers (1920 × 1080, 165.01 Hz, 60 %, 90°) read best in the mono font
    function fontFor(text) {
        return /^[-+]?\d[\d.,:×x ]*\s*(%|°|Hz|px|s|ms|pt)?$/.test(String(text).trim()) ? fontMono : fontUi
    }

    // ttf-nerd-fonts-symbols, or any other Nerd Font (Qt doesn't fall back to them by itself)
    readonly property string iconFont: families.includes("Symbols Nerd Font") ? "Symbols Nerd Font" : families.find(f => f.includes("Nerd Font")) ?? ""
}
