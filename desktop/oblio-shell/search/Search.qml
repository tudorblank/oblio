// SPDX-License-Identifier: GPL-3.0-or-later
// Search (SUPER+R, or `qs -p ~/.config/oblio-shell ipc call search toggle`): a pill that opens a
// little way down the focused screen and widens as you type, with the apps that match in a card
// under it. Up and Down (or Tab) pick, Enter opens, Escape or a click outside closes. Its look is
// the "search" part's style, its size and place its options (services/Parts.qml).
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.controls

Scope {
    id: root

    readonly property bool shown: overlay.shown
    property string query: ""
    property int selected: 0
    readonly property bool typing: query !== ""
    // the pointer picks a row only once it moves: a list appearing under a resting pointer
    // doesn't take the keyboard's pick. Typing hands the pick back to the keyboard
    property bool pointing: false
    property var rest: null
    onQueryChanged: { pointing = false; rest = null }
    function hover(index, at) {
        if (!pointing) {
            if (!rest) { rest = at; return }
            if (Math.abs(at.x - rest.x) + Math.abs(at.y - rest.y) < 3) return
            pointing = true
        }
        selected = index
    }

    function opt(key) { return Parts.option("search", key) }
    function open() {
        query = ""
        field.text = ""
        overlay.open()
    }
    function close() { overlay.close() }
    function toggle() { overlay.shown ? close() : open() }
    function move(by) { selected = Math.max(0, Math.min(selected + by, results.values.length - 1)) }
    function launch(entry) {
        if (!entry) return
        entry.execute()
        close()
    }

    IpcHandler {
        target: "search"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }
    Connections {
        target: Menus
        function onRequested(part, action, arg) {
            if (part !== "search") return
            if (action === "toggle") root.toggle()
            else if (action === "close") root.close()
            else root.open()
        }
    }

    // the apps that match, kept as the same objects while typing (rows aren't rebuilt)
    ScriptModel {
        id: results
        values: Apps.search(root.query)
        onValuesChanged: root.selected = 0
    }

    Overlay {
        id: overlay
        part: "search"
        exclusive: true
        fading: pill
        onShownChanged: if (shown) Qt.callLater(() => field.forceActiveFocus())

        Card {
            id: pill
            part: "search"
            readonly property real gap: 8
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(overlay.window.height * root.opt("top") / 100)
            width: root.typing ? root.opt("width") : Math.round(root.opt("width") * 0.6)
            height: root.typing ? 56 : 50
            radius: height / 2
            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 1.1

            Behavior on width { Spring {} }
            Behavior on height { Spring {} }
            Behavior on opacity { Anim {} }
            Behavior on scale { Anim {} }

            MouseArea { anchors.fill: parent; onPressed: field.forceActiveFocus() }

            Text {
                id: glyph
                x: 18
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.search
                color: Theme.subtext
                font.family: Theme.iconFont
                font.pixelSize: 22
            }
            TextInput {
                id: field
                anchors.left: glyph.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentFg
                font.family: Theme.fontUi
                font.pixelSize: Theme.textLarge
                onTextChanged: root.query = text

                Keys.onEscapePressed: root.close()
                Keys.onReturnPressed: root.launch(results.values[root.selected])
                Keys.onEnterPressed: root.launch(results.values[root.selected])
                Keys.onUpPressed: root.move(-1)
                Keys.onDownPressed: root.move(1)
                Keys.onTabPressed: root.move(1)
                Keys.onBacktabPressed: root.move(-1)
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_PageDown) { root.move(root.opt("rows")); e.accepted = true }
                    else if (e.key === Qt.Key_PageUp) { root.move(-root.opt("rows")); e.accepted = true }
                }

                Text {
                    visible: field.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search"
                    color: Theme.subtext
                    font: field.font
                }
            }
        }

        Card {
            id: list
            part: "search"
            readonly property real pad: 8
            readonly property real rowHeight: 56
            readonly property real spacing: 4
            readonly property int shownRows: Math.max(1, Math.min(root.opt("rows"), results.values.length))
            readonly property bool open: root.typing && root.shown
            anchors.horizontalCenter: parent.horizontalCenter
            width: pill.width
            height: shownRows * (rowHeight + spacing) - spacing + 2 * pad
            // slides up into place under the pill as it opens
            y: pill.y + pill.height + pill.gap + (open ? 0 : 48)
            opacity: open ? 1 : 0
            visible: opacity > 0

            Behavior on y { Spring {} }
            Behavior on height { Spring {} }
            Behavior on opacity { Anim {} }

            MouseArea { anchors.fill: parent }

            Text {
                visible: results.values.length === 0
                anchors.centerIn: parent
                text: "No apps match"
                color: Theme.subtext
                font.family: Theme.fontUi
                font.pixelSize: Theme.textBody
            }

            ListView {
                id: view
                anchors.fill: parent
                anchors.margins: list.pad
                clip: true
                spacing: list.spacing
                model: results
                currentIndex: root.selected
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: Theme.ms(150)
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: height
                highlight: Rectangle {
                    radius: Theme.inner(list.pad)
                    color: Theme.tint(Theme.accent, 0.14)
                    border.width: 1
                    border.color: Theme.tint(Theme.accent, 0.3)
                }
                delegate: SearchRow {
                    width: view.width
                    height: list.rowHeight
                    details: root.opt("details")
                    onHovered: at => root.hover(index, at)
                    onPicked: root.launch(modelData)
                }
            }
        }
    }
}
