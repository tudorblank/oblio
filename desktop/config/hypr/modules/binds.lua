-- Keybinds: https://wiki.hypr.land/configuring/core/binds/

-- in a VM the host desktop keeps Super for itself, so the VM uses Alt
local mod = oblio.vm and "ALT" or "SUPER"

local terminal = "alacritty"
local files    = "thunar"
local browser  = "zen-browser"
local launcher = oblio.shell .. "/scripts/launcher"   -- rofi; again closes it
local settings = oblio.qs .. " ipc call settings toggle"

local function key(k, action, opts) hl.bind(mod .. " + " .. k, action, opts) end
local function run(cmd) return hl.dsp.exec_cmd(cmd) end

-- apps
key("Return", run(terminal))
key("E",      run(files))
key("W",      run(browser))
key("R",      run(launcher))
key("I",      run(settings))

-- windows
key("Q",         hl.dsp.window.close())
key("D",         hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
key("F",         hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
key("C",         function() oblio.minimize() end)
-- in a VM the main key already is Alt, so there it's Alt + Ctrl + C
key((oblio.vm and "CONTROL" or "ALT") .. " + C", function() oblio.restore_last() end)
key("SHIFT + D", function() oblio.toggle_desktop() end)
key("T",         function() oblio.toggle_mode() end)
key("V",         hl.dsp.window.float({ action = "toggle" }))
key((oblio.vm and "CONTROL" or "ALT") .. " + Space", hl.dsp.window.float({ action = "toggle" }))
key("J",         hl.dsp.layout("togglesplit")) -- dwindle
key("X",         hl.dsp.layout("togglesplit"))
key("SHIFT + J", hl.dsp.window.pseudo())       -- dwindle
key("Escape",    run("hyprctl kill"))          -- then click a frozen window to kill it
key("M",         run("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- focus and move with the arrows
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    key(dir,              hl.dsp.focus({ direction = dir }))
    key("SHIFT + " .. dir, hl.dsp.window.move({ direction = dir:sub(1, 1) }))
end
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())

-- resize with the arrows (dragging a window's edge, or mod + right-drag, works too)
local step = 40
local grow = { left = { -step, 0 }, right = { step, 0 }, up = { 0, -step }, down = { 0, step } }
for dir, d in pairs(grow) do
    key("CONTROL + SHIFT + " .. dir, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
end

-- workspaces 1..10 (0 = 10); SHIFT takes the window along
for i = 1, 10 do
    key(tostring(i % 10),              hl.dsp.focus({ workspace = i }))
    key("SHIFT + " .. tostring(i % 10), hl.dsp.window.move({ workspace = i }))
end
key("CONTROL + right", hl.dsp.focus({ workspace = "m+1" }))
key("CONTROL + left",  hl.dsp.focus({ workspace = "m-1" }))
key("CONTROL + down",  hl.dsp.focus({ workspace = "emptym" }))
key("mouse_down",      hl.dsp.focus({ workspace = "e+1" }))
key("mouse_up",        hl.dsp.focus({ workspace = "e-1" }))

-- move the window to the next / previous monitor
key("SHIFT + mouse_down", hl.dsp.window.move({ monitor = "+1" }))
key("SHIFT + mouse_up",   hl.dsp.window.move({ monitor = "-1" }))

-- scratchpad
key("P",         hl.dsp.workspace.toggle_special("magic"))
key("SHIFT + P", hl.dsp.window.move({ workspace = "special:magic" }))

-- drag to move, right-drag to resize
key("mouse:272", hl.dsp.window.drag(),   { mouse = true })
key("mouse:273", hl.dsp.window.resize(), { mouse = true })

-- zoom
local function zoom(step)
    local z = hl.get_config("cursor:zoom_factor") + step
    hl.config({ cursor = { zoom_factor = math.max(1.0, math.min(3.0, z)) } })
end
key("equal",   function() zoom(0.3) end,  { repeating = true })
key("minus",   function() zoom(-0.3) end, { repeating = true })
key("code:86", function() zoom(0.3) end,  { repeating = true }) -- keypad +
key("code:82", function() zoom(-0.3) end, { repeating = true }) -- keypad -

-- tools
hl.bind("CONTROL + SHIFT + Escape", run(terminal .. " -e btop")) -- task manager
key("SHIFT + I", run("hyprpicker -a -n"))                        -- color picker, copies the color

-- screenshots: saved to ~/Pictures/Screenshots and copied
local shot = 'd="$HOME/Pictures/Screenshots"; mkdir -p "$d"; f="$d/$(date +%Y-%m-%d_%H-%M-%S).png"; '
local region = run(shot .. 'grim -g "$(slurp)" "$f" && wl-copy < "$f"')
local screen = run(shot .. 'grim "$f" && wl-copy < "$f"')
key("S", region)
key("Print", screen)
hl.bind("Print", screen)

-- media keys, also while a shell menu is open
local held = { locked = true, repeating = true, submap_universal = true }
hl.bind("XF86AudioRaiseVolume",  run("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), held)
hl.bind("XF86AudioLowerVolume",  run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      held)
hl.bind("XF86AudioMute",         run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     held)
hl.bind("XF86AudioMicMute",      run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   held)
hl.bind("XF86MonBrightnessUp",   run("brightnessctl -e4 -n2 set 5%+"),                  held)
hl.bind("XF86MonBrightnessDown", run("brightnessctl -e4 -n2 set 5%-"),                  held)
hl.bind("XF86AudioNext",  run("playerctl next"),       { locked = true, submap_universal = true })
hl.bind("XF86AudioPause", run("playerctl play-pause"), { locked = true, submap_universal = true })
hl.bind("XF86AudioPlay",  run("playerctl play-pause"), { locked = true, submap_universal = true })
hl.bind("XF86AudioPrev",  run("playerctl previous"),   { locked = true, submap_universal = true })

-- while a shell menu or the launcher is open, this submap is on: no keybind reaches the windows,
-- SUPER+Q and SUPER+I close them (and leave the submap even if the shell doesn't answer)
hl.define_submap("oblio-menu", function()
    local function close()
        hl.dispatch(hl.dsp.submap("reset"))
        hl.exec_cmd(oblio.qs .. " ipc call menus close")
        hl.exec_cmd("pkill -x rofi")
    end
    key("Q", close)
    key("I", close)
end)
