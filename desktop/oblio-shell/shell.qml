// SPDX-License-Identifier: GPL-3.0-or-later
//@ pragma IconTheme WhiteSur
// a fixed id keeps the state folder (settings.json) the same wherever this folder lives
//@ pragma ShellId oblio
// Oblio's shell: desktop/setup copies this folder to ~/.config/oblio-shell, Hyprland runs
// `qs -p ~/.config/oblio-shell`

import Quickshell
import qs.services
import qs.bar
import qs.dock
import qs.settings
import qs.notifications

ShellRoot {
    // starting it applies the theme to GTK, icons, fonts and the terminal
    readonly property var systemTheme: SystemTheme
    // leaves the menu keybind mode (binds.lua) if the shell restarted with a menu open
    readonly property var menus: Menus
    // the notification server starts with the shell, not when the bell first shows
    readonly property var notifications: Notifications

    Variants {
        model: Settings.opts.barEnabled ? Quickshell.screens : []

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Dock {
            required property var modelData
            screen: modelData
        }
    }

    SettingsPanel {}

    // new notifications, as cards (the server is services/Notifications.qml)
    Toasts {}
}
