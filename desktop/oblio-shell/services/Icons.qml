// SPDX-License-Identifier: GPL-3.0-or-later
// Every icon the shell draws, by name: Material Design glyphs from the Nerd Font (Theme.iconFont).
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // shell and session
    readonly property string apps: "\u{f003b}"
    readonly property string search: "\u{f0349}"
    readonly property string settings: "\u{f0493}"
    readonly property string bar: "\u{f1513}"
    readonly property string dock: "\u{f10a9}"
    readonly property string display: "\u{f0379}"
    readonly property string windows: "\u{f05af}"
    readonly property string menu: "\u{f035c}"
    readonly property string appearance: "\u{f03d8}"
    readonly property string input: "\u{f030c}"
    readonly property string wallpaper: "\u{f0e09}"
    readonly property string power: "\u{f0425}"
    readonly property string sleep: "\u{f0904}"
    readonly property string logout: "\u{f0343}"
    readonly property string restart: "\u{f0709}"
    readonly property string lock: "\u{f033e}"

    // small controls
    readonly property string close: "\u{f0156}"
    readonly property string check: "\u{f012c}"
    readonly property string chevronDown: "\u{f0140}"
    readonly property string chevronLeft: "\u{f0141}"
    readonly property string chevronRight: "\u{f0142}"
    readonly property string dot: "\u{f09de}"
    readonly property string forget: "\u{f09e7}"
    readonly property string disconnect: "\u{f0338}"
    readonly property string trash: "\u{f0a7a}"
    readonly property string image: "\u{f02e9}"
    readonly property string folder: "\u{f024b}"
    readonly property string edit: "\u{f03eb}"
    readonly property string drag: "\u{f01dd}"

    // bar widgets
    readonly property string workspaces: "\u{f0570}"
    readonly property string window: "\u{f05b2}"
    readonly property string clock: "\u{f0954}"
    readonly property string tray: "\u{f1294}"
    readonly property string spacer: "\u{f084e}"
    readonly property string separator: "\u{f01d9}"

    // media
    readonly property string music: "\u{f075a}"
    readonly property string media: "\u{f0386}"
    readonly property string play: "\u{f040a}"
    readonly property string pause: "\u{f03e4}"
    readonly property string next: "\u{f04ad}"
    readonly property string previous: "\u{f04ae}"

    // sound and screen
    readonly property var volume: ["\u{f0581}", "\u{f057f}", "\u{f0580}", "\u{f057e}"]   // muted, low, medium, high
    readonly property string mic: "\u{f036c}"
    readonly property string micOff: "\u{f036d}"
    readonly property var brightness: ["\u{f00de}", "\u{f00df}", "\u{f00e0}"]            // low, medium, high

    // battery: by tens, empty .. full
    readonly property var battery: ["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}",
                                    "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]
    readonly property string charging: "\u{f0084}"

    // network
    readonly property var wifi: ["\u{f092f}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"]   // 0..4 bars
    readonly property string wifiOff: "\u{f05aa}"
    readonly property string wifiOn: "\u{f05a9}"
    readonly property string ethernet: "\u{f0200}"
    readonly property string cableUnplugged: "\u{f0319}"

    // bluetooth and its devices
    readonly property string bluetooth: "\u{f00af}"
    readonly property string bluetoothOff: "\u{f00b2}"
    readonly property string bluetoothConnected: "\u{f00b1}"
    function device(kind) {
        return /headset|headphone/.test(kind) ? "\u{f02cb}" : /mouse/.test(kind) ? "\u{f037d}"
            : /keyboard/.test(kind) ? "\u{f030c}" : /phone/.test(kind) ? "\u{f011c}"
            : /gaming|joystick/.test(kind) ? "\u{f0297}" : /audio|speaker/.test(kind) ? "\u{f04c3}"
            : /computer/.test(kind) ? "\u{f0322}" : bluetooth
    }

    // notifications
    readonly property string bell: "\u{f009a}"
    readonly property string bellOff: "\u{f009b}"
    readonly property string bellUnread: "\u{f116b}"
}
