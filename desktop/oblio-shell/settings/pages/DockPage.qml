// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Dock: the edge panel settings (EdgeSettings), then what only the dock has.
import QtQuick
import qs.services
import qs.controls
import qs.settings

Column {
    spacing: 22

    EdgeSettings {
        width: parent.width
        prefix: "dock"
        noun: "dock"
        edges: [{ value: "top", label: "Top" }, { value: "bottom", label: "Bottom" }, { value: "left", label: "Left" }, { value: "right", label: "Right" }]
        takenEdge: Settings.opts.barEnabled ? Settings.opts.barEdge : ""
        sizeFrom: 40
        sizeTo: 96
    }

    SettingGroup {
        title: "ICONS"

        SettingRow {
            id: position
            readonly property bool side: Settings.opts.dockEdge === "left" || Settings.opts.dockEdge === "right"
            visible: Settings.opts.dockShape === "full" || Settings.opts.dockLength === "fixed"
            title: "Position"
            description: "Where the icons sit along the dock"
            Segmented {
                options: [{ value: "start", label: position.side ? "Top" : "Left" },
                          { value: "center", label: "Center" },
                          { value: "end", label: position.side ? "Bottom" : "Right" }]
                value: Settings.opts.dockAlign
                onPicked: v => Settings.set("dockAlign", v)
            }
        }

        SettingRow {
            title: "Magnify on hover"
            Toggle {
                checked: Settings.opts.dockMagnify
                onToggled: v => Settings.set("dockMagnify", v)
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
