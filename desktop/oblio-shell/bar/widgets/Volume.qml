// SPDX-License-Identifier: GPL-3.0-or-later
// Speaker volume: scroll to change, middle click to mute; the popup has the speaker, the
// microphone and every app playing sound.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import qs.controls
import qs.bar

BarWidget {
    id: w

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    function glyph(v, m) { return Icons.volume[m || v <= 0 ? 0 : v < 0.34 ? 1 : v < 0.67 ? 2 : 3] }
    function setVolume(node, v) {
        if (!node || !node.audio) return
        node.audio.muted = false
        node.audio.volume = Math.max(0, Math.min(1, v))
    }
    function toggleMute(node) { if (node && node.audio) node.audio.muted = !node.audio.muted }

    PwObjectTracker { objects: [w.sink, w.source].filter(n => n) }

    length: sink ? row.length : 0
    popup: panel
    onScrolled: s => setVolume(sink, Math.round((volume + s * 0.05) * 20) / 20)
    onActivated: b => { if (b === Qt.MiddleButton) toggleMute(sink) }

    IconValue {
        id: row
        widget: w
        icon: w.glyph(w.volume, w.muted)
        value: Math.round(w.volume * 100) + "%"
        showValue: w.opt("value")
        color: w.muted ? Theme.subtext : Theme.text
    }

    Component {
        id: panel
        Column {
            id: card
            // apps playing sound: PipeWire playback streams (a stream that takes sound in: isSink),
            // tracked only while this is open; rows keyed by node id survive new streams
            readonly property var apps: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio)
            function app(id) { return apps.find(n => n.id === id) ?? null }
            PwObjectTracker { objects: card.apps }

            PopupSlider {
                icon: w.glyph(w.volume, w.muted)
                title: "Speaker"
                detail: w.sink ? (w.sink.description || w.sink.name) : ""
                value: Math.round(w.volume * 100)
                muted: w.muted
                canMute: true
                onMoved: v => w.setVolume(w.sink, v / 100)
                onToggled: w.toggleMute(w.sink)
            }
            PopupSlider {
                visible: w.source !== null
                readonly property bool off: w.source && w.source.audio ? w.source.audio.muted : false
                icon: off ? Icons.micOff : Icons.mic
                title: "Microphone"
                detail: w.source ? (w.source.description || w.source.name) : ""
                value: w.source && w.source.audio ? Math.round(w.source.audio.volume * 100) : 0
                muted: off
                canMute: true
                onMoved: v => w.setVolume(w.source, v / 100)
                onToggled: w.toggleMute(w.source)
            }

            Divider { space: 25 }
            SectionLabel {
                leftPadding: 8
                bottomPadding: 2
                text: card.apps.length ? "APPS" : "No app is playing sound"
                font.letterSpacing: card.apps.length ? 0.5 : 0
                font.weight: card.apps.length ? Font.DemiBold : Font.Normal
            }
            Repeater {
                model: ScriptModel { values: card.apps.map(n => n.id) }
                PopupSlider {
                    required property int modelData
                    readonly property var node: card.app(modelData)
                    readonly property var p: node ? node.properties : ({})
                    readonly property bool off: node && node.audio ? node.audio.muted : false
                    readonly property string name: p["application.name"] || (node ? node.description || node.name : "")
                    visible: node !== null
                    icon: Icons.music
                    image: Apps.icon(p["application.icon-name"] || p["application.process.binary"] || name)
                    title: name
                    detail: p["media.name"] || ""
                    value: node && node.audio ? Math.round(node.audio.volume * 100) : 0
                    muted: off
                    canMute: true
                    onMoved: v => w.setVolume(node, v / 100)
                    onToggled: w.toggleMute(node)
                }
            }
        }
    }
}
