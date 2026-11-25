// SPDX-License-Identifier: GPL-3.0-or-later
// A row in a popup list (networks, devices): an icon or image, a title and a status line, controls
// on the right. `active` (connected) tints it with the accent. `inset`: how far the card's edge is.
import QtQuick
import qs.services

Rectangle {
    id: row

    property string icon: ""
    property string image: ""
    property string title
    property string subtitle: ""
    property color subtitleColor: Theme.subtext
    property bool active: false
    property bool clickable: true
    property real inset: 8
    default property alias trailing: slot.data
    signal clicked()

    width: parent ? parent.width : 0
    height: 40
    radius: Theme.inner(inset)
    color: active ? Theme.tint(Theme.accent, 0.12) : area.containsMouse && clickable ? Theme.hover : "transparent"

    Item {
        id: lead
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18
        Text {
            visible: row.image === ""
            anchors.centerIn: parent
            text: row.icon
            color: row.active ? Theme.accentText : Theme.text
            font.family: Theme.iconFont
            font.pixelSize: 16
        }
        Image {
            visible: row.image !== ""
            anchors.fill: parent
            sourceSize: Qt.size(36, 36)
            source: row.image
        }
    }
    Column {
        anchors.left: lead.right
        anchors.leftMargin: 12
        anchors.right: slot.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        Text {
            width: parent.width
            text: row.title
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.fontUi
            font.pixelSize: Theme.textBody
            font.weight: row.active ? Font.DemiBold : Font.Normal
        }
        Text {
            visible: text !== ""
            width: parent.width
            text: row.subtitle
            elide: Text.ElideRight
            color: row.subtitleColor
            font.family: Theme.fontUi
            font.pixelSize: Theme.textCaption
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (row.clickable) row.clicked()
    }
    Row {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
    }
}
