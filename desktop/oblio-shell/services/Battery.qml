// SPDX-License-Identifier: GPL-3.0-or-later
// The laptop battery (UPower): charge, charging or not, time left, and the battery alerts
// (Settings > Battery): one notification when the charge drops to the low level while
// discharging, one when it reaches the high level while charging. Each fires once per crossing.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device !== null && device.isLaptopBattery
    readonly property int percent: present ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: present && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge)
    readonly property bool discharging: present && (device.state === UPowerDeviceState.Discharging || device.state === UPowerDeviceState.PendingDischarge)
    readonly property bool full: present && device.state === UPowerDeviceState.FullyCharged
    // seconds until full while charging, until empty while discharging; 0 when UPower doesn't know yet
    readonly property real timeLeft: !present ? 0 : charging ? device.timeToFull : discharging ? device.timeToEmpty : 0

    function duration(s) {
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
        return h > 0 ? `${h} h ${m} min` : `${m} min`
    }
    // "1:05": short, for the bar
    function short(s) {
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
        return `${h}:${String(m).padStart(2, "0")}`
    }
    readonly property string state: !present ? "" : full ? "Fully charged" : charging ? "Charging"
        : discharging ? "Discharging" : "Plugged in, not charging"
    readonly property string estimate: timeLeft <= 0 ? ""
        : charging ? `full in ${duration(timeLeft)}` : `${duration(timeLeft)} left`

    function notify(title, body, urgency, icon) {
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", urgency, "-i", icon, title, body])
    }

    // the levels crossed: an alert fires when its side becomes true, and again only after it was false
    // (also when the shell starts on the other side of one)
    readonly property bool low: discharging && percent <= Settings.opts.batteryLow
    readonly property bool high: charging && percent >= Settings.opts.batteryHigh
    function alertLow() {
        if (low && Settings.opts.batteryAlertLow)
            notify("Battery low", `${percent}% left${timeLeft > 0 ? ", about " + duration(timeLeft) : ""}. Plug in the charger.`,
                   "critical", "battery-caution")
    }
    function alertHigh() {
        if (high && Settings.opts.batteryAlertHigh)
            notify("Battery charged", `It reached ${percent}%. Unplugging now is easier on the battery.`, "normal", "battery-full-charging")
    }
    onLowChanged: alertLow()
    onHighChanged: alertHigh()
    Component.onCompleted: { alertLow(); alertHigh() }
}
