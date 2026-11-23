// SPDX-License-Identifier: GPL-3.0-or-later
// Dark background with two soft glows, slowly drifting.
import QtQuick
import QtQuick.Shapes

Item {
    id: bd

    property color accent

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

    Glow {
        tint: bd.accent
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
            loops: Animation.Infinite
            NumberAnimation { to: 1; duration: 14000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0; duration: 14000; easing.type: Easing.InOutSine }
        }
    }
}
