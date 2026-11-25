// SPDX-License-Identifier: GPL-3.0-or-later
// Date and time in a Qt date format and a language of its own; the popup is a month calendar.
import QtQuick
import Quickshell
import qs.services
import qs.controls
import qs.bar

BarWidget {
    id: w

    readonly property var locale: Qt.locale(opt("language"))
    readonly property string format: opt("format") || "HH:mm"
    readonly property string formatted: clock.date.toLocaleString(locale, format)
    // a side bar stacks the parts: "Tue 24 Nov 15:13" -> Tue / 24 / Nov / 15 / 13
    readonly property string shown: vertical ? formatted.split(/[\s:]+/).filter(p => p).join("\n") : formatted

    length: vertical ? label.implicitHeight : label.implicitWidth
    popup: calendar
    popupWidth: 292

    SystemClock {
        id: clock
        precision: /s/.test(w.format) ? SystemClock.Seconds : SystemClock.Minutes
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: w.shown
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 0.95
        color: Theme.text
        font.family: Theme.fontUi
        // a share of the bar's thickness (option size, %): never bigger than the bar
        font.pixelSize: Math.max(8, Math.round(w.thickness * w.opt("size") / 100 * (w.vertical ? w.m.smallText / w.m.text : 1)))
        font.weight: Font.Medium
        font.features: { "tnum": 1 }
    }

    Component {
        id: calendar

        Column {
            id: cal
            property int shift: 0          // months away from this one
            readonly property date today: clock.date
            readonly property date month: new Date(today.getFullYear(), today.getMonth() + shift, 1)
            // the week starts as the system's formats say; names in the clock's language
            readonly property int firstDay: Qt.locale().firstDayOfWeek % 7      // 0 = Sunday
            readonly property var names: w.locale
            readonly property int lead: (month.getDay() - firstDay + 7) % 7
            spacing: 6
            topPadding: 4
            bottomPadding: 4

            Item {
                width: parent.width
                height: 32

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: cal.month.toLocaleDateString(cal.names, "MMMM yyyy")
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.textTitle
                    font.weight: Font.DemiBold
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    IconButton { size: 28; icon: Icons.chevronLeft; onClicked: cal.shift-- }
                    IconButton { size: 28; icon: Icons.dot; onClicked: cal.shift = 0 }
                    IconButton { size: 28; icon: Icons.chevronRight; onClicked: cal.shift++ }
                }
            }

            Grid {
                columns: 7
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: 7
                    Text {
                        required property int index
                        width: 38
                        height: 24
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: cal.names.dayName((cal.firstDay + index) % 7, Locale.ShortFormat).slice(0, 2)
                        color: Theme.subtext
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.textCaption
                        font.weight: Font.DemiBold
                    }
                }

                Repeater {
                    model: 42
                    Item {
                        required property int index
                        readonly property date day: new Date(cal.month.getFullYear(), cal.month.getMonth(), 1 - cal.lead + index)
                        readonly property bool inMonth: day.getMonth() === cal.month.getMonth()
                        readonly property bool isToday: day.toDateString() === cal.today.toDateString()
                        width: 38
                        height: 32
                        Rectangle {
                            anchors.centerIn: parent
                            width: 30
                            height: 30
                            radius: 15
                            color: parent.isToday ? Theme.accent : "transparent"
                        }
                        Text {
                            anchors.centerIn: parent
                            text: parent.day.getDate()
                            color: parent.isToday ? Theme.accentFg : Theme.text
                            opacity: parent.inMonth ? 1 : 0.35
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.textLabel
                            font.weight: parent.isToday ? Font.Bold : Font.Normal
                        }
                    }
                }
            }
        }
    }
}
