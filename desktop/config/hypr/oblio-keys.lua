-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- Oblio's keybinds. hyprland.lua calls this with its main key and programs:
--   require("oblio-keys")({ mod = mainMod, terminal = ..., files = ..., browser = ..., launcher = ... })

local oblio = require("oblio")

return function(o)
    local function key(k, action, opts) hl.bind(o.mod .. " + " .. k, action, opts) end

    -- apps
    key("Return", hl.dsp.exec_cmd(o.terminal))
    key("E",      hl.dsp.exec_cmd(o.files))
    key("W",      hl.dsp.exec_cmd(o.browser))
    key("R",      hl.dsp.exec_cmd(o.launcher))
    key("I",      hl.dsp.exec_cmd("qs -c oblio ipc call settings toggle"))

    -- windows
    key("Q",         hl.dsp.window.close())
    key("D",         hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
    key("F",         hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
    key("C",         function() oblio.minimize() end)
    key("SHIFT + C", function() oblio.restore_last() end)
    key("SHIFT + D", function() oblio.toggle_desktop() end)
    key("T",         function() oblio.toggle_mode() end)
    key("V",         hl.dsp.window.float({ action = "toggle" }))
    key("P",         hl.dsp.window.pseudo())
    key("J",         hl.dsp.layout("togglesplit"))    -- dwindle only
    key("M",         hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

    -- focus with arrows
    for _, dir in ipairs({ "left", "right", "up", "down" }) do
        key(dir, hl.dsp.focus({ direction = dir }))
    end

    -- workspaces 1..10 (0 = 10); SHIFT moves the window there
    for i = 1, 10 do
        key(tostring(i % 10),              hl.dsp.focus({ workspace = i }))
        key("SHIFT + " .. tostring(i % 10), hl.dsp.window.move({ workspace = i }))
    end
    key("mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    key("mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

    -- scratchpad
    key("S",         hl.dsp.workspace.toggle_special("magic"))
    key("SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

    -- drag to move, right-drag to resize
    key("mouse:272", hl.dsp.window.drag(),   { mouse = true })
    key("mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- media keys
    local function media(k, cmd, opts) hl.bind(k, hl.dsp.exec_cmd(cmd), opts) end
    local held = { locked = true, repeating = true }
    media("XF86AudioRaiseVolume",  "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", held)
    media("XF86AudioLowerVolume",  "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",      held)
    media("XF86AudioMute",         "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",     held)
    media("XF86AudioMicMute",      "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",   held)
    media("XF86MonBrightnessUp",   "brightnessctl -e4 -n2 set 5%+",                  held)
    media("XF86MonBrightnessDown", "brightnessctl -e4 -n2 set 5%-",                  held)
    media("XF86AudioNext",  "playerctl next",       { locked = true })
    media("XF86AudioPause", "playerctl play-pause", { locked = true })
    media("XF86AudioPlay",  "playerctl play-pause", { locked = true })
    media("XF86AudioPrev",  "playerctl previous",   { locked = true })
end
