// SPDX-License-Identifier: GPL-3.0-or-later
// Opens Search (search/Search.qml); again closes it.
import QtQuick
import qs.services
import qs.bar

BarWidget {
    id: w
    length: row.length
    onActivated: b => { if (b === Qt.LeftButton) Menus.request("search", "toggle") }
    IconValue { id: row; widget: w; icon: Icons.search }
}
