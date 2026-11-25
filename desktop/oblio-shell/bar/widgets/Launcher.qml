// SPDX-License-Identifier: GPL-3.0-or-later
// Opens the app launcher (scripts/launcher: rofi); again closes it.
import QtQuick
import Quickshell
import qs.services
import qs.bar

BarWidget {
    id: w
    length: row.length
    onActivated: b => { if (b === Qt.LeftButton) Quickshell.execDetached([Quickshell.shellDir + "/scripts/launcher"]) }
    IconValue { id: row; widget: w; icon: Icons.apps }
}
