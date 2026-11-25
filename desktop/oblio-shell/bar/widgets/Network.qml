// SPDX-License-Identifier: GPL-3.0-or-later
// Cable and Wi-Fi (services/Network.qml): the icon says which and how strong. The popup turns
// Wi-Fi on or off and lists the networks in range: click one to connect (a new secured one asks
// for its password). Disconnecting and forgetting have their own buttons and ask for a second
// click: a stray click never drops the connection.
import QtQuick
import Quickshell
import qs.services
import qs.controls
import qs.bar

BarWidget {
    id: w

    readonly property string glyph: Network.wired ? Icons.ethernet
        : Network.wifiState === "connected" ? Icons.wifi[Network.strength]
        : Network.device && !Network.wifiPowered ? Icons.wifiOff
        : Network.cable ? Icons.cableUnplugged : Icons.wifi[0]

    Component.onCompleted: Network.hold(w)
    Component.onDestruction: Network.release(w)
    onPopupOpenChanged: Network.listing(w, popupOpen)

    length: row.length
    popup: panel
    popupWidth: 320

    IconValue {
        id: row
        widget: w
        icon: w.glyph
        value: Network.wired ? "Wired" : Network.ssid
        showValue: w.opt("name") && !w.vertical
        color: Network.online ? Theme.text : Theme.subtext
    }

    Component {
        id: panel

        Column {
            id: list
            property string asking: ""          // the network whose password is being typed
            property string armed: ""           // "disconnect:NAME" / "forget:NAME": clicked once
            spacing: 2
            topPadding: 4
            bottomPadding: 4

            PopupHeader {
                title: "Wi-Fi"
                subtitle: !Network.device ? "No Wi-Fi device"
                    : !Network.wifiPowered ? "Off"
                    : Network.wifiState === "connected" ? `Connected to ${Network.ssid}`
                    : Network.busy ? `Connecting to ${Network.busy}…`
                    : Network.scanning ? "Looking for networks…" : "Not connected"
                Toggle {
                    visible: Network.device !== ""
                    checked: Network.wifiPowered
                    onToggled: v => Network.setPowered(v)
                }
            }

            ListRow {
                visible: Network.cable
                clickable: false
                icon: Icons.ethernet
                title: "Cable"
                subtitle: Network.wired ? "Connected" : "Plugged in, no connection"
                active: Network.wired
            }

            Divider { visible: Network.wifiPowered && Network.networks.length > 0 }

            Text {
                visible: Network.error !== ""
                x: 12
                width: parent.width - 24
                topPadding: 4
                bottomPadding: 4
                text: Network.error
                wrapMode: Text.Wrap
                color: Theme.danger
                font.family: Theme.fontUi
                font.pixelSize: Theme.textCaption
            }

            ListView {
                id: nets
                visible: Network.wifiPowered
                width: parent.width
                height: Math.min(contentHeight, 340)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 2
                // keyed by name: rows (and a password being typed) survive every poll
                model: ScriptModel { values: Network.networks.map(n => n.name) }

                delegate: Column {
                    id: net
                    required property string modelData
                    readonly property var n: Network.networks.find(x => x.name === modelData) ?? ({ name: modelData })
                    readonly property bool asking: list.asking === modelData
                    readonly property string armed: list.armed.endsWith(":" + modelData) ? list.armed.split(":")[0] : ""
                    width: nets.width

                    // asks once, acts on the second click
                    function twice(what, act) {
                        if (net.armed !== what) { list.armed = what + ":" + net.modelData; return }
                        list.armed = ""
                        act()
                    }

                    ListRow {
                        icon: Icons.wifi[net.n.strength ?? 0]
                        title: net.modelData
                        subtitle: net.armed === "disconnect" ? "Click again to disconnect"
                            : net.armed === "forget" ? "Click again to forget it"
                            : Network.busy === net.modelData ? "Connecting…"
                            : net.n.connected ? "Connected" : net.n.known ? "Saved" : ""
                        subtitleColor: net.armed ? Theme.danger : Theme.subtext
                        active: net.n.connected === true
                        clickable: !net.n.connected
                        onClicked: {
                            list.armed = ""
                            if (net.n.known || net.n.security === "open") Network.connect(net.modelData)
                            else list.asking = net.asking ? "" : net.modelData
                        }

                        Text {
                            visible: net.n.security !== "open"
                            anchors.verticalCenter: parent.verticalCenter
                            text: Icons.lock
                            color: Theme.subtext
                            font.family: Theme.iconFont
                            font.pixelSize: 12
                        }
                        IconButton {
                            visible: net.n.connected === true
                            size: 26
                            icon: Icons.disconnect
                            onClicked: net.twice("disconnect", () => Network.disconnect())
                        }
                        IconButton {
                            visible: net.n.known === true
                            size: 26
                            icon: Icons.forget
                            onClicked: net.twice("forget", () => Network.forget(net.modelData))
                        }
                    }

                    // a new secured network: its password
                    Row {
                        visible: net.asking
                        x: 12
                        spacing: 8
                        topPadding: 4
                        bottomPadding: 6
                        TextBox {
                            id: pass
                            width: net.width - 24 - connectButton.width - 8
                            password: true
                            placeholder: "Password"
                            onEdited: v => { if (v) { Network.connect(net.modelData, v); list.asking = "" } }
                            onVisibleChanged: if (visible) focusInput()
                        }
                        Button {
                            id: connectButton
                            text: "Connect"
                            primary: true
                            onClicked: pass.submit()
                        }
                    }
                }
            }
        }
    }
}
