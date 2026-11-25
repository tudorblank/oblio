// SPDX-License-Identifier: GPL-3.0-or-later
// One notification: app icon, app and time, summary, body, its picture, its actions. Clicking it
// runs its default action (without one: seen(), the toast goes, the notification stays listed);
// × dismisses it (closed()). Running an action closes the notification
// (unless the app keeps it), which removes this card: handlers keep what they need in locals.
import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services
import qs.controls

Rectangle {
    id: card

    required property var notification
    readonly property var n: notification
    property bool compact: false        // in the list: fewer lines
    readonly property bool hovered: hover.hovered
    readonly property var defaultAction: n.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: n.actions.filter(a => a.identifier !== "default")
    signal closed()
    signal seen()

    width: parent ? parent.width : 360
    height: content.implicitHeight + 24
    // in the bell's list it sits inside a popover, 8 px from its edge
    radius: compact ? Theme.inner(8) : Theme.radius
    color: Theme.popup
    border.width: 1
    border.color: n.urgency === NotificationUrgency.Critical ? Theme.tint(Theme.danger, 0.6) : Theme.border

    HoverHandler { id: hover }
    MouseArea {
        anchors.fill: parent
        cursorShape: card.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (!card.defaultAction) { card.seen(); return }
            const n = card.n
            card.defaultAction.invoke()
            Notifications.hideToast(n)
        }
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
                source: Notifications.icon(card.n)
            }
            Text {
                anchors.left: appIcon.visible ? appIcon.right : parent.left
                anchors.leftMargin: appIcon.visible ? 8 : 0
                anchors.right: close.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: (card.n.appName || "Notification") + "  ·  " + Notifications.ago(card.n)
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
                    text: card.n.summary
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
                    text: card.n.body
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
                visible: card.n.image !== ""
                width: 48
                height: 48
                radius: 10
                color: Theme.card
                Image {
                    anchors.fill: parent
                    source: card.n.image
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
                    onClicked: {
                        const n = card.n
                        modelData.invoke()
                        Notifications.hideToast(n)
                    }
                }
            }
        }
    }
}
