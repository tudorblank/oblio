// SPDX-License-Identifier: GPL-3.0-or-later
// A button showing the current choice; clicking it lists the options under it (PopupList).
import QtQuick
import qs.services

Item {
    id: dd

    property var options: []    // [{ value, label, tag, note, font }]: tag in the accent color, note on the
                                // right, font draws the label in that font (font pickers)
    property var value
    signal picked(var value)

    readonly property var current: options.find(o => o.value === value) ?? null

    implicitWidth: 250
    implicitHeight: Theme.controlHeight
    opacity: enabled ? 1 : Theme.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: area.containsMouse || popup.opened ? Theme.hover : Theme.card
        border.width: 1
        border.color: popup.opened ? Theme.tint(Theme.accent, 0.6) : Theme.hairline

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                id: currentLabel
                text: dd.current ? dd.current.label : ""
                color: Theme.text
                font.family: Theme.fontFor(text)
                font.pixelSize: Theme.textLabel
                font.weight: Font.Medium
            }
            Text {
                anchors.baseline: currentLabel.baseline
                text: dd.current?.tag ?? ""
                color: Theme.accentText
                font.family: Theme.fontUi
                font.pixelSize: Theme.textCaption
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.chevronDown
            color: Theme.subtext
            font.family: Theme.iconFont
            font.pixelSize: 14
            rotation: popup.opened ? 180 : 0

            Behavior on rotation { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.opened ? popup.close() : popup.open()
    }

    PopupList {
        id: popup
        y: dd.height + 6
        // a bit wider than the button, growing to the left, so a tag and a note both fit
        x: dd.width - width
        width: dd.width + 40
        model: dd.options
        onOpened: view.positionViewAtIndex(Math.max(0, dd.options.indexOf(dd.current)), ListView.Contain)

        delegate: Rectangle {
            id: option
            required property var modelData
            readonly property bool selected: modelData.value === dd.value
            width: ListView.view.width
            height: 32
            radius: Math.min(height / 2, Theme.inner(popup.padding))
            color: optionArea.containsMouse ? Theme.hover : "transparent"

            Text {
                id: check
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                text: option.selected ? Icons.check : ""
                color: Theme.accentText
                font.family: Theme.iconFont
                font.pixelSize: 13
            }
            Row {
                anchors.left: check.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    id: optionLabel
                    text: option.modelData.label
                    color: Theme.text
                    font.family: option.modelData.font ?? Theme.fontFor(text)
                    font.pixelSize: Theme.textLabel
                    font.weight: option.selected ? Font.DemiBold : Font.Normal
                }
                Text {
                    anchors.baseline: optionLabel.baseline
                    text: option.modelData.tag ?? ""
                    color: Theme.accentText
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textCaption
                }
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: option.modelData.note ?? ""
                color: Theme.subtext
                font.family: Theme.fontFor(text)
                font.pixelSize: Theme.textCaption
            }
            MouseArea {
                id: optionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    popup.close()
                    if (option.modelData.value !== dd.value) dd.picked(option.modelData.value)
                }
            }
        }
    }
}
