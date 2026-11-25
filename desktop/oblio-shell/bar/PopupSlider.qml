// SPDX-License-Identifier: GPL-3.0-or-later
// A popup row: icon (click: mute, when it can), title and detail, then a 0..100 slider.
import QtQuick
import qs.services
import qs.controls

Column {
    id: ps

    property string icon                // a Nerd Font glyph, or
    property string image: ""           // an icon file (apps)
    property string title
    property string detail
    property real value
    property bool muted: false
    property bool canMute: false
    signal moved(real value)
    signal toggled()

    width: parent ? parent.width : 0
    spacing: 6
    topPadding: 6
    bottomPadding: 6

    Row {
        x: 6
        width: parent.width - 12
        spacing: 10

        Rectangle {
            width: 30
            height: 30
            radius: 15
            color: ps.muted ? Theme.tint(Theme.danger, 0.18) : iconArea.containsMouse && ps.canMute ? Theme.hover : Theme.card
            Image {
                visible: ps.image !== ""
                anchors.centerIn: parent
                width: 18
                height: 18
                sourceSize: Qt.size(36, 36)
                source: ps.image
                opacity: ps.muted ? 0.5 : 1
            }
            Text {
                visible: ps.image === ""
                anchors.centerIn: parent
                text: ps.icon
                color: ps.muted ? Theme.danger : Theme.text
                font.family: Theme.iconFont
                font.pixelSize: 15
            }
            MouseArea {
                id: iconArea
                anchors.fill: parent
                enabled: ps.canMute
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ps.toggled()
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 40
            Text {
                text: ps.title
                color: Theme.text
                font.family: Theme.fontUi
                font.pixelSize: Theme.textBody
                font.weight: Font.DemiBold
            }
            Text {
                visible: text !== ""
                width: parent.width
                text: ps.detail
                elide: Text.ElideRight
                color: Theme.subtext
                font.family: Theme.fontUi
                font.pixelSize: Theme.textCaption
            }
        }
    }

    ValueSlider {
        x: 6
        width: parent.width - 12
        unit: "%"
        value: ps.value
        muted: ps.muted
        onMoved: v => ps.moved(v)
    }
}
