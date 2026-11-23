// SPDX-License-Identifier: GPL-3.0-or-later
// Accent colors; "hyprland" is Hyprland's own cyan-to-green border.
import QtQuick

Row {
    id: sw

    property string value
    property var colors: ["hyprland", "#5b9cf5", "#a78bfa", "#f472b6", "#ef5350", "#fb923c", "#facc15", "#4ade80", "#2dd4bf", "#e4e4e7"]
    signal picked(string value)

    spacing: 8

    Repeater {
        model: sw.colors

        Rectangle {
            required property string modelData
            readonly property bool selected: modelData === sw.value
            width: 26
            height: 26
            radius: 13
            color: "transparent"
            border.width: 2
            border.color: selected ? "white" : "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: 18
                height: 18
                radius: 9
                color: parent.modelData === "hyprland" ? "#33ccff" : parent.modelData
                gradient: parent.modelData === "hyprland" ? hyprGradient : null
                scale: area.containsMouse ? 1.12 : 1

                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
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

    Gradient {
        id: hyprGradient
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: "#33ccff" }
        GradientStop { position: 1; color: "#00ff99" }
    }
}
