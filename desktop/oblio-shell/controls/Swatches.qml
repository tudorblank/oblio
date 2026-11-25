// SPDX-License-Identifier: GPL-3.0-or-later
// Accent colors, and a color picker for any other one.
import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.services

Row {
    id: sw

    property string value
    property var colors: [Theme.defaultAccent, "#5b9cf5", "#a78bfa", "#f472b6", "#ef5350", "#fb923c", "#facc15", "#2dd4bf", "#e4e4e7"]
    property string pickerTitle: "Accent color"
    signal picked(string value)

    spacing: 8

    Repeater {
        model: sw.colors

        Rectangle {
            required property string modelData
            readonly property bool selected: modelData.toLowerCase() === sw.value.toLowerCase()
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26
            radius: 13
            color: "transparent"
            border.width: 2
            border.color: selected ? Theme.text : "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: 18
                height: 18
                radius: 9
                color: parent.modelData
                scale: area.containsMouse ? 1.12 : 1

                Behavior on scale { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sw.picked(parent.modelData)
            }
        }
    }

    // any other color: a rainbow ring that opens the picker, showing the color when it's a custom one
    Rectangle {
        id: custom
        readonly property bool selected: !sw.colors.some(c => c.toLowerCase() === sw.value.toLowerCase())
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        radius: 13
        color: "transparent"
        border.width: 2
        border.color: selected ? Theme.text : "transparent"

        Item {
            anchors.centerIn: parent
            width: 18
            height: 18
            scale: customArea.containsMouse ? 1.12 : 1
            Behavior on scale { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillGradient: ConicalGradient {
                        centerX: 9; centerY: 9
                        GradientStop { position: 0 / 6; color: "#ff5f5f" }
                        GradientStop { position: 1 / 6; color: "#ffe15f" }
                        GradientStop { position: 2 / 6; color: "#6fe86f" }
                        GradientStop { position: 3 / 6; color: "#5fe0e8" }
                        GradientStop { position: 4 / 6; color: "#6f7fff" }
                        GradientStop { position: 5 / 6; color: "#e86fe8" }
                        GradientStop { position: 6 / 6; color: "#ff5f5f" }
                    }
                    PathAngleArc { centerX: 9; centerY: 9; radiusX: 9; radiusY: 9; startAngle: 0; sweepAngle: 360 }
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 5
                color: custom.selected ? sw.value : Theme.popup
            }
        }

        MouseArea {
            id: customArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: picker.open(sw.value, QsWindow.window?.screen)
        }
    }

    ColorPicker {
        id: picker
        title: sw.pickerTitle
        onPicked: v => sw.picked(v)
    }
}
