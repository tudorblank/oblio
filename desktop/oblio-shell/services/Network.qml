// SPDX-License-Identifier: GPL-3.0-or-later
// The network as Oblio's base sets it up: systemd-networkd for cables, iwd for Wi-Fi. Read over
// D-Bus (busctl, as JSON) and networkctl; Wi-Fi actions go through iwctl. It polls only while
// something shows it (hold/release), more often while a network list is open (scanning), and
// right after every action.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // who shows it / has a network list open; adding or removing twice changes nothing
    property var holders: []
    property var listers: []
    function hold(who) { if (!holders.includes(who)) holders = holders.concat([who]) }
    function release(who) { holders = holders.filter(h => h !== who); listing(who, false) }
    function listing(who, open) {
        const has = listers.includes(who)
        if (open && !has) { listers = listers.concat([who]); error = ""; scan() }
        else if (!open && has) listers = listers.filter(l => l !== who)
    }

    // cable: plugged in, and working (an address and a route)
    property bool cable: false
    property bool wired: false
    // Wi-Fi: the iwd device, its station
    property string device: ""          // wlan0
    property string devicePath: ""
    property bool wifiPowered: false
    property string wifiState: ""       // connected | connecting | disconnected | roaming ...
    property bool scanning: false
    property string ssid: ""
    property int strength: 0            // 0..4
    // in range, strongest first: { name, path, security (open|psk|8021x), known, connected, strength }
    property var networks: []
    property string busy: ""            // the network being connected to
    property string error: ""

    readonly property bool online: wired || wifiState === "connected"

    function bars(dbm100) { return dbm100 >= -6000 ? 4 : dbm100 >= -6700 ? 3 : dbm100 >= -7500 ? 2 : 1 }
    function prop(v) { return v && v.data !== undefined ? v.data : v }

    function refresh() {
        if (!objects.running) objects.running = true
        if (!links.running) links.running = true
    }
    // false when another action is still running
    function run(args) {
        if (action.running) return false
        error = ""
        action.command = args
        action.running = true
        return true
    }
    function connect(name, passphrase) {
        if (run(passphrase ? ["iwctl", "--passphrase", passphrase, "station", device, "connect", name]
                       : ["iwctl", "station", device, "connect", name])) busy = name
    }
    function disconnect() { run(["iwctl", "station", device, "disconnect"]) }
    function forget(name) { run(["iwctl", "known-networks", name, "forget"]) }
    function setPowered(on) { run(["iwctl", "device", device, "set-property", "Powered", on ? "on" : "off"]) }
    function scan() { if (device && wifiPowered) Quickshell.execDetached(["iwctl", "station", device, "scan"]) }

    Timer {
        running: root.holders.length > 0
        interval: root.listers.length > 0 ? 2500 : 6000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: links
        command: ["networkctl", "list", "--json=short"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const ifs = JSON.parse(text).Interfaces.filter(i => i.Type === "ether")
                    root.cable = ifs.some(i => i.CarrierState === "carrier" || i.OperationalState === "routable")
                    root.wired = ifs.some(i => i.OperationalState === "routable")
                } catch (e) {}
            }
        }
    }

    // everything iwd knows: devices, stations, networks, saved networks
    Process {
        id: objects
        command: ["busctl", "--json=short", "call", "net.connman.iwd", "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"]
        stdout: StdioCollector {
            onStreamFinished: {
                let all
                try { all = JSON.parse(text).data[0] } catch (e) { root.device = ""; return }
                const nets = {}
                let dev = null, station = null
                for (const path in all) {
                    const o = all[path]
                    if (o["net.connman.iwd.Device"] && !dev) dev = { path, d: o["net.connman.iwd.Device"], s: o["net.connman.iwd.Station"] }
                    if (o["net.connman.iwd.Network"]) nets[path] = o["net.connman.iwd.Network"]
                }
                root.device = dev ? root.prop(dev.d.Name) : ""
                root.devicePath = dev ? dev.path : ""
                root.wifiPowered = dev ? root.prop(dev.d.Powered) === true : false
                station = dev ? dev.s : null
                root.wifiState = station ? root.prop(station.State) : ""
                root.scanning = station ? root.prop(station.Scanning) === true : false
                const connectedPath = station ? root.prop(station.ConnectedNetwork) : ""
                root.ssid = connectedPath && nets[connectedPath] ? root.prop(nets[connectedPath].Name) : ""
                root.pending = nets
                if (station) {
                    ordered.command = ["busctl", "--json=short", "call", "net.connman.iwd", root.devicePath,
                                       "net.connman.iwd.Station", "GetOrderedNetworks"]
                    if (!ordered.running) ordered.running = true
                } else {
                    root.networks = []
                    root.strength = 0
                }
            }
        }
    }
    property var pending: ({})

    // networks in range with their signal, strongest first
    Process {
        id: ordered
        stdout: StdioCollector {
            onStreamFinished: {
                let list
                try { list = JSON.parse(text).data[0] } catch (e) { return }
                const nets = root.pending
                const out = []
                for (const [path, dbm] of list) {
                    const n = nets[path]
                    if (!n) continue
                    out.push({
                        name: root.prop(n.Name), path, security: root.prop(n.Type),
                        known: n.KnownNetwork !== undefined, connected: root.prop(n.Connected) === true,
                        strength: root.bars(dbm),
                    })
                }
                root.networks = out
                const c = out.find(n => n.connected)
                root.strength = c ? c.strength : 0
            }
        }
    }

    Process {
        id: action
        stdout: StdioCollector { id: actionOut }
        stderr: StdioCollector { id: actionErr }
        onExited: code => {
            const said = (actionErr.text + "\n" + actionOut.text).replace(/\x1b\[[0-9;]*m/g, "").trim()
            if (code !== 0) root.error = said || "That didn't work"
            root.busy = ""
            root.refresh()
        }
    }
}
