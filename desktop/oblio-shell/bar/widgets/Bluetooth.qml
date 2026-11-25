// SPDX-License-Identifier: GPL-3.0-or-later
// Bluetooth (BlueZ): on or off, connected devices. The popup lists paired devices (click to
// connect or disconnect) and, while it's open, looks for new ones (click to pair).
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.controls
import qs.bar

BarWidget {
    id: w

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter !== null && adapter.enabled
    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var connected: devices.filter(d => d.connected)
    function device(address) { return devices.find(d => d.address === address) ?? null }
    // the name other devices see this computer by (BlueZ's alias; Quickshell only reads it)
    function rename(name) {
        name = name.trim()
        if (adapter && name) Quickshell.execDetached(["busctl", "set-property", "org.bluez", adapter.dbusPath, "org.bluez.Adapter1", "Alias", "s", name])
    }

    // looks for devices while the list is open; BlueZ only takes that once the adapter is on
    readonly property bool looking: on && popupOpen
    onLookingChanged: if (adapter) adapter.discovering = looking
    Component.onDestruction: if (looking) adapter.discovering = false

    length: adapter ? row.length : 0
    popup: panel
    popupWidth: 320

    IconValue {
        id: row
        widget: w
        icon: !w.on ? Icons.bluetoothOff : w.connected.length ? Icons.bluetoothConnected : Icons.bluetooth
        readonly property var first: w.connected[0] ?? null
        value: !first ? "" : [w.opt("name") ? first.name : "",
                              w.opt("battery") && first.batteryAvailable ? Math.round(first.battery * 100) + "%" : ""].filter(s => s).join("  ")
        showValue: !w.vertical
        color: w.on ? Theme.text : Theme.subtext
    }

    // one device, looked up by address so the row survives the list changing
    component Device: ListRow {
        required property string modelData
        readonly property var d: w.device(modelData)
        visible: d !== null
        icon: d ? Icons.device(d.icon) : Icons.bluetooth
        title: d ? (d.name || d.address) : ""
        active: d !== null && d.connected
        subtitle: !d ? ""
            : d.pairing ? "Pairing…"
            : d.state === BluetoothDeviceState.Connecting ? "Connecting…"
            : d.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
            : d.connected ? "Connected" + (d.batteryAvailable ? ` · ${Math.round(d.battery * 100)}%` : "")
            : d.paired ? "" : "Click to pair"
        onClicked: {
            if (d.connected) d.disconnect()
            else if (d.paired) d.connect()
            else { d.trusted = true; d.pair() }
        }

        IconButton {
            visible: d !== null && d.paired
            size: 26
            icon: Icons.forget
            onClicked: d.forget()
        }
    }

    Component {
        id: panel

        Column {
            spacing: 2
            topPadding: 4
            bottomPadding: 4

            PopupHeader {
                title: "Bluetooth"
                subtitle: !w.adapter ? "No Bluetooth adapter" : !w.on ? "Off"
                    : w.connected.length ? `Connected to ${w.connected.map(d => d.name).join(", ")}`
                    : w.adapter.discovering ? "Looking for devices…" : "On"
                Toggle {
                    visible: w.adapter !== null
                    checked: w.on
                    onToggled: v => w.adapter.enabled = v
                }
            }

            // this computer: its name for others, and whether they can find it
            Column {
                visible: w.on
                x: 10
                width: parent.width - 20
                spacing: 6
                bottomPadding: 6

                Item {
                    width: parent.width
                    height: Theme.controlHeight
                    Text {
                        id: nameLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Name"
                        color: Theme.text
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.textLabel
                    }
                    TextBox {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - nameLabel.width - 16
                        value: w.adapter ? w.adapter.name : ""
                        placeholder: "This computer's name"
                        onEdited: v => w.rename(v)
                    }
                }
                Item {
                    width: parent.width
                    height: 28
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Visible to nearby devices"
                        color: Theme.text
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.textLabel
                    }
                    Toggle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: w.adapter !== null && w.adapter.discoverable
                        onToggled: v => w.adapter.discoverable = v
                    }
                }
            }

            Repeater {
                model: ScriptModel { values: w.on ? w.devices.filter(d => d.paired).map(d => d.address) : [] }
                Device {}
            }

            SectionLabel {
                visible: w.on
                leftPadding: 10
                topPadding: 8
                bottomPadding: 2
                text: "NEARBY"
            }
            Repeater {
                // unnamed devices only show an address: nobody recognizes those
                model: ScriptModel { values: w.on ? w.devices.filter(d => !d.paired && d.deviceName).map(d => d.address) : [] }
                Device {}
            }
            Text {
                visible: w.on && !w.devices.some(d => !d.paired && d.deviceName)
                leftPadding: 10
                bottomPadding: 6
                text: "Nothing new nearby yet"
                color: Theme.subtext
                font.family: Theme.fontUi
                font.pixelSize: Theme.textLabel
            }
        }
    }
}
