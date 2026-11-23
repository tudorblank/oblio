-- Monitors: https://wiki.hypr.land/configuring/core/monitors/
-- `hyprctl monitors` lists names and modes. Choices made in Settings > Display are
-- saved to settings.lua and win over this.

-- every monitor: best mode, placed automatically, 100%
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- one monitor set by hand:
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })
