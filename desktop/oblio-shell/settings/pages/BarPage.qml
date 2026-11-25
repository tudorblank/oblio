// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Bar: on or off, its widgets (BarLayout), then the edge panel settings (EdgeSettings).
// Its look is a style (Appearance).
import QtQuick
import qs.services
import qs.controls
import qs.settings

Column {
    spacing: 22

    SettingGroup {
        title: "BAR"

        SettingRow {
            title: "Show the bar"
            description: "A bar along an edge of every screen"
            Toggle {
                checked: Settings.opts.barEnabled
                onToggled: v => Settings.set("barEnabled", v)
            }
        }
    }

    BarLayout {
        visible: Settings.opts.barEnabled
        width: parent.width
    }

    EdgeSettings {
        visible: Settings.opts.barEnabled
        width: parent.width
        prefix: "bar"
        noun: "bar"
        edges: [{ value: "top", label: "Top" }, { value: "bottom", label: "Bottom" }, { value: "left", label: "Left" }, { value: "right", label: "Right" }]
        takenEdge: Settings.opts.dockEdge
        sizeFrom: 24
        sizeTo: 56
        islands: true
    }
}
