// SPDX-License-Identifier: GPL-3.0-or-later
//@ pragma IconTheme breeze
// Oblio shell: run with `qs -c oblio`

import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens

        Dock {
            required property var modelData
            screen: modelData
        }
    }

    SettingsPanel {}
}
