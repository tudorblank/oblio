// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.services

Item {
    id: s

    property real value
    property real from: 0
    property real to: 100
    property real step: 1
    property int decimals: 0
    property string unit: ""
    signal moved(real value)

    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))

    implicitWidth: 250
    implicitHeight: 24

    Item {
        id: track
        anchors.left: parent.left
        anchors.right: label.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        height: 18

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Theme.control
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: knob.x + knob.width / 2
            height: 4
            radius: 2
            color: Theme.accent
        }

        Rectangle {
            id: knob
            anchors.verticalCenter: parent.verticalCenter
            x: s.frac * (parent.width - width)
            width: 16
            height: 16
            radius: 8
            color: Theme.knob
            scale: area.pressed ? 1.2 : area.containsMouse ? 1.08 : 1

            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            function pick(mx) {
                const f = Math.max(0, Math.min(1, (mx - 6 - knob.width / 2) / (track.width - knob.width)))
                const v = Number((s.from + Math.round(f * (s.to - s.from) / s.step) * s.step).toFixed(s.decimals))
                if (v !== s.value) s.moved(v)
            }

            onPressed: m => pick(m.x)
            onPositionChanged: m => { if (pressed) pick(m.x) }
        }
    }

    Text {
        font.family: Theme.fontUi
        id: label
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        horizontalAlignment: Text.AlignRight
        text: s.value.toFixed(s.decimals) + s.unit
        color: Theme.subtext
        font.pixelSize: 12
        font.features: { "tnum": 1 }
    }
}
