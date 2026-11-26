// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Appearance: light/dark, accent, styles, fonts, animations. Mode, accent and fonts apply
// to the shell, GTK apps, browsers, icons, the terminal and Hyprland (services/SystemTheme.qml);
// styles are the look of the shell's parts and of apps (services/Styles.qml, settings/StyleCard.qml).
import QtQuick
import Quickshell
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
            font.pixelSize: Theme.textLabel
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

    Column {
        width: parent.width
        spacing: 8

        SectionLabel { text: "STYLES" }
        Text {
            leftPadding: 4
            bottomPadding: 4
            width: parent.width
            text: "A style is a look: material, tint and opacity. Give it to parts of the shell and to apps; each follows one style. Parts of the shell in no other style follow Default, apps in none keep their own look."
            wrapMode: Text.WordWrap
            color: Theme.subtext
            font.family: Theme.fontUi
            font.pixelSize: Theme.textLabel
        }
        Column {
            width: parent.width
            spacing: 12
            Repeater {
                model: ScriptModel { values: Styles.uids }
                StyleCard { required property string modelData; uid: modelData }
            }
        }
        // a new style, applied to nothing yet
        Rectangle {
            width: parent.width
            height: Theme.controlHeight + 16
            radius: Theme.groupRadius
            color: newArea.containsMouse ? Theme.hover : "transparent"
            border.width: 1
            border.color: Theme.hairline
            Row {
                x: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                PlusMark { anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; color: Theme.subtext }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "New style"
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textTitle
                }
            }
            MouseArea {
                id: newArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Styles.add()
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
        title: "WINDOW SHADOW"

        SettingRow {
            title: "Opacity"
            description: Settings.opts.shadowOpacity > 0 ? "How dark the shadow under windows is" : "No shadow"
            ValueSlider {
                from: 0; to: 100; unit: "%"
                value: Settings.opts.shadowOpacity
                onMoved: v => Settings.set("shadowOpacity", Math.round(v))
            }
        }
        SettingRow {
            title: "Size"
            description: "How far it reaches around the window"
            ValueSlider {
                from: 1; to: 60; unit: " px"
                value: Settings.opts.shadowSize
                onMoved: v => Settings.set("shadowSize", Math.round(v))
            }
        }
        SettingRow {
            title: "Spread"
            description: "Soft fades out gently, hard keeps a firm edge"
            Segmented {
                options: [{ value: 1, label: "Soft" }, { value: 2, label: "Medium" }, { value: 3, label: "Firm" }, { value: 4, label: "Hard" }]
                value: Settings.opts.shadowSpread
                onPicked: v => Settings.set("shadowSpread", v)
            }
        }
    }

    SettingGroup {
        title: "ANIMATIONS"

        SettingRow {
            title: "Animations"
            description: "Windows, workspaces and the shell"
            Toggle {
                checked: Settings.opts.animations
                onToggled: v => Settings.set("animations", v)
            }
        }
        SettingRow {
            title: "Speed"
            description: Settings.opts.animationSpeed === 100 ? "Oblio's own pace" : Settings.opts.animationSpeed > 100 ? "Faster than Oblio's own pace" : "Slower than Oblio's own pace"
            ValueSlider {
                enabled: Settings.opts.animations
                from: 50; to: 200; step: 10; unit: "%"
                value: Settings.opts.animationSpeed
                onMoved: v => Settings.set("animationSpeed", Math.round(v))
            }
        }
    }
}
