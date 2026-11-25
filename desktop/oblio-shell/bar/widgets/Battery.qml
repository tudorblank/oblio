// SPDX-License-Identifier: GPL-3.0-or-later
// Battery charge (services/Battery.qml): the charging glyph while it charges, the time left if
// asked; the popup says charging or discharging and until when, and has the power profile.
// Hidden without a battery.
import QtQuick
import Quickshell.Services.UPower
import qs.services
import qs.controls
import qs.bar

BarWidget {
    id: w

    readonly property string glyph: Battery.charging ? Icons.charging : Icons.battery[Math.round(Battery.percent / 10)]
    readonly property color tone: Battery.low ? Theme.danger : Theme.text

    length: Battery.present ? row.length : 0
    popup: panel

    IconValue {
        id: row
        widget: w
        icon: w.glyph
        value: [w.opt("value") ? Battery.percent + "%" : "",
                w.opt("time") && Battery.timeLeft > 0 ? Battery.short(Battery.timeLeft) : ""].filter(s => s).join("  ")
        color: w.tone
    }

    Component {
        id: panel
        Column {
            spacing: 12
            topPadding: 8
            bottomPadding: 8

            Row {
                x: 8
                spacing: 12
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: w.glyph
                    color: w.tone
                    font.family: Theme.iconFont
                    font.pixelSize: 30
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: Battery.percent + "%"
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: Battery.state + (Battery.estimate ? " · " + Battery.estimate : "")
                        color: Theme.subtext
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.textLabel
                    }
                }
            }

            Column {
                x: 8
                width: parent.width - 16
                spacing: 8
                Text {
                    text: "Power profile"
                    color: Theme.subtext
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textLabel
                    font.weight: Font.DemiBold
                }
                Segmented {
                    options: [
                        { value: PowerProfile.PowerSaver, label: "Saver" },
                        { value: PowerProfile.Balanced, label: "Balanced" },
                        { value: PowerProfile.Performance, label: "Performance", disabled: !PowerProfiles.hasPerformanceProfile },
                    ]
                    value: PowerProfiles.profile
                    onPicked: v => PowerProfiles.profile = v
                }
            }
        }
    }
}
