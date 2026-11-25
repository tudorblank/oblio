// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Windows: focus, tiling, borders. How see-through apps are is a style (Appearance).
import QtQuick
import qs.services
import qs.controls
import qs.settings

Column {
    spacing: 22

    SettingGroup {
        title: "FOCUS"

        SettingRow {
            title: "Typing follows the mouse"
            description: "Hovering a window focuses it for the keyboard. Off: click a window to type in it"
            Toggle {
                checked: Settings.opts.focusKeyboard
                onToggled: v => Settings.set("focusKeyboard", v)
            }
        }
        SettingRow {
            title: "Scrolling follows the mouse"
            description: "Scroll the window under the pointer without clicking it first"
            Toggle {
                enabled: !Settings.opts.focusKeyboard
                checked: Settings.opts.focusKeyboard || Settings.opts.focusScroll
                onToggled: v => Settings.set("focusScroll", v)
            }
        }
    }

    SettingGroup {
        title: "TILING"

        SettingRow {
            title: "Layout"
            description: "How tiled windows share the screen"
            Segmented {
                options: [{ value: "dwindle", label: "Dwindle" }, { value: "master", label: "Master" }, { value: "scrolling", label: "Scrolling" }]
                value: Settings.opts.layout
                onPicked: v => Settings.set("layout", v)
            }
        }
        SettingRow {
            title: "Gaps between windows"
            ValueSlider {
                from: 0; to: 30; unit: " px"
                value: Settings.opts.gapsIn
                onMoved: v => Settings.set("gapsIn", v)
            }
        }
        SettingRow {
            title: "Gaps at screen edges"
            ValueSlider {
                from: 0; to: 60; unit: " px"
                value: Settings.opts.gapsOut
                onMoved: v => Settings.set("gapsOut", v)
            }
        }
    }

    SettingGroup {
        title: "WINDOWS"

        SettingRow {
            title: "Border width"
            ValueSlider {
                from: 0; to: 6; unit: " px"
                value: Settings.opts.borderSize
                onMoved: v => Settings.set("borderSize", v)
            }
        }
        SettingRow {
            title: "Corner rounding"
            ValueSlider {
                from: 0; to: 24; unit: " px"
                value: Settings.opts.rounding
                onMoved: v => Settings.set("rounding", v)
            }
        }
    }
}
