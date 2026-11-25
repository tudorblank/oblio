// SPDX-License-Identifier: GPL-3.0-or-later
// The dock's state shared by its copies on every screen: the order of apps that aren't pinned.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property var otherOrder: []
}
