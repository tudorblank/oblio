// SPDX-License-Identifier: GPL-3.0-or-later
// New notifications as cards in the corner of the focused screen, on the bar's side (top or
// bottom). Each one counts down its time (Notifications.timeout) on a line along its bottom, paused
// while the pointer is on it, then folds away; critical ones stay until closed.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.controls

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
            model: ScriptModel { values: Notifications.toasts; objectProp: "key" }

            // the card, folding its room away as it goes
            Item {
                id: toast
                required property var modelData
                readonly property bool critical: modelData.critical
                property bool leaving: false
                function leave() { leaving = true }
                width: list.width
                height: leaving ? 0 : card.height
                clip: leaving
                opacity: leaving ? 0 : 1

                Behavior on height { Anim {} }
                Behavior on opacity { Anim {} }
                // gone from the list once folded (a local first: hiding it removes this toast)
                Timer {
                    running: toast.leaving
                    interval: Theme.motionNormal
                    onTriggered: { const key = toast.modelData.key; Notifications.hideToast(key) }
                }

                NotificationCard {
                    id: card
                    entry: toast.modelData
                    remaining: toast.critical ? -1 : timeLeft
                    property real timeLeft: 1
                    onClosed: toast.leave()
                    onSeen: toast.leave()

                    NumberAnimation on timeLeft {
                        running: !toast.critical
                        paused: running && card.hovered
                        from: 1; to: 0
                        duration: Notifications.timeout(toast.modelData)
                        onFinished: toast.leave()
                    }
                    NumberAnimation on opacity { from: 0; to: 1; duration: Theme.ms(180); easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
