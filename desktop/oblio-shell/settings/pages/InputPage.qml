// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Input: mouse, touchpad, keyboard.
import QtQuick
import qs.services
import qs.controls
import qs.settings

Column {
    spacing: 22

    SettingGroup {
        title: "MOUSE AND TOUCHPAD"

        SettingRow {
            title: "Pointer speed"
            ValueSlider {
                from: -1; to: 1; step: 0.05; decimals: 2
                value: Settings.opts.sensitivity
                onMoved: v => Settings.set("sensitivity", v)
            }
        }
        SettingRow {
            title: "Natural scrolling (mouse)"
            description: "Content follows your fingers, like a phone"
            Toggle {
                checked: Settings.opts.naturalScroll
                onToggled: v => Settings.set("naturalScroll", v)
            }
        }
        SettingRow {
            title: "Natural scrolling (touchpad)"
            Toggle {
                checked: Settings.opts.touchpadNaturalScroll
                onToggled: v => Settings.set("touchpadNaturalScroll", v)
            }
        }
    }

    SettingGroup {
        title: "KEYBOARD"

        SettingRow {
            title: "Repeat rate"
            description: "Characters per second while a key is held"
            ValueSlider {
                from: 10; to: 60; unit: "/s"
                value: Settings.opts.repeatRate
                onMoved: v => Settings.set("repeatRate", v)
            }
        }
        SettingRow {
            title: "Repeat delay"
            description: "How long to hold a key before it repeats"
            ValueSlider {
                from: 150; to: 1000; step: 25; unit: " ms"
                value: Settings.opts.repeatDelay
                onMoved: v => Settings.set("repeatDelay", v)
            }
        }
    }
}
