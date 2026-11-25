// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > Battery: the alerts (services/Battery.qml).
import QtQuick
import qs.services
import qs.controls
import qs.settings

Column {
    spacing: 22

    SettingGroup {
        title: "NOW"
        SettingRow {
            title: Battery.present ? Battery.percent + "%  ·  " + Battery.state : "No battery"
            description: Battery.present ? (Battery.estimate ? Battery.estimate.charAt(0).toUpperCase() + Battery.estimate.slice(1) : "Working out the time left…")
                                         : "This computer has no battery to watch"
        }
    }

    SettingGroup {
        title: "ALERTS"
        enabled: Battery.present
        opacity: enabled ? 1 : Theme.disabledOpacity

        SettingRow {
            title: "Low battery"
            description: "A notification when the charge drops to this level while it's running on battery"
            Toggle {
                checked: Settings.opts.batteryAlertLow
                onToggled: v => Settings.set("batteryAlertLow", v)
            }
        }
        SettingRow {
            title: "Low level"
            ValueSlider {
                from: 5
                to: 50
                step: 5
                unit: " %"
                muted: !Settings.opts.batteryAlertLow
                value: Settings.opts.batteryLow
                onMoved: v => Settings.set("batteryLow", Math.round(v))
            }
        }
        SettingRow {
            title: "Charged"
            description: "A notification when the charge reaches this level while it's charging. Keeping a battery below full makes it last longer"
            Toggle {
                checked: Settings.opts.batteryAlertHigh
                onToggled: v => Settings.set("batteryAlertHigh", v)
            }
        }
        SettingRow {
            title: "Charged level"
            ValueSlider {
                from: 50
                to: 100
                step: 5
                unit: " %"
                muted: !Settings.opts.batteryAlertHigh
                value: Settings.opts.batteryHigh
                onMoved: v => Settings.set("batteryHigh", Math.round(v))
            }
        }
    }
}
