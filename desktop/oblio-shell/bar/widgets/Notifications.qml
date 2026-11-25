// SPDX-License-Identifier: GPL-3.0-or-later
// The bell: the notification history (services/Notifications.qml), with the unread count if its
// option says so, and Do Not Disturb. The popup lists them, newest first; opening it marks them read.
import QtQuick
import Quickshell
import qs.services
import qs.controls
import qs.bar
import qs.notifications

BarWidget {
    id: w

    onPopupOpenChanged: if (popupOpen) Notifications.markRead()

    length: row.length
    popup: panel
    popupWidth: 380
    onActivated: b => { if (b === Qt.MiddleButton) Settings.set("notifyDnd", !Settings.opts.notifyDnd) }

    IconValue {
        id: row
        widget: w
        icon: Settings.opts.notifyDnd ? Icons.bellOff : Notifications.unread > 0 ? Icons.bellUnread : Icons.bell
        value: Notifications.unread > 0 ? String(Notifications.unread) : ""
        showValue: w.opt("count")
        color: Notifications.unread > 0 && !Settings.opts.notifyDnd ? Theme.accentText : Theme.text
    }

    Component {
        id: panel

        Column {
            spacing: 6
            topPadding: 4
            bottomPadding: 4

            Item {
                width: parent.width
                height: 40
                Text {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textTitle
                    font.weight: Font.DemiBold
                }
                Button {
                    visible: Notifications.history.length > 0
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clear all"
                    onClicked: Notifications.clear()
                }
            }

            Item {
                width: parent.width
                height: 36
                Text {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Do Not Disturb"
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textBody
                }
                Toggle {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Settings.opts.notifyDnd
                    onToggled: v => Settings.set("notifyDnd", v)
                }
            }

            Text {
                visible: Notifications.history.length === 0
                width: parent.width
                topPadding: 18
                bottomPadding: 22
                horizontalAlignment: Text.AlignHCenter
                text: "No notifications"
                color: Theme.subtext
                font.family: Theme.fontUi
                font.pixelSize: Theme.textLabel
            }

            ListView {
                visible: Notifications.history.length > 0
                width: parent.width
                height: Math.min(contentHeight, 460)
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                model: ScriptModel { values: Notifications.history; objectProp: "key" }
                delegate: NotificationCard {
                    required property var modelData
                    width: ListView.view.width
                    entry: modelData
                    compact: true
                    // a local first: removing it removes this card
                    onClosed: { const key = modelData.key; Notifications.remove(key) }
                }
            }
        }
    }
}
