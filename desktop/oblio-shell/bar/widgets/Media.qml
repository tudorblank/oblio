// SPDX-License-Identifier: GPL-3.0-or-later
// What's playing (MPRIS): the playing player, or else the first one. Middle click plays or pauses; the
// popup has the art, where it plays from, seeking and the controls. A side bar shows the art only.
import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.services
import qs.controls
import qs.bar

BarWidget {
    id: w

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: player !== null && player.isPlaying
    readonly property string title: player ? (player.trackTitle || player.identity || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string art: player ? (player.trackArtUrl || "") : ""
    readonly property bool hidden: player === null || (opt("hideIdle") && !playing)
    // it lingers a moment after it would hide (skipping and seeking pause the player for an
    // instant), and slides open and shut; meanwhile it shows what it showed last
    property bool shown: false
    Component.onCompleted: shown = !hidden
    onHiddenChanged: if (hidden) linger.restart(); else { linger.stop(); shown = true }
    Timer { id: linger; interval: 1500; onTriggered: w.shown = !w.hidden }
    property string keptTitle
    property string keptArtist
    property string keptArt
    Binding { target: w; property: "keptTitle"; value: w.title; when: w.player !== null; restoreMode: Binding.RestoreNone }
    Binding { target: w; property: "keptArtist"; value: w.artist; when: w.player !== null; restoreMode: Binding.RestoreNone }
    Binding { target: w; property: "keptArt"; value: w.art; when: w.player !== null; restoreMode: Binding.RestoreNone }

    function clock(s) {
        s = Math.max(0, Math.floor(s))
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = String(s % 60).padStart(2, "0")
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${sec}` : `${m}:${sec}`
    }

    reveal: shown ? 1 : 0
    Behavior on reveal { Anim {} }
    length: (vertical ? Math.round(thickness * 0.62) : row.implicitWidth) * reveal
    clip: true
    popup: panel
    popupWidth: 340
    onActivated: b => { if (b === Qt.MiddleButton && player) player.togglePlaying() }

    Row {
        id: row
        anchors.centerIn: parent
        opacity: w.reveal
        spacing: Math.round(w.thickness * 0.22)

        ClippingRectangle {
            visible: w.opt("art") && w.keptArt !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(w.thickness * 0.62)
            height: width
            radius: Math.round(width * 0.22)
            color: Theme.card
            Image {
                anchors.fill: parent
                source: w.keptArt
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 64
                sourceSize.height: 64
                asynchronous: true
            }
        }
        Text {
            visible: !(w.opt("art") && w.keptArt !== "")
            anchors.verticalCenter: parent.verticalCenter
            text: w.playing ? Icons.music : Icons.pause
            color: Theme.text
            font.family: Theme.iconFont
            font.pixelSize: w.iconSize
        }
        TextMetrics { id: metrics; font: label.font; text: label.text }
        Text {
            id: label
            visible: !w.vertical
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(Math.ceil(metrics.advanceWidth) + 1, w.opt("maxLength") - x)
            text: w.keptArtist ? `${w.keptTitle}  ·  ${w.keptArtist}` : w.keptTitle
            elide: Text.ElideRight
            color: Theme.text
            opacity: w.playing ? 1 : 0.6
            font.family: Theme.fontUi
            font.pixelSize: w.textSize
            font.weight: Font.Medium
        }
    }

    Component {
        id: panel

        Column {
            id: card
            readonly property var p: w.player
            spacing: 12
            topPadding: 8
            bottomPadding: 8

            // MPRIS doesn't announce the position as it moves
            Timer {
                running: w.popupOpen && w.playing
                interval: 500
                repeat: true
                triggeredOnStart: true
                onTriggered: if (card.p) card.p.positionChanged()
            }

            Row {
                x: 8
                width: parent.width - 16
                spacing: 14

                ClippingRectangle {
                    width: 84
                    height: 84
                    radius: 12
                    color: Theme.card
                    Image {
                        anchors.fill: parent
                        source: w.art
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 168
                        sourceSize.height: 168
                        asynchronous: true
                    }
                    Text {
                        visible: w.art === ""
                        anchors.centerIn: parent
                        text: Icons.music
                        color: Theme.subtext
                        font.family: Theme.iconFont
                        font.pixelSize: 32
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 98
                    spacing: 3
                    Text {
                        width: parent.width
                        text: w.title || "Nothing playing"
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        color: Theme.text
                        font.family: Theme.fontUi
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                    Text {
                        visible: text !== ""
                        width: parent.width
                        text: w.artist
                        elide: Text.ElideRight
                        color: Theme.text
                        opacity: 0.8
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.textBody
                    }
                    Text {
                        width: parent.width
                        text: card.p ? `from ${card.p.identity}` : ""
                        elide: Text.ElideRight
                        color: Theme.subtext
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.textCaption
                    }
                }
            }

            // seeking: drag or click on the line
            Column {
                visible: card.p !== null && card.p.lengthSupported && card.p.length > 0
                x: 8
                width: parent.width - 16
                spacing: 4

                Item {
                    id: seek
                    width: parent.width
                    height: 16
                    property real dragFrac: -1
                    readonly property real frac: dragFrac >= 0 ? dragFrac
                        : card.p && card.p.length > 0 ? Math.max(0, Math.min(1, card.p.position / card.p.length)) : 0

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Theme.control
                        Rectangle {
                            width: parent.width * seek.frac
                            height: parent.height
                            radius: 2
                            color: Theme.accent
                        }
                    }
                    Rectangle {
                        visible: card.p !== null && card.p.canSeek
                        x: seek.width * seek.frac - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: seekArea.containsMouse || seekArea.pressed ? 14 : 10
                        height: width
                        radius: width / 2
                        color: Theme.knob
                        Behavior on width { NumberAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: seekArea
                        anchors.fill: parent
                        enabled: card.p !== null && card.p.canSeek
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor
                        function at(x) { return Math.max(0, Math.min(1, x / width)) }
                        onPressed: m => seek.dragFrac = at(m.x)
                        onPositionChanged: m => { if (pressed) seek.dragFrac = at(m.x) }
                        onReleased: {
                            if (card.p) card.p.position = seek.dragFrac * card.p.length
                            seek.dragFrac = -1
                        }
                        onCanceled: seek.dragFrac = -1
                    }
                }

                Item {
                    width: parent.width
                    height: 14
                    Text {
                        text: card.p ? w.clock(seek.frac * card.p.length) : ""
                        color: Theme.subtext
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.textCaption
                    }
                    Text {
                        anchors.right: parent.right
                        text: card.p ? w.clock(card.p.length) : ""
                        color: Theme.subtext
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.textCaption
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.previous
                    enabled: card.p !== null && card.p.canGoPrevious
                    onClicked: card.p.previous()
                }
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 46
                    primary: true
                    icon: w.playing ? Icons.pause : Icons.play
                    enabled: card.p !== null && card.p.canTogglePlaying
                    onClicked: card.p.togglePlaying()
                }
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.next
                    enabled: card.p !== null && card.p.canGoNext
                    onClicked: card.p.next()
                }
            }
        }
    }
}
