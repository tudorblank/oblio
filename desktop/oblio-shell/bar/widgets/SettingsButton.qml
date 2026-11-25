// SPDX-License-Identifier: GPL-3.0-or-later
// Opens Oblio's settings (SUPER+I).
import QtQuick
import qs.services
import qs.bar

BarWidget {
    id: w
    length: row.length
    onActivated: b => { if (b === Qt.LeftButton) Menus.openSettings() }
    IconValue { id: row; widget: w; icon: Icons.settings }
}
