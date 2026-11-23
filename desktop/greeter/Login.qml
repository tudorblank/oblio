// SPDX-License-Identifier: GPL-3.0-or-later
// Clock, the login card (avatar, name, password) and the bottom bar (session, power).
import QtQuick
import Quickshell

Item {
    id: ui

    required property var greeter
    readonly property string font: "Inter"
    readonly property string iconFont: {
        const all = Qt.fontFamilies()
        return all.includes("Symbols Nerd Font") ? "Symbols Nerd Font" : all.find(f => f.includes("Nerd Font")) ?? ""
    }
    property bool sessionsOpen: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // clock
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.17
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "#f4f4f6"
            font.family: ui.font
            font.pixelSize: 112
            font.weight: Font.Light
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: "#b8b8c2"
            font.family: ui.font
            font.pixelSize: 20
        }
    }

    // login card
    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.5
        width: 360
        height: content.implicitHeight + 56
        radius: 28
        color: "#59141418"
        border.width: 1
        border.color: "#1fffffff"

        // shake when the password is wrong
        transform: Translate { id: shift }
        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: shift; property: "x"; to: -12; duration: 50 }
            NumberAnimation { target: shift; property: "x"; to: 10; duration: 70 }
            NumberAnimation { target: shift; property: "x"; to: -6; duration: 70 }
            NumberAnimation { target: shift; property: "x"; to: 0; duration: 60 }
        }
        Connections {
            target: ui.greeter
            function onFailed() { shake.restart(); field.forceActiveFocus() }
        }

        Column {
            id: content
            anchors.centerIn: parent
            width: parent.width - 56
            spacing: 14

            // avatar: the user's initial
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 84
                height: 84
                radius: 42
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.lighter(ui.greeter.accent, 1.25) }
                    GradientStop { position: 1; color: Qt.darker(ui.greeter.accent, 1.35) }
                }
                border.width: 2
                border.color: "#33ffffff"

                Text {
                    anchors.centerIn: parent
                    text: ui.greeter.user ? ui.greeter.user.display.charAt(0).toUpperCase() : ""
                    color: "white"
                    font.family: ui.font
                    font.pixelSize: 36
                    font.weight: Font.DemiBold
                }
            }

            // name; arrows switch user when there is more than one
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Text {
                    visible: ui.greeter.users.length > 1
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: prevArea.containsMouse ? "#ffffff" : "#80ffffff"
                    font.family: ui.iconFont
                    font.pixelSize: 13
                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        onClicked: ui.greeter.userIndex = (ui.greeter.userIndex + ui.greeter.users.length - 1) % ui.greeter.users.length
                    }
                }

                Text {
                    text: ui.greeter.user ? ui.greeter.user.display : "No users"
                    color: "#f4f4f6"
                    font.family: ui.font
                    font.pixelSize: 21
                    font.weight: Font.Medium
                }

                Text {
                    visible: ui.greeter.users.length > 1
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: nextArea.containsMouse ? "#ffffff" : "#80ffffff"
                    font.family: ui.iconFont
                    font.pixelSize: 13
                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        onClicked: ui.greeter.userIndex = (ui.greeter.userIndex + 1) % ui.greeter.users.length
                    }
                }
            }

            // password
            Rectangle {
                width: parent.width
                height: 46
                radius: 23
                color: "#14ffffff"
                border.width: 1
                border.color: field.activeFocus ? Qt.rgba(ui.greeter.accent.r, ui.greeter.accent.g, ui.greeter.accent.b, 0.8) : "#1fffffff"

                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: field
                    anchors.left: parent.left
                    anchors.right: go.left
                    anchors.leftMargin: 20
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: "#f4f4f6"
                    selectionColor: ui.greeter.accent
                    font.family: ui.font
                    font.pixelSize: 16
                    font.letterSpacing: 2
                    clip: true
                    focus: true
                    enabled: !ui.greeter.busy
                    text: ui.greeter.password
                    onTextChanged: ui.greeter.password = text
                    onAccepted: ui.greeter.login()
                    Keys.onEscapePressed: { text = ""; ui.sessionsOpen = false }
                    Component.onCompleted: forceActiveFocus()

                    Text {
                        visible: !field.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: ui.greeter.busy ? "Signing in…" : "Password"
                        color: "#80ffffff"
                        font.family: ui.font
                        font.pixelSize: 15
                    }
                }

                Rectangle {
                    id: go
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 18
                    color: goArea.containsMouse ? Qt.lighter(ui.greeter.accent, 1.15) : ui.greeter.accent
                    opacity: field.text || ui.greeter.busy ? 1 : 0.45

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: "white"
                        font.family: ui.iconFont
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: goArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: ui.greeter.login()
                    }
                }
            }

            Text {
                width: parent.width
                height: ui.greeter.message ? implicitHeight : 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: ui.greeter.message
                color: "#ff8a8d"
                font.family: ui.font
                font.pixelSize: 13
            }
        }
    }

    // bottom left: session
    Rectangle {
        id: sessionPill
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 28
        width: sessionRow.implicitWidth + 32
        height: 40
        radius: 20
        color: sessionArea.containsMouse || ui.sessionsOpen ? "#26ffffff" : "#14ffffff"
        border.width: 1
        border.color: "#1fffffff"

        Row {
            id: sessionRow
            anchors.centerIn: parent
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: "#c8c8d0"
                font.family: ui.iconFont
                font.pixelSize: 14
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ui.greeter.session ? ui.greeter.session.name : "No sessions"
                color: "#f4f4f6"
                font.family: ui.font
                font.pixelSize: 14
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ui.sessionsOpen ? "" : ""
                color: "#a0a0aa"
                font.family: ui.iconFont
                font.pixelSize: 10
            }
        }

        MouseArea {
            id: sessionArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: ui.sessionsOpen = !ui.sessionsOpen
        }
    }

    // session list, opens upward
    Rectangle {
        anchors.left: sessionPill.left
        anchors.bottom: sessionPill.top
        anchors.bottomMargin: 10
        width: Math.max(240, list.implicitWidth + 12)
        height: list.implicitHeight + 12
        radius: 18
        color: "#e6141418"
        border.width: 1
        border.color: "#1fffffff"
        opacity: ui.sessionsOpen ? 1 : 0
        visible: opacity > 0
        transform: Translate { y: ui.sessionsOpen ? 0 : 8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }

        Behavior on opacity { NumberAnimation { duration: 140 } }

        Column {
            id: list
            anchors.centerIn: parent
            width: parent.width - 12

            Repeater {
                model: ui.greeter.sessions

                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool current: index === ui.greeter.sessionIndex
                    width: list.width
                    height: 38
                    radius: 12
                    color: current ? Qt.rgba(ui.greeter.accent.r, ui.greeter.accent.g, ui.greeter.accent.b, 0.22) : itemArea.containsMouse ? "#14ffffff" : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData.name
                        color: "#f4f4f6"
                        font.family: ui.font
                        font.pixelSize: 14
                        font.weight: parent.current ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            ui.greeter.sessionIndex = parent.index
                            ui.sessionsOpen = false
                            field.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    // bottom right: power
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 12

        Repeater {
            model: [
                { icon: "", cmd: ["systemctl", "reboot"] },
                { icon: "", cmd: ["systemctl", "poweroff"] },
            ]

            Rectangle {
                required property var modelData
                width: 40
                height: 40
                radius: 20
                color: powerArea.containsMouse ? "#26ffffff" : "#14ffffff"
                border.width: 1
                border.color: "#1fffffff"

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData.icon
                    color: "#e4e4ea"
                    font.family: ui.iconFont
                    font.pixelSize: 15
                }

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(parent.modelData.cmd)
                }
            }
        }
    }

    // Oblio mark, bottom center
    Image {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        source: "file:///usr/share/pixmaps/oblio.svg"
        sourceSize: Qt.size(56, 56)
        width: 28
        height: 28
        opacity: 0.9
    }
}
