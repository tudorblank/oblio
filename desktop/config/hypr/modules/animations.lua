-- Animations: https://wiki.hypr.land/configuring/core/animations/

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

-- each animation's own pace (speed = tenths of a second); Settings > Appearance > Animations
-- scales them all with oblio.animate (settings.lua calls it)
local base = {
    { "global",         10,   bezier = "default" },
    { "border",         5.39, bezier = "easeOutQuint" },
    { "windows",        4.79, spring = "easy" },
    -- opening: quick and without the spring's overshoot (the spring took ~430 ms of a terminal's
    -- ~640 ms to appear, measured); moving keeps the spring (windows.lua's SETTLE is measured on it)
    { "windowsIn",      2.5,  bezier = "easeOutQuint", style = "popin 87%" },
    { "windowsOut",     1.49, bezier = "linear",       style = "popin 87%" },
    { "fadeIn",         1.73, bezier = "almostLinear" },
    { "fadeOut",        1.46, bezier = "almostLinear" },
    { "fade",           3.03, bezier = "quick" },
    { "layers",         3.81, bezier = "easeOutQuint" },
    { "layersIn",       4,    bezier = "easeOutQuint", style = "fade" },
    { "layersOut",      1.5,  bezier = "linear",       style = "fade" },
    { "fadeLayersIn",   1.79, bezier = "almostLinear" },
    { "fadeLayersOut",  1.39, bezier = "almostLinear" },
    { "workspaces",     1.94, bezier = "almostLinear", style = "fade" },
    { "workspacesIn",   1.21, bezier = "almostLinear", style = "fade" },
    { "workspacesOut",  1.94, bezier = "almostLinear", style = "fade" },
    { "zoomFactor",     7,    bezier = "quick" },
}

-- factor: how long animations take against their own pace (0.5 = twice as fast); on: animations at
-- all. oblio.motion is that for Oblio's own timings (windows.lua), 0 with animations off
function oblio.animate(factor, on)
    oblio.motion = on and factor or 0
    hl.config({ animations = { enabled = on } })
    for _, a in ipairs(base) do
        local spec = { leaf = a[1], enabled = true, speed = a[2] * factor }
        for k, v in pairs(a) do if type(k) == "string" then spec[k] = v end end
        hl.animation(spec)
    end
end
oblio.animate(1, true)
