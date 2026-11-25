// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Display: resolution, refresh rate, scale, rotation; arrangement with more than one screen.
import QtQuick
import qs.services
import qs.controls
import qs.settings

Column {
    id: dp
    spacing: 22

    readonly property var monitors: Displays.monitors
    readonly property var mon: Displays.current
    readonly property var cfg: Displays.edited
    readonly property bool multi: monitors.length > 1
    readonly property int enabledCount: monitors.filter(m => !m.disabled).length
    readonly property real recommended: mon && cfg ? Displays.recommended(mon, cfg.resolution) : 1

    function edit(changes) { Displays.edit(changes) }
    function percent(s) { return Math.round(s * 100) + "%" }
    function looks(res, s) {
        const [w, h] = res.split("x").map(Number)
        return `${Math.round(w / s)} × ${Math.round(h / s)}`
    }

    Text {
        font.family: Theme.fontUi
        visible: !dp.mon
        text: "No displays found"
        color: Theme.subtext
        font.pixelSize: Theme.textBody
    }

    Segmented {
        visible: dp.multi
        options: dp.monitors.map((m, i) => ({ value: i, label: Displays.label(m) }))
        value: Displays.selected
        onPicked: v => Displays.selected = v
    }

    SettingGroup {
        visible: dp.mon !== null
        title: dp.mon ? [Displays.label(dp.mon).toUpperCase(), Displays.label(dp.mon) === dp.mon.name ? "" : dp.mon.name,
            Displays.inches(dp.mon) ? Displays.inches(dp.mon).toFixed(1) + "″" : ""].filter(t => t).join("  ·  ") : ""

        SettingRow {
            title: "Resolution"
            Dropdown {
                enabled: dp.cfg && !dp.cfg.disabled && !dp.cfg.mirror
                options: dp.mon ? Displays.resolutions(dp.mon).map(r => ({
                    value: r.value, label: r.value.replace("x", " × "), tag: r.native ? "Native" : "",
                })) : []
                value: dp.cfg ? dp.cfg.resolution : ""
                onPicked: v => dp.edit({
                    resolution: v,
                    rate: Displays.closestRate(dp.mon, v, dp.cfg.rate),
                    scale: Displays.scales(v).includes(dp.cfg.scale) ? dp.cfg.scale : Displays.recommended(dp.mon, v),
                })
            }
        }
        SettingRow {
            title: "Refresh rate"
            Dropdown {
                enabled: dp.cfg && !dp.cfg.disabled && !dp.cfg.mirror
                options: dp.cfg ? Displays.rates(dp.mon, dp.cfg.resolution).map(r => ({
                    value: r, label: (Math.round(r * 100) / 100) + " Hz",
                })) : []
                value: dp.cfg ? dp.cfg.rate : 0
                onPicked: v => dp.edit({ rate: v })
            }
        }
        SettingRow {
            title: "Scale"
            description: dp.cfg ? `How big everything is. At ${dp.percent(dp.cfg.scale)} the screen fits as much as a ${dp.looks(dp.cfg.resolution, dp.cfg.scale)} one` : ""
            Dropdown {
                enabled: dp.cfg && !dp.cfg.disabled && !dp.cfg.mirror
                options: dp.cfg ? Displays.scales(dp.cfg.resolution).map(s => ({
                    value: s,
                    label: dp.percent(s),
                    tag: s === dp.recommended ? "Recommended" : "",
                    note: dp.looks(dp.cfg.resolution, s),
                })) : []
                value: dp.cfg ? dp.cfg.scale : 1
                onPicked: v => dp.edit({ scale: v })
            }
        }
        SettingRow {
            title: "Rotation"
            Segmented {
                enabled: dp.cfg && !dp.cfg.disabled && !dp.cfg.mirror
                options: [{ value: 0, label: "Normal" }, { value: 1, label: "90°" }, { value: 2, label: "180°" }, { value: 3, label: "270°" }]
                value: dp.cfg ? dp.cfg.transform : 0
                onPicked: v => dp.edit({ transform: v })
            }
        }
    }

    SettingGroup {
        visible: dp.multi && dp.mon !== null
        title: "ARRANGEMENT"

        SettingRow {
            title: "Use this display"
            description: dp.cfg && !dp.cfg.disabled && dp.enabledCount <= 1 ? "The only display that's on can't be turned off" : ""
            Toggle {
                enabled: dp.cfg && (dp.cfg.disabled || dp.enabledCount > 1)
                checked: dp.cfg ? !dp.cfg.disabled : true
                onToggled: v => dp.edit({ disabled: !v })
            }
        }
        SettingRow {
            title: "Position"
            description: "Where it sits next to the other displays"
            Segmented {
                enabled: dp.cfg && !dp.cfg.disabled && !dp.cfg.mirror
                options: [{ value: "auto", label: "Auto" }, { value: "auto-left", label: "Left" }, { value: "auto-right", label: "Right" },
                          { value: "auto-up", label: "Above" }, { value: "auto-down", label: "Below" }]
                value: dp.cfg ? dp.cfg.position : "auto"
                onPicked: v => dp.edit({ position: v })
            }
        }
        SettingRow {
            title: "Mirror"
            description: "Show the same picture as another display"
            Dropdown {
                enabled: dp.cfg && !dp.cfg.disabled
                options: [{ value: "", label: "Off" }].concat(dp.monitors
                    .filter(m => dp.mon && m.name !== dp.mon.name && !m.disabled)
                    .map(m => ({ value: m.name, label: Displays.label(m), note: m.name })))
                value: dp.cfg ? dp.cfg.mirror : ""
                onPicked: v => dp.edit({ mirror: v })
            }
        }
    }

    // room for the floating apply bar under the last row
    Item {
        visible: dp.mon !== null
        width: parent.width
        height: 30 + 56

        Button {
            text: "Use defaults"
            enabled: Displays.pending === null
            onClicked: { Displays.discard(); Displays.reset(dp.mon) }
        }
    }
}
