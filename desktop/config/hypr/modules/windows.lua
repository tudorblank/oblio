-- Oblio window management: minimize / restore (any number of windows), show
-- desktop, per-workspace tiling <-> floating mode. Keys are in binds.lua.
-- Minimized windows live on the hidden workspace "special:minimized" and come back
-- where they were: same workspace, and for floating windows the same place and size.
-- Nothing here moves the pointer. The dock calls these through
--   hyprctl dispatch 'function() oblio.toggle_app({ "0x..." }) end'

oblio = oblio or {}

local MINIMIZED = "special:minimized"

local s = oblio.state or {
    floating = {},    -- workspace id -> true when the workspace is in floating mode
    floated = {},     -- address -> true for windows floated by floating mode
    saved = {},       -- address -> where it was when minimized: workspace, floating, place, size
    order = {},       -- minimized addresses, oldest first
    desktop = nil,    -- addresses hidden by show_desktop, to bring back together
}
oblio.state = s

local function sel(address) return "address:" .. address end
local function win(address) return hl.get_window(sel(address)) end

local function notify(text)
    hl.notification.create({ text = text, duration = 1200, font_size = 14 })
end

-- runs fn without Hyprland moving the pointer onto the windows it focuses
local function quietly(fn)
    local before = hl.get_config("cursor:no_warps")
    hl.config({ cursor = { no_warps = true } })
    fn()
    hl.config({ cursor = { no_warps = before } })
end

local function forget(address)
    s.saved[address] = nil
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
    local m = w.monitor
    s.saved[w.address] = {
        workspace = w.workspace.id,
        floating  = w.floating,
        -- relative to the monitor: the workspace may come back on another one
        x = w.at.x - (m and m.x or 0), y = w.at.y - (m and m.y or 0),
        width = w.size.x, height = w.size.y,
    }
    table.insert(s.order, w.address)
    hl.dispatch(hl.dsp.window.move({ workspace = MINIMIZED, follow = false, window = sel(w.address) }))
end

-- puts a minimized window back where it was and focuses it (switching to its workspace)
function oblio.restore(w)
    if type(w) == "string" then w = win(w) end
    if not is_minimized(w) then return end
    local address = w.address
    local saved = s.saved[address]
    local here = hl.get_active_workspace()
    local target = (saved and saved.workspace) or (here and here.id) or 1
    forget(address)
    quietly(function()
        hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false, window = sel(address) }))
        if saved and saved.floating then
            hl.dispatch(hl.dsp.window.float({ action = "enable", window = sel(address) }))
            hl.dispatch(hl.dsp.window.resize({ x = saved.width, y = saved.height, window = sel(address) }))
            local m = (win(address) or {}).monitor
            hl.dispatch(hl.dsp.window.move({
                x = saved.x + (m and m.x or 0), y = saved.y + (m and m.y or 0), window = sel(address),
            }))
        end
        hl.dispatch(hl.dsp.focus({ window = sel(address) }))
    end)
end

function oblio.restore_last()
    local address = s.order[#s.order]
    if address then oblio.restore(address) end
end

function oblio.restore_all()
    for i = #s.order, 1, -1 do oblio.restore(s.order[i]) end
end

-- focuses a window without moving the pointer; a minimized one is restored first
function oblio.focus(address)
    local w = win(address)
    if not w then return end
    if is_minimized(w) then return oblio.restore(w) end
    quietly(function() hl.dispatch(hl.dsp.focus({ window = sel(address) })) end)
end

-- the most recently focused of some windows
local function latest(list)
    table.sort(list, function(a, b) return a.focus_history_id < b.focus_history_id end)
    return list[1]
end

-- the dock's click on an app: if one of its windows on screen has focus, minimizes them
-- all; if they're on screen but not focused, focuses the last used one; if they're all
-- minimized, brings them back; if it only has windows on other workspaces, goes there
function oblio.toggle_app(addresses)
    local shown, minimized, elsewhere = {}, {}, {}
    for _, address in ipairs(addresses) do
        local w = win(address)
        if w then
            if is_minimized(w) then table.insert(minimized, w)
            elseif w.workspace and w.workspace.visible then table.insert(shown, w)
            else table.insert(elsewhere, w) end
        end
    end
    if #shown > 0 then
        local focused = false
        for _, w in ipairs(shown) do focused = focused or w.active end
        if focused then
            for _, w in ipairs(shown) do oblio.minimize(w) end
        else
            oblio.focus(latest(shown).address)
        end
    elseif #minimized > 0 then
        for _, w in ipairs(minimized) do oblio.restore(w) end
    elseif #elsewhere > 0 then
        oblio.focus(latest(elsewhere).address)
    end
end

function oblio.close(addresses)
    for _, address in ipairs(addresses) do
        hl.dispatch(hl.dsp.window.close({ window = sel(address) }))
    end
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
