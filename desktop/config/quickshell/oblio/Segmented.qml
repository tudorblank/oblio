// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

Rectangle {
    id: seg

    property var options: []    // [{ value, label }]
    property var value
    signal picked(var value)

    implicitWidth: row.implicitWidth + 6
    implicitHeight: 30
    radius: height / 2
    color: Theme.card
    border.width: 1
    border.color: Theme.hairline

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: seg.options

            Rectangle {
                required property var modelData
                readonly property bool selected: modelData.value === seg.value
                width: label.implicitWidth + 26
                height: 24
                radius: height / 2
                color: selected ? Settings.accent : area.containsMouse ? Theme.hover : "transparent"

                Behavior on color { ColorAnimation { duration: 140 } }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: parent.selected ? Theme.onAccent : Theme.text
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.picked(parent.modelData.value)
                }
            }
        }
    }
}
