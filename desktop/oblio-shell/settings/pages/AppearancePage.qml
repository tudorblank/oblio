// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Appearance: light/dark, accent, fonts, effects. Applies to the shell, GTK apps,
// browsers, icons, the terminal and Hyprland (services/SystemTheme.qml).
import QtQuick
import Quickshell.Io
import qs.services
import qs.controls
import qs.settings

Column {
    id: page
    spacing: 22

    // a small picture of a window in that mode, with the current accent
    component ModeTile: Item {
        id: tile
        property string mode
        property string label
        readonly property bool dark: mode === "dark"
        readonly property bool selected: Settings.opts.themeMode === mode
        width: 148
        height: 112

        Rectangle {
            id: frame
            width: parent.width
            height: 86
            radius: 12
            color: tile.dark ? "#141417" : "#f4f4f6"
            border.width: tile.selected ? 2 : 1
            border.color: tile.selected ? Theme.accent : Theme.hairline

            Rectangle {
                x: 14; y: 14
                width: parent.width - 28
                height: parent.height - 28
                radius: 7
                color: tile.dark ? "#1f1f24" : "#ffffff"
                border.width: 1
                border.color: tile.dark ? "#2c2c33" : "#e2e2e7"

                Column {
                    x: 10; y: 10
                    spacing: 6
                    Rectangle { width: 56; height: 6; radius: 3; color: tile.dark ? "#5a5a64" : "#c4c4cc" }
                    Rectangle { width: 80; height: 6; radius: 3; color: tile.dark ? "#3c3c44" : "#dcdce2" }
                    Rectangle { width: 34; height: 10; radius: 5; color: Theme.accent }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: tile.label
            color: tile.selected ? Theme.text : Theme.subtext
            font.family: Theme.fontUi
            font.pixelSize: 12
            font.weight: tile.selected ? Font.DemiBold : Font.Normal
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Settings.set("themeMode", tile.mode)
        }
    }

    // installed font families, and the monospace ones
    property var uiFonts: []
    property var monoFonts: []
    function familyList(text) {
        const seen = new Set()
        for (const line of text.split("\n"))
            for (const f of line.split(",")) {
                const name = f.trim()
                if (name && !/Nerd Font|Symbols|Emoji|Cursor|DejaVu Math/i.test(name)) seen.add(name)
            }
        return [...seen].sort((a, b) => a.localeCompare(b)).map(f => ({ value: f, label: f, font: f }))
    }
    Process {
        running: true
        command: ["fc-list", ":", "family"]
        stdout: StdioCollector { onStreamFinished: page.uiFonts = page.familyList(text) }
    }
    Process {
        running: true
        command: ["fc-list", ":spacing=mono", "family"]
        stdout: StdioCollector { onStreamFinished: page.monoFonts = page.familyList(text) }
    }

    SettingGroup {
        title: "MODE"

        Item {
            width: parent.width
            height: 112 + 32

            Row {
                anchors.centerIn: parent
                spacing: 24
                ModeTile { mode: "dark"; label: "Dark" }
                ModeTile { mode: "light"; label: "Light" }
            }
        }
    }

    SettingGroup {
        title: "COLOR"

        SettingRow {
            title: "Accent"
            description: "Window borders, selections, Oblio's controls, and apps that follow it"
            Swatches {
                value: Theme.accentHex
                onPicked: v => Settings.set("accent", v)
            }
        }
    }

    SettingGroup {
        title: "FONTS"

        SettingRow {
            title: "Interface"
            description: Settings.opts.fontUi === Theme.fontUi ? "Menus, labels and windows" : Settings.opts.fontUi + " isn't installed, using " + Theme.fontUi
            Dropdown {
                options: page.uiFonts
                value: Theme.fontUi
                onPicked: v => Settings.set("fontUi", v)
            }
        }
        SettingRow {
            title: "Monospace"
            description: "The terminal and code"
            Dropdown {
                options: page.monoFonts
                value: Theme.fontMono
                onPicked: v => Settings.set("fontMono", v)
            }
        }
        SettingRow {
            title: "Text size"
            description: "For apps and the terminal"
            ValueSlider {
                from: 8; to: 16; unit: " pt"
                value: Settings.opts.fontSize
                onMoved: v => Settings.set("fontSize", v)
            }
        }
    }

    SettingGroup {
        title: "EFFECTS"

        SettingRow {
            title: "Blur"
            description: "Frosted glass behind the dock, panels and see-through windows"
            Toggle {
                checked: Settings.opts.blur
                onToggled: v => Settings.set("blur", v)
            }
        }
        SettingRow {
            title: "Blur strength"
            ValueSlider {
                from: 1; to: 16
                value: Settings.opts.blurSize
                onMoved: v => Settings.set("blurSize", v)
            }
        }
        SettingRow {
            title: "Animations"
            Toggle {
                checked: Settings.opts.animations
                onToggled: v => Settings.set("animations", v)
            }
        }
    }
}
