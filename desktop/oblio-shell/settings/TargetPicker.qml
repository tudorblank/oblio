// SPDX-License-Identifier: GPL-3.0-or-later
// Picks what a style applies to: the shell's parts, all apps, or one app (installed, or open
// right now). Only what no style has yet is listed (shell parts in Default are free). Type to
// search; the list stays open for more.
import QtQuick
import qs.services
import qs.controls

PopupList {
    id: picker

    required property string uid

    width: 320
    maxHeight: 380
    onOpened: headerItem.focusInput()
    onClosed: headerItem.reset()

    readonly property string query: headerItem ? headerItem.text.trim().toLowerCase() : ""
    model: {
        const l = []
        const fits = name => !query || name.toLowerCase().includes(query)
        const add = (target, name, glyph, image) => {
            if (fits(name) && Styles.free(target)) l.push({ target, name, glyph, image })
        }
        const group = (title, from) => {
            const at = l.length
            from()
            if (l.length > at) l.splice(at, 0, { title })
        }
        group("SHELL", () => { for (const p of Styles.parts) add(p.id, p.name, p.icon, "") })
        group("APPS", () => {
            add(Styles.allApps, "All apps", Icons.windows, "")
            for (const a of Apps.installed) add("app:" + a.cls, a.name, "", Apps.appIcon(a.cls, "application-x-executable"))
        })
        return l
    }

    header: Item {
        readonly property alias text: search.text
        function focusInput() { search.focusInput() }
        function reset() { search.reset() }
        height: Theme.controlHeight + 4
        TextBox {
            id: search
            width: parent.width
            placeholder: "Search"
        }
    }

    delegate: Item {
        id: option
        required property var modelData
        readonly property bool isTitle: modelData.title !== undefined
        width: ListView.view.width
        height: isTitle ? 30 : 40

        SectionLabel {
            visible: option.isTitle
            x: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: option.modelData.title ?? ""
        }

        Rectangle {
            visible: !option.isTitle
            anchors.fill: parent
            radius: Theme.inner(picker.padding)
            color: area.containsMouse ? Theme.hover : "transparent"

            Item {
                id: icon
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                Text {
                    visible: option.modelData.glyph !== ""
                    anchors.centerIn: parent
                    text: option.modelData.glyph ?? ""
                    color: Theme.subtext
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                }
                Image {
                    visible: (option.modelData.image ?? "") !== ""
                    anchors.fill: parent
                    source: option.modelData.image ?? ""
                    sourceSize: Qt.size(44, 44)
                    asynchronous: true
                }
            }
            Text {
                anchors.left: icon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: option.modelData.name ?? ""
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.fontUi
                font.pixelSize: Theme.textBody
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Styles.assign(picker.uid, option.modelData.target)
            }
        }
    }
}
