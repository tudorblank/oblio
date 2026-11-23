-- Oblio's Hyprland config: https://wiki.hypr.land/configuring/
-- Each part lives in modules/. settings.lua holds what you change in Oblio's
-- settings (SUPER+I) and wins over the modules.

require("modules.env")
require("modules.monitors")
require("modules.input")
require("modules.layout")
require("modules.decorations")
require("modules.animations")
require("modules.misc")
require("modules.windowrules")
require("modules.windows")
require("modules.binds")
require("modules.autostart")

-- loaded with dofile, so the settings panel saving it doesn't reload Hyprland
local settings = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/settings.lua"
local f = io.open(settings)
if f then
    f:close()
    pcall(dofile, settings)
end
