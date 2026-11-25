// SPDX-License-Identifier: GPL-3.0-or-later
// The desktop's picture on one screen, under every window; a new one fades in over the old.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: win

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "oblio-wallpaper"
    color: Theme.background

    readonly property string source: Wallpaper.url(Wallpaper.desktop)
    onSourceChanged: {
        fade.stop()
        next.opacity = 0
        next.source = source
        if (!source) shown.source = ""
    }

    component Picture: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(win.screen.width, win.screen.height)
        asynchronous: true
    }

    Picture { id: shown; Component.onCompleted: source = win.source }

    Picture {
        id: next
        opacity: 0
        onStatusChanged: if (status === Image.Ready && source !== shown.source) fade.restart()
    }

    // the new picture stays on top until the next change; the one under it catches up meanwhile
    SequentialAnimation {
        id: fade
        NumberAnimation { target: next; property: "opacity"; to: 1; duration: 450; easing.type: Easing.InOutCubic }
        ScriptAction { script: shown.source = next.source }
    }
}
