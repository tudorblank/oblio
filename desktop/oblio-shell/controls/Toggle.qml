// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.services

Item {
    id: t

    property bool checked
    signal toggled(bool value)

    implicitWidth: 42
    implicitHeight: 24
    opacity: enabled ? 1 : Theme.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: t.checked ? Theme.accent : Theme.control

        Behavior on color { ColorAnimation { duration: 160 } }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 3
            x: t.checked ? parent.width - width - 3 : 3
            color: Theme.knob

            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: t.toggled(!t.checked)
    }
}
