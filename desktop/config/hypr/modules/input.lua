-- Keyboard, mouse, touchpad: https://wiki.hypr.land/configuring/core/variables/#input

-- keyboard layout: the console's (KEYMAP in /etc/vconsole.conf), when it is also a desktop layout
local function console_layout()
    local f = io.open("/etc/vconsole.conf")
    if not f then return "us" end
    local layout = f:read("*a"):match("KEYMAP=\"?([%w_-]+)")
    f:close()
    local xkb = layout and io.open("/usr/share/X11/xkb/symbols/" .. layout)
    if not xkb then return "us" end
    xkb:close()
    return layout
end

hl.config({
    input = {
        kb_layout  = console_layout(),
        kb_variant = "",
        kb_options = "",

        -- 1: hovering a window focuses it; 2: click to focus, scrolling still goes to the
        -- window under the pointer; 0: click to focus, scrolling too (settings: SUPER+I)
        follow_mouse = 2,
        -- 1: moving between tiled and floating windows also moves focus (0 with click to focus)
        float_switch_override_focus = 0,
        sensitivity  = 0, -- -1.0 to 1.0, 0 = unchanged

        touchpad = {
            natural_scroll = true,
        },
    },
})

-- touchpad: three fingers sideways switches workspace, up makes the window fullscreen,
-- down closes it
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
