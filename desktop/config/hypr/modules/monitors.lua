-- Monitors: https://wiki.hypr.land/configuring/core/monitors/
-- `hyprctl monitors` lists names and modes.

-- every monitor: best mode, placed automatically
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- one monitor set by hand:
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })
