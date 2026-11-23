-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- Oblio's desktop: window management, the shell (dock), polkit agent,
-- and the settings that go with them. Loaded from hyprland.lua.

require("oblio")

-- Dolphin's "Open with" menus outside Plasma
hl.env("XDG_MENU_PREFIX", "arch-")

hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
    hl.exec_cmd("qs -c oblio")
end)

-- the dock gets the blurred-glass look
hl.layer_rule({ match = { namespace = "oblio-dock" }, blur = true, ignore_alpha = 0.3 })

hl.config({
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})
