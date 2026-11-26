// SPDX-License-Identifier: GPL-3.0-or-later
// One notification entry (services/Notifications.qml): app icon, app and time, summary, body, its
// picture, and its actions while the app still keeps it. Clicking it runs its default action
// (without one: seen()); × is closed(). remaining (0..1, a card on its own) draws how long it has
// left as a line along its bottom, shrinking to the left.
import QtQuick
import Quickshell.Widgets
import qs.services
import qs.controls

Card {
    id: card
    part: "menus"
    namespace: "oblio-notifications"
    // on its own (a toast) it's glass when menus are; in the bell's list it's a card on glass
    glass: !compact

    required property var entry
    property bool compact: false        // in the list: fewer lines
    property real remaining: -1         // -1: no countdown
    readonly property bool hovered: hover.hovered
    readonly property var buttons: Notifications.live[entry.key] ? Notifications.actions(entry.key) : []
    readonly property bool clickable: Notifications.live[entry.key]?.actions.some(a => a.identifier === "default") ?? false
    signal closed()
    signal seen()

    width: parent ? parent.width : 360
    height: content.implicitHeight + 24
    // in the bell's list it's a card inside a popover, 8 px from its edge; on its own (a toast) it's
    // a menu, in the menus' style
    radius: compact ? Theme.inner(8) : Theme.radius
    color: compact ? Theme.card : look.fill
    border.width: compact || entry.critical ? 1 : look.lineWidth
    border.color: entry.critical ? Theme.tint(Theme.danger, 0.6) : compact ? Theme.hairline : look.line

    HoverHandler { id: hover }
    MouseArea {
        anchors.fill: parent
        cursorShape: card.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (!Notifications.invoke(card.entry.key, "default")) card.seen()
    }

    Column {
        id: content
        x: 14
        y: 12
        width: parent.width - 28
        spacing: 6

        // app icon, app name, when
        Item {
            width: parent.width
            height: 18
            IconImage {
                id: appIcon
                visible: source !== ""
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                source: Notifications.icon(card.entry)
            }
            Text {
                anchors.left: appIcon.visible ? appIcon.right : parent.left
                anchors.leftMargin: appIcon.visible ? 8 : 0
                anchors.right: close.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: card.entry.app + "  ·  " + Notifications.ago(card.entry)
                elide: Text.ElideRight
                color: Theme.subtext
                font.family: Theme.fontUi
                font.pixelSize: Theme.textCaption
            }
            IconButton {
                id: close
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                size: 22
                icon: Icons.close
                onClicked: card.closed()
            }
        }

        Row {
            width: parent.width
            spacing: 12

            Column {
                width: parent.width - (picture.visible ? picture.width + 12 : 0)
                spacing: 3
                Text {
                    width: parent.width
                    text: card.entry.summary
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textBody
                    font.weight: Font.DemiBold
                }
                Text {
                    visible: text !== ""
                    width: parent.width
                    text: card.entry.body
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: card.compact ? 2 : 5
                    elide: Text.ElideRight
                    color: Theme.text
                    opacity: 0.85
                    linkColor: Theme.accentText
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textLabel
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
            ClippingRectangle {
                id: picture
                visible: (card.entry.image ?? "") !== ""
                width: 48
                height: 48
                radius: 10
                color: Theme.card
                Image {
                    anchors.fill: parent
                    source: card.entry.image ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(96, 96)
                    asynchronous: true
                }
            }
        }

        // its actions
        Row {
            visible: card.buttons.length > 0
            spacing: 6
            topPadding: 2
            Repeater {
                model: card.buttons
                Button {
                    required property var modelData
                    text: modelData.text
                    onClicked: Notifications.invoke(card.entry.key, modelData.identifier)
                }
            }
        }
    }

    // the time left, along the bottom inside the corners
    Rectangle {
        visible: card.remaining >= 0
        x: Theme.radius / 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        width: parent.width - Theme.radius
        height: 3
        radius: height / 2
        color: Theme.hairline
        Rectangle {
            width: parent.width * Math.max(0, card.remaining)
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }
    }
}
