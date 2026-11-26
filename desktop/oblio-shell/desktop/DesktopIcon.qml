// SPDX-License-Identifier: GPL-3.0-or-later
// One file on the desktop: its picture or icon and its name under it (a launcher's own). A click
// selects it (Ctrl: adds or takes away, Shift: everything from the last one), a double click opens
// the selection, a right click opens its menu, F2 or the menu renames it in place. Dragging takes
// the selection along: onto another spot or screen, into a folder, or out to an app; Ctrl held when
// the drag starts copies. A folder takes files dropped on it.
import QtQuick
import QtQuick.Window
import Quickshell.Io
import qs.services
import qs.controls

Item {
    id: cell

    // the file's path (services/Desktop.qml: paths are the icons' keys)
    required property string modelData
    required property var window
    readonly property string path: modelData
    readonly property var file: Desktop.info[path] ?? ({ name: "", isDir: false })
    readonly property bool selected: Desktop.selection[path] === true
    readonly property bool renaming: Desktop.renaming === path

    width: Desktop.cellWidth
    height: Desktop.cellHeight

    // its spot (services/Desktop.qml); it moves there once it has appeared where it was first put
    readonly property var at: Desktop.placed[path]
    x: at?.x ?? 0
    y: at?.y ?? 0
    property bool settled: false
    Component.onCompleted: Qt.callLater(() => settled = true)
    Behavior on x { enabled: cell.settled; Anim {} }
    Behavior on y { enabled: cell.settled; Anim {} }

    readonly property bool launcher: !file.isDir && Desktop.isLauncher(path)
    readonly property var entry: launcher ? Desktop.launchers[path] ?? null : null
    FileView {
        path: cell.launcher ? cell.path : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: Desktop.setLauncher(cell.path, Desktop.launcher(text()))
    }

    readonly property string picture: launcher ? "" : Desktop.picture(path)
    // a picture that can't be read falls back to the icon
    property bool unreadable: false
    onPictureChanged: unreadable = false

    // selected, a drop target, or under the pointer
    Rectangle {
        anchors.horizontalCenter: image.horizontalCenter
        anchors.verticalCenter: image.verticalCenter
        width: Desktop.iconSize + 2 * Desktop.labelGap
        height: width
        radius: Theme.inner(Desktop.spacing)
        color: cell.selected || drop.containsDrag ? Theme.tint(Theme.accent, 0.3)
             : mouse.containsMouse ? Theme.tint("white", 0.1) : "transparent"
        border.width: cell.selected || drop.containsDrag ? 1 : 0
        border.color: Theme.tint(Theme.accent, 0.7)
    }

    Image {
        id: image
        anchors.horizontalCenter: parent.horizontalCenter
        width: Desktop.iconSize
        height: Desktop.iconSize
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
        sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
        readonly property bool showsPicture: cell.picture !== "" && !cell.unreadable
        source: showsPicture ? cell.picture
              : cell.entry ? Apps.icon(cell.entry.icon, "application-x-executable")
              : Desktop.icon(cell.path)
        onStatusChanged: if (status === Image.Error && showsPicture) cell.unreadable = true
    }

    Rectangle {
        visible: cell.selected && !cell.renaming
        anchors.centerIn: label
        width: label.contentWidth + 2 * Desktop.labelGap
        height: label.contentHeight + Desktop.labelGap
        radius: Theme.inner(Desktop.spacing)
        color: Theme.accent
    }
    Text {
        id: label
        visible: !cell.renaming
        anchors.top: image.bottom
        anchors.topMargin: Desktop.labelGap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        maximumLineCount: Desktop.labelLines
        elide: Text.ElideRight
        text: Desktop.label(cell.path)
        font: Desktop.labelFont
        // light text with a dark edge reads on any wallpaper; on the selection's accent, its own
        color: cell.selected ? Theme.accentFg : "white"
        style: cell.selected ? Text.Normal : Text.Raised
        styleColor: "#99000000"
    }

    // renaming in place: Enter or a click elsewhere renames, Esc doesn't. Wider than the cell (a
    // name has room), kept on the screen
    Loader {
        id: editor
        active: cell.renaming
        readonly property real wide: Desktop.cellWidth + Desktop.iconSize
        x: Math.max(-cell.x, Math.min((cell.width - wide) / 2, cell.window.width - cell.x - wide))
        anchors.top: image.bottom
        anchors.topMargin: Desktop.labelGap
        sourceComponent: TextBox {
            width: editor.wide
            value: cell.file.name
            onEdited: v => Desktop.rename(cell.path, v)
            onEditingChanged: if (!editing && Desktop.renaming === cell.path) Desktop.renaming = ""
            Component.onCompleted: {
                focusInput()
                // the name without its extension, like Files
                const dot = cell.file.isDir ? -1 : value.lastIndexOf(".")
                select(0, dot > 0 ? dot : value.length)
            }
        }
    }

    // what a drag carries: the selection's files, and our own mark
    Item {
        id: dragger
        property bool copy: false
        property var paths: []
        Drag.dragType: Drag.Automatic
        Drag.active: mouse.drag.active
        Drag.supportedActions: copy ? Qt.CopyAction : Qt.CopyAction | Qt.MoveAction | Qt.LinkAction
        Drag.proposedAction: copy ? Qt.CopyAction : Qt.MoveAction
        Drag.mimeData: ({ "text/uri-list": paths.map(p => Desktop.info[p]?.uri ?? "").join("\r\n") + "\r\n", [Desktop.dragKey]: "1" })
        Drag.imageSource: image.source
        Drag.imageSourceSize: Qt.size(Desktop.iconSize, Desktop.iconSize)
        Drag.hotSpot: Qt.point(mouse.pressX - image.x, mouse.pressY - image.y)
        Drag.onDragStarted: Desktop.dragging = { paths, held: cell.path, dx: mouse.pressX, dy: mouse.pressY, copy }
        Drag.onDragFinished: Qt.callLater(() => Desktop.dragging = null)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !cell.renaming
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        drag.target: dragger
        property real pressX
        property real pressY
        property bool wasSelected: false
        property int mods: 0
        onPressed: m => {
            cell.window.takeKeys()
            pressX = m.x
            pressY = m.y
            mods = m.modifiers
            wasSelected = cell.selected
            if (m.button === Qt.RightButton) {
                if (!cell.selected) Desktop.select(cell.path, "only")
                cell.window.menuAt(cell.x + m.x, cell.y + m.y, Desktop.selected)
                return
            }
            // Ctrl adds now and takes away on release (so Ctrl+drag can copy it), Shift selects a
            // range; a plain press on a selected icon keeps the rest for a drag
            if (mods & Qt.ShiftModifier) Desktop.select(cell.path, "range")
            else if (mods & Qt.ControlModifier) { if (!wasSelected) Desktop.select(cell.path, "add") }
            else if (!wasSelected) Desktop.select(cell.path, "only")
            dragger.copy = (mods & Qt.ControlModifier) !== 0
            dragger.paths = Desktop.selected
        }
        onClicked: m => {
            if (m.button !== Qt.LeftButton || mods & Qt.ShiftModifier) return
            if (mods & Qt.ControlModifier) { if (wasSelected) Desktop.select(cell.path, "toggle") }
            else if (wasSelected) Desktop.select(cell.path, "only")
        }
        onDoubleClicked: m => { if (m.button === Qt.LeftButton) Desktop.open(Desktop.selected) }
    }

    // a folder takes what's dropped on it (not itself)
    DropArea {
        id: drop
        anchors.fill: parent
        enabled: cell.file.isDir
        keys: ["text/uri-list", Desktop.dragKey]
        onEntered: d => { if (Desktop.own(d) && Desktop.dragging.paths.includes(cell.path)) d.accepted = false }
        onDropped: d => {
            Desktop.droppedOn(cell.path, d)
            d.accept(d.proposedAction)
        }
    }
}
