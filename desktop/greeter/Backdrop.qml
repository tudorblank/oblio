// SPDX-License-Identifier: GPL-3.0-or-later
// The user's lock screen wallpaper, a little dimmed; without one, two soft glows drifting slowly.
import QtQuick
import QtQuick.Shapes

Item {
    id: bd

    required property QtObject theme
    property string source
    readonly property bool hasPicture: picture.status === Image.Ready

    component Glow: Shape {
        id: g
        property color tint
        property real size
        width: size
        height: size
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: g.size / 2; centerY: g.size / 2
                centerRadius: g.size / 2
                focalX: centerX; focalY: centerY
                GradientStop { position: 0; color: Qt.rgba(g.tint.r, g.tint.g, g.tint.b, 0.30) }
                GradientStop { position: 0.5; color: Qt.rgba(g.tint.r, g.tint.g, g.tint.b, 0.10) }
                GradientStop { position: 1; color: "transparent" }
            }
            PathRectangle { width: g.size; height: g.size }
        }
    }

    Item {
        anchors.fill: parent
        visible: !bd.hasPicture

        Glow {
            tint: bd.theme.accent
            size: Math.max(bd.width, bd.height) * 0.9
            x: bd.width * 0.62 - size / 2 + drift.value * 40
            y: bd.height * 0.85 - size / 2
        }

        Glow {
            tint: "#3b4cca"
            size: Math.max(bd.width, bd.height) * 0.8
            x: bd.width * 0.2 - size / 2 - drift.value * 40
            y: bd.height * 0.15 - size / 2
        }

        Item {
            id: drift
            property real value: 0
            SequentialAnimation on value {
                running: !bd.hasPicture
                loops: Animation.Infinite
                NumberAnimation { to: 1; duration: 14000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0; duration: 14000; easing.type: Easing.InOutSine }
            }
        }
    }

    Image {
        id: picture
        anchors.fill: parent
        source: bd.width > 0 ? bd.source : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(bd.width, bd.height)
        asynchronous: true
        cache: false
        opacity: bd.hasPicture ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    }

    // keeps the clock and the card readable on bright pictures
    Rectangle {
        anchors.fill: parent
        visible: bd.hasPicture
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.28) }
            GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.08) }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.32) }
        }
    }
}
