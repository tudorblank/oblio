// SPDX-License-Identifier: GPL-3.0-or-later
// A one-line text field: Enter or leaving it applies (a password only on Enter or submit()),
// Esc puts the value back. text is what's typed so far (search fields), editing whether it has
// the keyboard.
import QtQuick
import qs.services

Rectangle {
    id: box

    property string value
    property bool mono: false
    property bool password: false
    property string placeholder: ""
    readonly property alias text: input.text
    readonly property bool editing: input.activeFocus
    signal edited(string value)

    function submit() { input.apply() }
    function focusInput() { input.forceActiveFocus() }
    function reset() { input.text = box.value }
    function select(from, to) { input.select(from, to) }

    implicitWidth: 250
    implicitHeight: Theme.controlHeight
    radius: height / 2
    color: Theme.card
    border.width: 1
    border.color: input.activeFocus ? Theme.tint(Theme.accent, 0.6) : Theme.hairline

    Text {
        visible: input.text === "" && !input.activeFocus
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        text: box.placeholder
        color: Theme.subtext
        font: input.font
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        text: box.value
        echoMode: box.password ? TextInput.Password : TextInput.Normal
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentFg
        selectByMouse: true
        font.family: box.mono ? Theme.fontMono : Theme.fontUi
        font.pixelSize: Theme.textLabel
        function apply() { if (text !== box.value) box.edited(text) }
        onAccepted: { apply(); focus = false }
        onActiveFocusChanged: if (!activeFocus && !box.password) apply()
        Keys.onEscapePressed: { box.reset(); focus = false }
    }
}
