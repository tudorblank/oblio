// SPDX-License-Identifier: GPL-3.0-or-later
// The current app: the focused window's app icon and title, on the screen it's on. A side bar
// shows the icon only.
import QtQuick
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.services
import qs.bar

BarWidget {
    id: w

    // Hyprland's own focus state is empty until focus first changes; the Wayland side knows it
    readonly property var window: Hyprland.toplevels.values.find(t => t.wayland && t.wayland.activated) ?? null
    readonly property var monitor: bar ? Hyprland.monitorFor(bar.screen) : null
    readonly property bool here: window !== null && window.workspace !== null && monitor !== null
                                 && window.workspace === monitor.activeWorkspace
    readonly property string title: here ? window.title : ""
    readonly property string appId: here && window.wayland ? window.wayland.appId : ""
    readonly property string iconSource: appId ? Apps.appIcon(appId, "application-x-executable") : ""
    readonly property bool showIcon: opt("icon") || vertical
    readonly property bool showTitle: opt("title") && !vertical

    interactive: false
    length: !here ? 0 : vertical ? (showIcon ? m.icon : 0)
        : Math.min((showIcon ? m.icon : 0) + (showIcon && showTitle ? m.gap : 0)
                   + (showTitle ? Math.ceil(metrics.advanceWidth) + 1 : 0), opt("maxLength"))

    TextMetrics { id: metrics; font: label.font; text: w.title }

    Row {
        anchors.centerIn: parent
        spacing: w.m.gap

        IconImage {
            visible: w.showIcon
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: w.m.icon
            source: w.iconSource
        }
        Text {
            id: label
            visible: w.showTitle
            anchors.verticalCenter: parent.verticalCenter
            width: w.length - (w.showIcon ? w.m.icon + w.m.gap : 0)
            text: w.title
            elide: Text.ElideRight
            color: Theme.text
            opacity: 0.8
            font.family: Theme.fontUi
            font.pixelSize: w.m.text
        }
    }
}
