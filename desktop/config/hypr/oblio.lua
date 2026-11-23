-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- Oblio window management for Hyprland:
--   minimize / restore (any number of windows), show desktop,
--   per-workspace tiling <-> floating mode.
-- Minimized windows live on the hidden workspace "special:minimized".
-- Keys: oblio-keys.lua. Everything is reachable from outside (the dock) through
--   hyprctl dispatch 'function() oblio.restore("0x...") end'

oblio = oblio or {}

local MINIMIZED = "special:minimized"

-- kept on the global table so a config reload doesn't forget minimized windows
local s = oblio.state or {
    floating = {},    -- workspace id -> true when the workspace is in floating mode
    floated = {},     -- address -> true for windows floated by floating mode
    origin = {},      -- address -> workspace id it was minimized from
    order = {},       -- minimized addresses, oldest first
    desktop = nil,    -- addresses hidden by show_desktop, to bring back together
}
oblio.state = s

local function sel(address) return "address:" .. address end
local function win(address) return hl.get_window(sel(address)) end

local function notify(text)
    hl.notification.create({ text = text, duration = 1200, font_size = 14 })
end

local function forget(address)
    s.origin[address] = nil
    for i = #s.order, 1, -1 do
        if s.order[i] == address then table.remove(s.order, i) end
    end
end

local function is_minimized(w)
    return w and w.workspace and w.workspace.name == MINIMIZED
end

---------------------------------------------------------------------------
-- minimize / restore
---------------------------------------------------------------------------

function oblio.minimize(w)
    if type(w) == "string" then w = win(w) end
    w = w or hl.get_active_window()
    if not w or not w.workspace or w.workspace.special then return end
    forget(w.address)
    s.origin[w.address] = w.workspace.id
    table.insert(s.order, w.address)
    hl.dispatch(hl.dsp.window.move({ workspace = MINIMIZED, follow = false, window = sel(w.address) }))
end

-- brings a minimized window back to the workspace you're on, and focuses it
function oblio.restore(w)
    if type(w) == "string" then w = win(w) end
    if not is_minimized(w) then return end
    local here = hl.get_active_workspace()
    local target = (here and here.id) or s.origin[w.address] or 1
    forget(w.address)
    hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false, window = sel(w.address) }))
    hl.dispatch(hl.dsp.focus({ window = sel(w.address) }))
end

function oblio.restore_last()
    local address = s.order[#s.order]
    if address then oblio.restore(address) end
end

function oblio.restore_all()
    for i = #s.order, 1, -1 do oblio.restore(s.order[i]) end
end

-- minimize every window on this workspace; run again to bring them all back
function oblio.toggle_desktop()
    if s.desktop then
        local batch = s.desktop
        s.desktop = nil
        for _, address in ipairs(batch) do oblio.restore(address) end
        return
    end
    local ws = hl.get_active_workspace()
    if not ws then return end
    local batch = {}
    for _, w in ipairs(hl.get_workspace_windows(ws.id)) do
        if w.mapped then
            oblio.minimize(w)
            table.insert(batch, w.address)
        end
    end
    if #batch > 0 then s.desktop = batch end
end

-- the app's own minimize button, or a dock/taskbar asking (wlr foreign-toplevel)
hl.on("window.minimize", function(w, minimized)
    if minimized then oblio.minimize(w) else oblio.restore(w) end
end)

-- a closed window is no longer minimized
hl.on("window.close", function(w)
    if w then forget(w.address) end
end)

---------------------------------------------------------------------------
-- per-workspace tiling <-> floating
---------------------------------------------------------------------------

-- how many other floating windows the workspace already has, for cascading
local function floating_count(ws, except)
    local n = 0
    for _, o in ipairs(hl.get_workspace_windows(ws.id)) do
        if o.floating and o.address ~= except then n = n + 1 end
    end
    return n
end

-- floating mode places windows like a normal desktop: a comfortable size,
-- centered, each new one a step down and right of the last (cascade)
local function float_window(w)
    if not w or w.floating then return end
    local m = w.monitor
    local step = w.workspace and (floating_count(w.workspace, w.address) % 6) * 32 or 0
    hl.dispatch(hl.dsp.window.float({ action = "enable", window = sel(w.address) }))
    if m then
        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(m.width / m.scale * 0.6),
            y = math.floor(m.height / m.scale * 0.65),
            window = sel(w.address),
        }))
    end
    hl.dispatch(hl.dsp.window.center({ window = sel(w.address) }))
    if step > 0 then
        hl.dispatch(hl.dsp.window.move({ x = step, y = step, relative = true, window = sel(w.address) }))
    end
    s.floated[w.address] = true
end

local function tile_window(w)
    if not w or not s.floated[w.address] then return end
    s.floated[w.address] = nil
    if w.floating then
        hl.dispatch(hl.dsp.window.float({ action = "disable", window = sel(w.address) }))
    end
end

function oblio.is_floating(id)
    return s.floating[id] == true
end

function oblio.toggle_mode()
    local ws = hl.get_active_workspace()
    if not ws or ws.special then return end
    local floating = not s.floating[ws.id]
    s.floating[ws.id] = floating or nil
    for _, w in ipairs(hl.get_workspace_windows(ws.id)) do
        if floating then float_window(w) else tile_window(w) end
    end
    notify("Workspace " .. ws.id .. ": " .. (floating and "floating" or "tiling"))
end

hl.on("window.open", function(w)
    if w and w.workspace and s.floating[w.workspace.id] then float_window(w) end
end)

-- moving a window into or out of a floating workspace follows that workspace's mode
hl.on("window.move_to_workspace", function(w, ws)
    if not w or not ws or ws.special then return end
    if s.floating[ws.id] then float_window(w) else tile_window(w) end
end)

return oblio
