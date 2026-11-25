// SPDX-License-Identifier: GPL-3.0-or-later
// Accent colors, and a field for any other one (#rrggbb).
import QtQuick
import qs.services

Row {
    id: sw

    property string value
    property var colors: [Theme.defaultAccent, "#5b9cf5", "#a78bfa", "#f472b6", "#ef5350", "#fb923c", "#facc15", "#2dd4bf", "#e4e4e7"]
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

    // any color: type it, Enter applies
    Rectangle {
        readonly property bool custom: !sw.colors.some(c => c.toLowerCase() === sw.value.toLowerCase())
        anchors.verticalCenter: parent.verticalCenter
        width: 92
        height: 26
        radius: 13
        color: Theme.card
        border.width: custom ? 2 : 1
        border.color: custom ? Theme.text : (hex.activeFocus ? Theme.accent : Theme.hairline)

        Rectangle {
            id: dot
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: /^#[0-9a-fA-F]{6}$/.test(hex.text) ? hex.text : sw.value
        }

        TextInput {
            id: hex
            anchors.left: dot.right
            anchors.right: parent.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: sw.value
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentFg
            font.family: Theme.fontMono
            font.pixelSize: Theme.textCaption
            maximumLength: 7
            validator: RegularExpressionValidator { regularExpression: /#?[0-9a-fA-F]{0,6}/ }
            onAccepted: {
                const v = (text.startsWith("#") ? text : "#" + text).toLowerCase()
                if (/^#[0-9a-f]{6}$/.test(v)) sw.picked(v)
            }
            onActiveFocusChanged: if (!activeFocus) text = Qt.binding(() => sw.value)
        }
    }
}
