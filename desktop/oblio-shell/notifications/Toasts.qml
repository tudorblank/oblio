// SPDX-License-Identifier: GPL-3.0-or-later
// New notifications as cards in the corner of the focused screen, on the bar's side (top or
// bottom). Each one goes after its timeout (5 s when the app doesn't say), but not while the
// pointer is on it; critical ones stay until dismissed.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import qs.services

PanelWindow {
    id: win

    readonly property bool bottom: Settings.opts.barEnabled && Settings.opts.barEdge === "bottom"
    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? Quickshell.screens[0]
    visible: Notifications.toasts.length > 0
    anchors { top: !bottom; bottom: bottom; right: true }
    margins { top: 8; bottom: 8; right: 8 }
    implicitWidth: 372
    implicitHeight: Math.max(1, list.implicitHeight)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "oblio-notifications"

    Column {
        id: list
        width: parent.width
        spacing: 8

        Repeater {
            model: ScriptModel { values: Notifications.toasts }

            NotificationCard {
                id: toast
                required property var modelData
                notification: modelData
                // hiding it removes this card: keep the notification in a local first
                onClosed: { const n = modelData; Notifications.hideToast(n); if (!n.transient) n.dismiss() }
                onSeen: Notifications.hideToast(modelData)

                Timer {
                    running: toast.n.urgency !== NotificationUrgency.Critical && !toast.hovered
                    interval: toast.n.expireTimeout > 0 ? toast.n.expireTimeout : 5000
                    onTriggered: Notifications.hideToast(toast.modelData)
                }
                NumberAnimation on opacity { from: 0; to: 1; duration: Theme.ms(180); easing.type: Easing.OutCubic }
            }
        }
    }
}
