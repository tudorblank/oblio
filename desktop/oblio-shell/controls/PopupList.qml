// SPDX-License-Identifier: GPL-3.0-or-later
// A list that drops down from a control (dropdowns, the widget catalog). A press on the control
// itself doesn't close it, so a click there toggles it; a press anywhere else closes it and still
// reaches what's there (another dropdown opens).
import QtQuick
import QtQuick.Controls as C
import qs.services

C.Popup {
    id: pop

    property alias model: list.model
    property alias delegate: list.delegate
    property alias view: list
    property real maxHeight: 280

    height: Math.min(list.contentHeight, maxHeight) + topPadding + bottomPadding
    padding: 5
    margins: 12
    focus: true
    closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutsideParent

    background: Rectangle {
        radius: Theme.radius
        color: Theme.popup
        border.width: 1
        border.color: Theme.border
    }

    contentItem: ListView {
        id: list
        clip: true
        boundsBehavior: Flickable.StopAtBounds
    }
}
