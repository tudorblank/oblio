// SPDX-License-Identifier: GPL-3.0-or-later
// A button showing the current choice; clicking it lists the options below it.
import QtQuick
import QtQuick.Controls as C
import qs.services

Item {
    id: dd

    property var options: []    // [{ value, label, tag, note, font }]: tag in the accent color, note on the
                                // right, font draws the label in that font (font pickers)
    property var value
    signal picked(var value)

    readonly property var current: options.find(o => o.value === value) ?? null

    implicitWidth: 250
    implicitHeight: 30
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: area.containsMouse || popup.opened ? Theme.hover : Theme.card
        border.width: 1
        border.color: popup.opened ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6) : Theme.hairline

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                font.family: Theme.fontUi
                text: dd.current ? dd.current.label : ""
                color: Theme.text
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            Text {
                font.family: Theme.fontUi
                text: dd.current?.tag ?? ""
                color: Theme.accent
                font.pixelSize: 11
            }
        }

        Text {
            id: chevron
            anchors.right: parent.right
            anchors.rightMargin: 13
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: Theme.subtext
            font.family: Theme.iconFont
            font.pixelSize: 9
            rotation: popup.opened ? 180 : 0

            Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.opened ? popup.close() : popup.open()
    }

    // a Popup draws above everything in the window, so the page's clipping doesn't cut it off
    C.Popup {
        id: popup
        y: dd.height + 6
        // a bit wider than the button, growing to the left, so a tag and a note both fit
        x: dd.width - width
        width: dd.width + 40
        height: Math.min(list.contentHeight, 280) + topPadding + bottomPadding
        padding: 5
        margins: 12
        focus: true
        closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutside

        onOpened: list.positionViewAtIndex(Math.max(0, dd.options.indexOf(dd.current)), ListView.Contain)

        background: Rectangle {
            radius: 14
            color: Theme.popup
            border.width: 1
            border.color: Theme.border
        }

        contentItem: ListView {
            id: list
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: dd.options

            delegate: Rectangle {
                id: option
                required property var modelData
                readonly property bool selected: modelData.value === dd.value
                width: list.width
                height: 32
                radius: 10
                color: optionArea.containsMouse ? Theme.hover : "transparent"

                Text {
                    id: check
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    text: option.selected ? "" : ""
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 11
                }

                Row {
                    anchors.left: check.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        font.family: option.modelData.font ?? Theme.fontUi
                        text: option.modelData.label
                        color: Theme.text
                        font.pixelSize: 12
                        font.weight: option.selected ? Font.DemiBold : Font.Normal
                    }
                    Text {
                        font.family: Theme.fontUi
                        text: option.modelData.tag ?? ""
                        color: Theme.accent
                        font.pixelSize: 11
                    }
                }

                Text {
                    font.family: Theme.fontUi
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: option.modelData.note ?? ""
                    color: Theme.subtext
                    font.pixelSize: 11
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
}
