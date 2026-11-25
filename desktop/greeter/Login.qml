// SPDX-License-Identifier: GPL-3.0-or-later
// The clock at the top, and one card near the bottom: who's logging in, the password, then the
// session and power buttons. Drawn like the shell (its palette, corners and controls).
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

Item {
    id: ui

    required property var greeter
    required property Backdrop backdrop
    readonly property QtObject t: greeter.theme
    // white with a shadow over a picture; the theme's text on the plain background
    readonly property bool onPicture: backdrop.hasPicture || t.dark
    property bool reveal: false
    // the open list: "sessions", "users" or ""
    property string menu: ""

    readonly property var icons: ({
        lock: "\u{f033e}", eye: "\u{f0208}", eyeOff: "\u{f0209}", go: "\u{f0054}", restart: "\u{f0709}",
        power: "\u{f0425}", chevronDown: "\u{f0140}", session: "\u{f0379}", check: "\u{f012c}",
    })

    function closeMenu() { menu = ""; field.forceActiveFocus() }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // a small rounded button: an icon, a label or both, outlined
    component Chip: Rectangle {
        id: chip
        property string icon
        property string label
        property string trailing
        property bool open: false
        signal clicked()
        implicitWidth: label ? row.implicitWidth + 26 : ui.t.control
        implicitHeight: ui.t.control
        radius: height / 2
        color: area.containsMouse || open ? ui.t.hover : "transparent"
        border.width: 1
        border.color: open ? Qt.rgba(ui.t.accent.r, ui.t.accent.g, ui.t.accent.b, 0.6) : ui.t.border

        Behavior on color { ColorAnimation { duration: 140 } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 7
            Text {
                visible: chip.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: chip.icon
                color: ui.t.text
                font.family: ui.t.iconFont
                font.pixelSize: 14
            }
            Text {
                visible: chip.label !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label
                color: ui.t.text
                font.family: ui.t.font
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            Text {
                visible: chip.trailing !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: chip.trailing
                color: ui.t.subtext
                font.family: ui.t.iconFont
                font.pixelSize: 13
                rotation: chip.open ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    // a click outside an open list closes it
    MouseArea {
        anchors.fill: parent
        enabled: ui.menu !== ""
        onPressed: ui.closeMenu()
    }

    // clock
    Column {
        id: clockColumn
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.13)
        spacing: 0
        layer.enabled: ui.onPicture
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.35
            shadowBlur: 0.8
            shadowVerticalOffset: 2
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: ui.onPicture ? "#f2f2f5" : ui.t.subtext
            font.family: ui.t.font
            font.pixelSize: 20
            font.weight: Font.Medium
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: ui.onPicture ? "#ffffff" : ui.t.text
            font.family: ui.t.font
            font.pixelSize: 112
            font.weight: Font.DemiBold
            font.letterSpacing: -3
            font.features: { "tnum": 1 }
        }
    }

    // the card
    Item {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 84
        width: 400
        height: content.implicitHeight + 2 * 22

        // shake when the password is wrong
        transform: Translate { id: shift }
        SequentialAnimation {
            id: shake
            NumberAnimation { target: shift; property: "x"; to: -12; duration: 50 }
            NumberAnimation { target: shift; property: "x"; to: 10; duration: 70 }
            NumberAnimation { target: shift; property: "x"; to: -6; duration: 70 }
            NumberAnimation { target: shift; property: "x"; to: 0; duration: 60 }
        }
        Connections {
            target: ui.greeter
            function onFailed() { shake.restart(); field.forceActiveFocus() }
        }

        // frosted: the wallpaper behind it, blurred, under the card's tint
        ClippingRectangle {
            anchors.fill: parent
            radius: ui.t.radius
            color: "transparent"

            MultiEffect {
                x: -card.x
                y: -card.y
                width: ui.width
                height: ui.height
                source: ui.backdrop
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: 64
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: ui.t.radius
            color: ui.t.card
            border.width: 1
            border.color: ui.t.border
        }

        Column {
            id: content
            anchors.centerIn: parent
            width: parent.width - 2 * 22
            spacing: 16

            // who: the picture, the name under it (a list of people when there's more than one)
            Column {
                width: parent.width
                spacing: 12

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 76
                    height: 76

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: ui.t.accent

                        Rectangle {
                            anchors.fill: parent
                            visible: face.status !== Image.Ready
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.lighter(ui.t.accent, 1.2) }
                                GradientStop { position: 1; color: Qt.darker(ui.t.accent, 1.3) }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: ui.greeter.user ? ui.greeter.user.display.charAt(0).toUpperCase() : ""
                                color: ui.t.accentFg
                                font.family: ui.t.font
                                font.pixelSize: 32
                                font.weight: Font.DemiBold
                            }
                        }

                        Image {
                            id: face
                            anchors.fill: parent
                            source: ui.greeter.userDir ? "file://" + ui.greeter.userDir + "/avatar" : ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(152, 152)
                            asynchronous: true
                            cache: false
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: width / 2
                        color: "transparent"
                        border.width: 2
                        border.color: ui.t.border
                    }
                }

                Rectangle {
                    id: userChip
                    readonly property bool many: ui.greeter.users.length > 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width, nameRow.implicitWidth + (many ? 28 : 0))
                    height: ui.t.control
                    radius: height / 2
                    color: many && (nameArea.containsMouse || ui.menu === "users") ? ui.t.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Row {
                        id: nameRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            width: Math.min(implicitWidth, userChip.parent.width - 40)
                            anchors.verticalCenter: parent.verticalCenter
                            text: ui.greeter.user ? ui.greeter.user.display : "No users"
                            color: ui.t.text
                            font.family: ui.t.font
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: userChip.many
                            anchors.verticalCenter: parent.verticalCenter
                            text: ui.icons.chevronDown
                            color: ui.t.subtext
                            font.family: ui.t.iconFont
                            font.pixelSize: 14
                            rotation: ui.menu === "users" ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }
                    }

                    MouseArea {
                        id: nameArea
                        anchors.fill: parent
                        enabled: userChip.many
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ui.menu = ui.menu === "users" ? "" : "users"
                    }
                }
            }

            // password, or whatever else PAM asks
            Rectangle {
                width: parent.width
                height: 44
                radius: height / 2
                color: ui.t.field
                border.width: 1
                border.color: field.activeFocus ? Qt.rgba(ui.t.accent.r, ui.t.accent.g, ui.t.accent.b, 0.6) : ui.t.hairline

                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    id: lockIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: ui.icons.lock
                    color: ui.t.subtext
                    font.family: ui.t.iconFont
                    font.pixelSize: 15
                }

                TextInput {
                    id: field
                    readonly property bool secret: ui.greeter.prompt ? !ui.greeter.promptEcho : true
                    anchors.left: lockIcon.right
                    anchors.right: eye.left
                    anchors.leftMargin: 12
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: secret && !ui.reveal ? TextInput.Password : TextInput.Normal
                    passwordCharacter: "•"
                    color: ui.t.text
                    selectionColor: ui.t.accent
                    selectedTextColor: ui.t.accentFg
                    font.family: ui.t.font
                    font.pixelSize: 14
                    font.letterSpacing: echoMode === TextInput.Password ? 2 : 0
                    clip: true
                    focus: true
                    enabled: !ui.greeter.busy
                    text: ui.greeter.password
                    onTextChanged: ui.greeter.password = text
                    onAccepted: ui.greeter.login()
                    Keys.onEscapePressed: { text = ""; ui.menu = "" }
                    Component.onCompleted: forceActiveFocus()

                    Text {
                        visible: !field.text
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: ui.greeter.busy ? "Signing in…" : ui.greeter.prompt || "Password"
                        color: ui.t.subtext
                        font.family: ui.t.font
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                }

                // show the password
                Rectangle {
                    id: eye
                    anchors.right: go.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    radius: 16
                    visible: field.secret
                    color: eyeArea.containsMouse ? ui.t.hover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: ui.reveal ? ui.icons.eyeOff : ui.icons.eye
                        color: ui.t.subtext
                        font.family: ui.t.iconFont
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: eyeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { ui.reveal = !ui.reveal; field.forceActiveFocus() }
                    }
                }

                Rectangle {
                    id: go
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    radius: 16
                    color: goArea.containsMouse ? ui.t.accentHover : ui.t.accent
                    opacity: field.text || ui.greeter.busy ? 1 : 0.45

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: ui.icons.go
                        color: ui.t.accentFg
                        font.family: ui.t.iconFont
                        font.pixelSize: 17
                    }
                    MouseArea {
                        id: goArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ui.greeter.login()
                    }
                }
            }

            Text {
                visible: ui.greeter.message !== ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: ui.greeter.message
                color: ui.t.danger
                font.family: ui.t.font
                font.pixelSize: 12
            }

            Rectangle {
                width: parent.width
                height: 1
                color: ui.t.hairline
            }

            // session on the left, power on the right
            Item {
                width: parent.width
                height: ui.t.control

                Chip {
                    id: sessionChip
                    anchors.left: parent.left
                    width: Math.min(implicitWidth, parent.width - powerRow.width - 8)
                    icon: ui.icons.session
                    label: ui.greeter.session ? ui.greeter.session.name : "No sessions"
                    trailing: ui.icons.chevronDown
                    open: ui.menu === "sessions"
                    onClicked: ui.menu = ui.menu === "sessions" ? "" : "sessions"
                }

                Row {
                    id: powerRow
                    anchors.right: parent.right
                    spacing: 8
                    Chip { icon: ui.icons.restart; label: "Restart"; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                    Chip { icon: ui.icons.power; label: "Shut down"; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
                }
            }
        }
    }

    // the users or sessions list, opening upward from its button
    Rectangle {
        id: list
        // the last one opened, so it keeps its content while fading out
        property string kind: "sessions"
        readonly property bool users: kind === "users"
        readonly property Item from: users ? userChip : sessionChip
        readonly property var items: users ? ui.greeter.users.map(u => u.display) : ui.greeter.sessions.map(s => s.name)
        readonly property int current: users ? ui.greeter.userIndex : ui.greeter.sessionIndex
        Connections {
            target: ui
            function onMenuChanged() { if (ui.menu) list.kind = ui.menu }
        }

        x: card.x + (users ? (card.width - width) / 2 : 22)
        y: card.y + from.mapToItem(card, 0, 0).y - height - 8
        width: Math.max(220, column.implicitWidth + 12)
        height: column.implicitHeight + 12
        radius: Math.min(ui.t.radius, 18)
        color: ui.t.popup
        border.width: 1
        border.color: ui.t.border
        opacity: ui.menu ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: ui.menu ? 0 : 8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }

        Behavior on opacity { NumberAnimation { duration: 140 } }

        MouseArea { anchors.fill: parent }

        Column {
            id: column
            anchors.centerIn: parent
            width: parent.width - 12

            Repeater {
                model: list.items

                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === list.current
                    width: column.width
                    height: 34
                    radius: 12
                    color: itemArea.containsMouse ? ui.t.hover : "transparent"

                    Text {
                        id: tick
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        text: parent.selected ? ui.icons.check : ""
                        color: ui.t.accent
                        font.family: ui.t.iconFont
                        font.pixelSize: 14
                    }
                    Text {
                        anchors.left: tick.right
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData
                        color: ui.t.text
                        font.family: ui.t.font
                        font.pixelSize: 13
                        font.weight: parent.selected ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (list.users) ui.greeter.userIndex = parent.index
                            else ui.greeter.sessionIndex = parent.index
                            ui.closeMenu()
                        }
                    }
                }
            }
        }
    }
}
