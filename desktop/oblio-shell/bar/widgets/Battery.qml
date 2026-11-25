// SPDX-License-Identifier: GPL-3.0-or-later
// Battery charge (UPower); the popup has the time left and the power profile. Hidden without a
// battery.
import QtQuick
import Quickshell.Services.UPower
import qs.services
import qs.controls
import qs.bar

BarWidget {
    id: w

    readonly property var device: UPower.displayDevice
    readonly property bool present: device !== null && device.isLaptopBattery
    readonly property int percent: present ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: present && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: present && device.state === UPowerDeviceState.FullyCharged
    readonly property bool low: present && !charging && percent <= 15

    readonly property string glyph: charging ? Icons.charging : Icons.battery[Math.round(percent / 10)]

    function duration(s) {
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
        return h > 0 ? `${h} h ${m} min` : `${m} min`
    }
    readonly property string status: !present ? ""
        : full ? "Fully charged"
        : charging ? (device.timeToFull > 0 ? `Charging, full in ${duration(device.timeToFull)}` : "Charging")
        : device.timeToEmpty > 0 ? `${duration(device.timeToEmpty)} left` : "On battery"

    length: present ? row.length : 0
    popup: panel

    IconValue {
        id: row
        widget: w
        icon: w.glyph
        value: w.percent + "%"
        showValue: w.opt("value")
        color: w.low ? Theme.danger : Theme.text
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
                    color: w.low ? Theme.danger : Theme.text
                    font.family: Theme.iconFont
                    font.pixelSize: 30
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: w.percent + "%"
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: w.status
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
