// SPDX-License-Identifier: GPL-3.0-or-later
// Log out, sleep, restart, shut down. The ones that end the session ask for a second click.
import QtQuick
import Quickshell
import qs.services
import qs.controls
import qs.bar

BarWidget {
    id: w

    length: row.length
    popup: panel
    popupWidth: 230

    readonly property var actions: [
        { id: "suspend", icon: Icons.sleep, text: "Sleep", command: ["systemctl", "suspend"] },
        { id: "logout", icon: Icons.logout, text: "Log out", confirm: true,
          command: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"] },
        { id: "reboot", icon: Icons.restart, text: "Restart", confirm: true, command: ["systemctl", "reboot"] },
        { id: "poweroff", icon: Icons.power, text: "Shut down", confirm: true, command: ["systemctl", "poweroff"] },
    ]

    IconValue { id: row; widget: w; icon: Icons.power }

    Component {
        id: panel
        Column {
            id: list
            property string armed: ""
            Repeater {
                model: w.actions
                MenuEntry {
                    required property var modelData
                    readonly property bool asking: list.armed === modelData.id
                    icon: modelData.icon
                    text: asking ? `Click again to ${modelData.text.toLowerCase()}` : modelData.text
                    danger: asking
                    onClicked: {
                        if (modelData.confirm && !asking) { list.armed = modelData.id; return }
                        w.bar.closePopup()
                        Quickshell.execDetached(modelData.command)
                    }
                }
            }
        }
    }
}
