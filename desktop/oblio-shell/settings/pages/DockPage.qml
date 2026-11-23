// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Dock.
import QtQuick
import qs.services
import qs.controls
import qs.settings

Column {
    spacing: 22

    SettingGroup {
        title: "SIZE AND LOOK"

        SettingRow {
            title: "Size"
            description: "Height of the dock, icons scale with it"
            ValueSlider {
                from: 40; to: 96; unit: " px"
                value: Settings.opts.dockSize
                onMoved: v => Settings.set("dockSize", v)
            }
        }
        SettingRow {
            title: "Glass tint"
            description: "How dark the dock's glass is"
            ValueSlider {
                from: 10; to: 90; unit: "%"
                value: Settings.opts.dockOpacity
                onMoved: v => Settings.set("dockOpacity", v)
            }
        }
    }

    SettingGroup {
        title: "BEHAVIOR"

        SettingRow {
            title: "Magnify on hover"
            Toggle {
                checked: Settings.opts.dockMagnify
                onToggled: v => Settings.set("dockMagnify", v)
            }
        }
        SettingRow {
            title: "Show"
            description: Settings.opts.dockMode === "autohide" ? "Hidden until the pointer touches the bottom edge"
                : Settings.opts.dockMode === "smart" ? "Hides while a window reaches into it; the bottom edge brings it back"
                : "Always on screen; windows stay clear of it"
            Segmented {
                options: [{ value: "always", label: "Always" }, { value: "autohide", label: "Auto-hide" }, { value: "smart", label: "Smart" }]
                value: Settings.opts.dockMode
                onPicked: v => Settings.set("dockMode", v)
            }
        }
        SettingRow {
            title: "Divider"
            description: "A line between pinned apps and other open apps"
            Toggle {
                checked: Settings.opts.dockDivider
                onToggled: v => Settings.set("dockDivider", v)
            }
        }
    }
}
