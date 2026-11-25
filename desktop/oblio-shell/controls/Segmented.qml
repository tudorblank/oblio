// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.services

Rectangle {
    id: seg

    property var options: []    // [{ value, label, disabled }]
    property var value
    signal picked(var value)

    implicitWidth: row.implicitWidth + 6
    implicitHeight: Theme.controlHeight
    opacity: enabled ? 1 : Theme.disabledOpacity
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
                readonly property bool off: modelData.disabled ?? false
                opacity: off ? Theme.disabledOpacity : 1
                width: label.implicitWidth + 26
                height: seg.height - 6
                radius: height / 2
                color: selected ? Theme.accent : area.containsMouse ? Theme.hover : "transparent"

                Behavior on color { ColorAnimation { duration: Theme.ms(140) } }

                Text {
                    font.family: Theme.fontFor(text)
                    id: label
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: parent.selected ? Theme.accentFg : Theme.text
                    font.pixelSize: Theme.textLabel
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    enabled: !parent.off
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.picked(parent.modelData.value)
                }
            }
        }
    }
}
