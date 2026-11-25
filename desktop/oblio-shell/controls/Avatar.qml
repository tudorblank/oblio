// SPDX-License-Identifier: GPL-3.0-or-later
// The user's picture in a circle, or their initial on the accent when there's none.
import QtQuick
import Quickshell.Widgets
import qs.services

ClippingRectangle {
    id: a

    property int size: 64
    readonly property bool hasPicture: picture.status === Image.Ready

    width: size
    height: size
    radius: size / 2
    color: Theme.accent

    Rectangle {
        anchors.fill: parent
        visible: !a.hasPicture
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(Theme.accent, 1.2) }
            GradientStop { position: 1; color: Qt.darker(Theme.accent, 1.3) }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !a.hasPicture
        text: User.display.charAt(0).toUpperCase()
        color: Theme.accentFg
        font.family: Theme.fontUi
        font.pixelSize: Math.round(a.size * 0.42)
        font.weight: Font.DemiBold
    }

    Image {
        id: picture
        anchors.fill: parent
        source: User.faceUrl
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(a.size * 2, a.size * 2)
        asynchronous: true
        cache: false
    }
}
