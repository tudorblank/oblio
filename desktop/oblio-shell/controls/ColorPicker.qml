// SPDX-License-Identifier: GPL-3.0-or-later
// A color picker in its own window over everything: a wheel (hue around, saturation outward),
// brightness, and the hex code. open(color); picked(hex) on Apply.
import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.services

Scope {
    id: cp

    property string title: "Color"
    property alias shown: overlay.shown
    property string initial: "#ffffff"
    property real hue: 0
    property real sat: 0
    property real val: 1
    readonly property color current: Qt.hsva(hue, sat, val, 1)
    readonly property string hex: String(current).slice(0, 7)
    signal picked(string hex)

    function open(value, screen) {
        initial = value
        setHex(value)
        overlay.open(screen)
    }
    function setHex(value) {
        const c = Qt.color(value)
        if (c.hsvHue >= 0) hue = c.hsvHue
        sat = c.hsvSaturation
        val = c.hsvValue
    }
    function apply() {
        picked(hex)
        shown = false
    }

    Overlay {
        id: overlay
        part: "menus"
        fading: card

        Card {
            id: card
            part: "menus"
            anchors.centerIn: parent
            width: 320
            height: content.implicitHeight + 2 * 20
            opacity: cp.shown ? 1 : 0
            scale: cp.shown ? 1 : 0.96
            focus: cp.shown

            Behavior on opacity { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }

            Keys.onEscapePressed: cp.shown = false
            Keys.onReturnPressed: cp.apply()

            MouseArea { anchors.fill: parent }

            Column {
                id: content
                x: 20
                y: 20
                width: parent.width - 40
                spacing: 18

                Text {
                    text: cp.title
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textTitle + 2
                    font.weight: Font.DemiBold
                }

                // hue around the circle, white in the middle, darkened by brightness
                Item {
                    id: wheel
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 220
                    height: 220
                    readonly property real r: width / 2

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeWidth: -1
                            fillGradient: ConicalGradient {
                                centerX: wheel.r; centerY: wheel.r
                                angle: 0
                                GradientStop { position: 0 / 6; color: "#ff0000" }
                                GradientStop { position: 1 / 6; color: "#ffff00" }
                                GradientStop { position: 2 / 6; color: "#00ff00" }
                                GradientStop { position: 3 / 6; color: "#00ffff" }
                                GradientStop { position: 4 / 6; color: "#0000ff" }
                                GradientStop { position: 5 / 6; color: "#ff00ff" }
                                GradientStop { position: 6 / 6; color: "#ff0000" }
                            }
                            PathAngleArc { centerX: wheel.r; centerY: wheel.r; radiusX: wheel.r; radiusY: wheel.r; startAngle: 0; sweepAngle: 360 }
                        }
                        ShapePath {
                            strokeWidth: -1
                            fillGradient: RadialGradient {
                                centerX: wheel.r; centerY: wheel.r; centerRadius: wheel.r
                                focalX: wheel.r; focalY: wheel.r
                                GradientStop { position: 0; color: "#ffffffff" }
                                GradientStop { position: 1; color: "#00ffffff" }
                            }
                            PathAngleArc { centerX: wheel.r; centerY: wheel.r; radiusX: wheel.r; radiusY: wheel.r; startAngle: 0; sweepAngle: 360 }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "black"
                        opacity: 1 - cp.val
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.hairline
                    }

                    Rectangle {
                        x: wheel.r + Math.cos(cp.hue * 2 * Math.PI) * cp.sat * wheel.r - width / 2
                        y: wheel.r - Math.sin(cp.hue * 2 * Math.PI) * cp.sat * wheel.r - height / 2
                        width: 20
                        height: 20
                        radius: 10
                        color: cp.current
                        border.width: 3
                        border.color: "white"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.CrossCursor
                        preventStealing: true
                        function pick(m) {
                            const dx = m.x - wheel.r, dy = m.y - wheel.r
                            cp.sat = Math.min(1, Math.hypot(dx, dy) / wheel.r)
                            cp.hue = ((Math.atan2(-dy, dx) / (2 * Math.PI)) + 1) % 1
                        }
                        onPressed: m => pick(m)
                        onPositionChanged: m => pick(m)
                    }
                }

                // brightness
                Item {
                    width: parent.width
                    height: 20

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 12
                        radius: 6
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "black" }
                            GradientStop { position: 1; color: Qt.hsva(cp.hue, cp.sat, 1, 1) }
                        }
                        border.width: 1
                        border.color: Theme.hairline
                    }
                    Rectangle {
                        x: cp.val * (parent.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20
                        radius: 10
                        color: cp.current
                        border.width: 3
                        border.color: "white"
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        function pick(m) { cp.val = Math.max(0, Math.min(1, (m.x - 6 - 10) / (width - 12 - 20))) }
                        onPressed: m => pick(m)
                        onPositionChanged: m => pick(m)
                    }
                }

                // before | after, and the code
                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 72
                        height: Theme.controlHeight
                        radius: height / 2
                        color: cp.initial
                        border.width: 1
                        border.color: Theme.hairline
                        Rectangle {
                            anchors.right: parent.right
                            width: parent.width / 2
                            height: parent.height
                            radius: parent.radius
                            color: cp.current
                            Rectangle { width: parent.radius; height: parent.height; color: parent.color }
                        }
                        MouseArea {
                            anchors.left: parent.left
                            width: parent.width / 2
                            height: parent.height
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cp.setHex(cp.initial)
                        }
                    }

                    TextBox {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 72 - 10
                        mono: true
                        value: cp.hex
                        onEdited: v => {
                            const h = (v.trim().startsWith("#") ? v.trim() : "#" + v.trim()).toLowerCase()
                            if (/^#[0-9a-f]{6}$/.test(h)) cp.setHex(h)
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: 8
                    Button { text: "Cancel"; onClicked: cp.shown = false }
                    Button { text: "Apply"; primary: true; onClicked: cp.apply() }
                }
            }
        }
    }
}
