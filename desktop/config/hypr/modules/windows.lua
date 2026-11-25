-- Oblio window management: minimize / restore (any number of windows), show
-- desktop, per-workspace tiling <-> floating mode. Keys are in binds.lua.
-- Minimized windows live on the hidden workspace "special:minimized" and come back
-- where they were: same workspace, and for floating windows the same place and size.
-- Nothing here moves the pointer. The dock calls these through
--   hyprctl dispatch 'function() oblio.toggle_app({ "0x..." }) end'
--
-- Minimize and restore are animated by the shell (dock/Genie.qml), which flies a live picture of
-- the window into or out of its dock icon. This file owns everything else: which window, its state,
-- focus, the layout, and every timing. The shell only draws and reports back. Each window being
-- animated is in one phase (s.fx). Each phase ends when the shell reports, or at its deadline;
-- finish() ends any phase at once, the same way. A new minimize or restore finishes every running
-- one first: two flights at once fly to places the other is changing.
--
--   minimize  shown --(shell: leave)--> covering   the picture lies exactly over the window
--             covering --ready--> leaving          the window turns invisible in its place (the
--                                                  layout doesn't move); focus goes back; shell: go
--             leaving --done--> minimized          the window goes; only now the gap closes
--   restore   minimized --(shell: arrive)--> placing  the window comes back invisible and, if the
--                                                  layout moves, Hyprland makes room meanwhile;
--                                                  the picture waits unseen in the icon
--             placing --ready + settled--> arriving  the window takes focus; shell: go
--             arriving --done--> showing           the window shows under the picture
--             showing --HOLD--> shown              shell: drop (the picture goes)

oblio = oblio or {}

local MINIMIZED = "special:minimized"

-- a config reload starts a fresh Lua state: the state is kept in a file too (the runtime dir is
-- emptied at logout) and read back here
local STATE = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/oblio-windows.lua"
local function load()
    local ok, t = pcall(dofile, STATE)
    return ok and type(t) == "table" and t or nil
end
local function dump(v)
    if type(v) ~= "table" then return type(v) == "string" and string.format("%q", v) or tostring(v) end
    local out = {}
    for k, x in pairs(v) do out[#out + 1] = "[" .. dump(k) .. "]=" .. dump(x) end
    return "{" .. table.concat(out, ",") .. "}"
end

local s = oblio.state or load() or {}
s.floating = s.floating or {}  -- workspace id -> true when the workspace is in floating mode
s.floated = s.floated or {}    -- address -> true for windows floated by floating mode
s.saved = s.saved or {}        -- address -> where it was when minimized: workspace, floating, place, size
s.order = s.order or {}        -- minimized addresses, oldest first
-- s.desktop: addresses hidden by show_desktop, to bring back together
s.fx = s.fx or {}              -- address -> its phase (see the top), while animated
s.fx_n = s.fx_n or {}          -- address -> the number of its phase (an older deadline leaves it alone)
s.waits = s.waits or {}        -- address -> what a placing window still waits for: { picture, layout }
oblio.state = s

local function save()
    local f = io.open(STATE, "w")
    if f then f:write("return ", dump(s)); f:close() end
end

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

local function focus_quietly(address)
    quietly(function() hl.dispatch(hl.dsp.focus({ window = sel(address) })) end)
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

local function tag(address, t) hl.dispatch(hl.dsp.window.tag({ tag = t, window = sel(address) })) end

-- timings (ms), all of them:
--   FLIGHT  a picture's flight
--   SETTLE  how long a flight in waits for the layout to make room (measured: tiled neighbours have
--           moved ~85 % by 160 ms, and the picture only reaches full size halfway through its flight)
--   HOLD    a window back from special:minimized fades in (~150 ms, whatever its rules say;
--           measured): the picture stays over it this long
-- and how long each phase may wait for the shell before it finishes here
local FLIGHT, SETTLE, HOLD = 200, 160, 250
local DEADLINE = { covering = 300, leaving = FLIGHT + 500, placing = SETTLE + 300, arriving = FLIGHT + 500, showing = HOLD }

-- invisible in its place (the "oblio-hidden" rule in windowrules.lua), or visible again. Showing
-- holds "oblio-still" (no animations) for HOLD: without it Hyprland fades the window in, and the
-- picture over it is gone by then (measured: a see-through flash)
local function conceal(address, on)
    if on then return tag(address, "+oblio-hidden") end
    tag(address, "+oblio-still")
    tag(address, "-oblio-hidden")
    hl.timer(function() if win(address) then tag(address, "-oblio-still") end end, { timeout = HOLD, type = "oneshot" })
end

-- messages to the shell are lines appended to a file it watches: a write, not a process to start
-- (qs ipc took ~50 ms a message, and nothing may move while one is on its way). Each line has a
-- number, so the shell takes every message once; the file starts over once it gets long.
local CHANNEL = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/oblio-fx"
do local f = io.open(CHANNEL, "a"); if f then f:close() end end
local function shell(...)
    s.seq = (s.seq or 0) + 1
    local f = io.open(CHANNEL, "a")
    if f and f:seek("end") > 32768 then f:close(); f = io.open(CHANNEL, "w") end
    if not f then return end
    f:write(s.seq, " ", table.concat({ ... }, " "), "\n")
    f:close()
end

local finish

-- enters a phase; when its deadline passes and it's still in it, it finishes here. A phase entered
-- again later gets a new number, so an old deadline doesn't end it.
local function phase(address, name)
    s.phase_n = (s.phase_n or 0) + 1
    local n = s.phase_n
    s.fx[address] = name
    s.fx_n[address] = n
    hl.timer(function()
        if s.fx[address] == name and s.fx_n[address] == n then finish(address); save() end
    end, { timeout = DEADLINE[name], type = "oneshot" })
end

local function rect(w)
    return string.format("%d %d %d %d", w.at.x, w.at.y, w.size.x, w.size.y)
end

-- the most recently used of some windows
local function latest(list)
    table.sort(list, function(a, b) return a.focus_history_id < b.focus_history_id end)
    return list[1]
end

-- after a window goes away: the most recently used window that's still on screen gets focus
local function focus_previous(except)
    local candidates = {}
    for _, w in ipairs(hl.get_windows()) do
        if w.address ~= except and w.mapped and not w.hidden and not is_minimized(w) and not s.fx[w.address]
            and w.workspace and w.workspace.visible and not w.workspace.special then
            table.insert(candidates, w)
        end
    end
    local w = latest(candidates)
    if w then focus_quietly(w.address) end
end

---------------------------------------------------------------------------
-- minimize / restore
---------------------------------------------------------------------------

-- ends a window's phase at once, where its animation would have ended: minimized, or shown with focus
finish = function(address)
    local kind = s.fx[address]
    if not kind then return end
    s.fx[address], s.fx_n[address], s.waits[address] = nil, nil, nil
    shell("drop", address)
    local w = win(address)
    if not w then return end
    if kind == "covering" then
        conceal(address, true)
        if w.active then focus_previous(address) end
    end
    if kind == "covering" or kind == "leaving" then
        hl.dispatch(hl.dsp.window.move({ workspace = MINIMIZED, follow = false, window = sel(address) }))
    elseif kind == "placing" or kind == "arriving" then
        conceal(address, false)
        if kind == "placing" then focus_quietly(address) end
    end
end

-- before a new minimize or restore. Show desktop's windows go together: it finishes the running
-- ones once, then lets its own run side by side.
local together = false
local function finish_running()
    if together then return end
    local running = {}
    for address in pairs(s.fx) do table.insert(running, address) end
    for _, address in ipairs(running) do finish(address) end
end

function oblio.minimize(w)
    finish_running()
    if w and type(w) ~= "string" then w = w.address end
    w = w and win(w) or not w and hl.get_active_window() or nil
    if not w or not w.workspace or w.workspace.special or s.fx[w.address] then return end
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
    phase(w.address, "covering")
    shell("leave", w.address, rect(w), tostring(w.active))
end

-- a placing window flies in once its picture is up and the layout has made room
local function arrive(address)
    local waits = s.waits[address]
    if s.fx[address] ~= "placing" or not waits or waits.picture or waits.layout then return end
    s.waits[address] = nil
    phase(address, "arriving")
    -- focused as its picture sets off: its border has the focused color when it shows
    focus_quietly(address)
    shell("go", address, FLIGHT)
end

-- a report from the shell about a flight that has since been finished (drop) and replaced by one
-- the other way: "out" belongs to a minimize, "in" to a restore
local function stale(address, way)
    local kind = s.fx[address]
    if way == "out" then return kind ~= "covering" and kind ~= "leaving" end
    if way == "in" then return kind ~= "placing" and kind ~= "arriving" and kind ~= "showing" end
    return false
end

-- the shell's picture is up. Leaving: it lies over the window, which turns invisible in its place
-- (nothing in the layout moves), focus goes back to the window used before it and the picture
-- flies. Placing: it waits in the icon until the layout has made room.
function oblio.ready(address, way)
    if stale(address, way) then return end
    local kind = s.fx[address]
    if kind == "placing" then
        if s.waits[address] then s.waits[address].picture = false end
        return arrive(address)
    end
    if kind ~= "covering" then return end
    local w = win(address)
    if not w then s.fx[address] = nil; return end
    conceal(address, true)
    if w.active then focus_previous(address) end
    phase(address, "leaving")
    shell("go", address, FLIGHT)
end

-- the end of a flight: a minimized window goes (the gap closes now; it stays concealed until it
-- has arrived again); a restored one shows under the picture, which stays for HOLD
function oblio.done(address, way)
    if stale(address, way) then return end
    local kind = s.fx[address]
    if kind == "leaving" then return finish(address) end
    if kind ~= "arriving" then return end
    conceal(address, false)
    phase(address, "showing")
end

-- restoring: the window comes back invisible to where it was (its workspace shown, the same place
-- and size if it floated). The shell readies its picture meanwhile. Only when something else moves
-- (tiled neighbours making room, another workspace coming into view) the flight waits for it.
function oblio.restore(w)
    finish_running()
    if w and type(w) ~= "string" then w = w.address end
    w = w and win(w)
    if not is_minimized(w) or s.fx[w.address] then return end
    local address = w.address
    local saved = s.saved[address]
    local here = hl.get_active_workspace()
    local target = (saved and saved.workspace) or (here and here.id) or 1
    local ws = hl.get_workspace(target)
    local moves = not (ws and ws.visible)
    if not moves and not (saved and saved.floating) then
        for _, o in ipairs(hl.get_workspace_windows(target)) do
            if not o.floating and o.mapped and not o.hidden then moves = true; break end
        end
    end
    forget(address)
    conceal(address, true)
    phase(address, "placing")
    s.waits[address] = { picture = true, layout = moves }
    quietly(function()
        if not (ws and ws.visible) then hl.dispatch(hl.dsp.focus({ workspace = target })) end
        hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false, window = sel(address) }))
        if saved and saved.floating then
            hl.dispatch(hl.dsp.window.float({ action = "enable", window = sel(address) }))
            hl.dispatch(hl.dsp.window.resize({ x = saved.width, y = saved.height, window = sel(address) }))
            local m = (win(address) or {}).monitor
            hl.dispatch(hl.dsp.window.move({
                x = saved.x + (m and m.x or 0), y = saved.y + (m and m.y or 0), window = sel(address),
            }))
        end
    end)
    local p = win(address)
    if p then shell("arrive", address, rect(p)) end
    if moves then
        hl.timer(function()
            if s.waits[address] then s.waits[address].layout = false; arrive(address); save() end
        end, { timeout = SETTLE, type = "oneshot" })
    end
end

function oblio.restore_last()
    local address = s.order[#s.order]
    if address then oblio.restore(address) end
end

-- focuses a window without moving the pointer; a minimized one is restored first
function oblio.focus(address)
    finish_running()
    local w = win(address)
    if not w then return end
    if is_minimized(w) then return oblio.restore(w) end
    focus_quietly(address)
end

-- the dock's left click on a running app (one that isn't running is started by the shell), with
-- its windows in the dock's order (its previews, left to right):
--   app not focused: the most recently used window on screen gets focus, else one on another
--   workspace (switching there), else the most recently used minimized one comes back
--   app focused, one window: it's minimized (clicks go minimize, restore, minimize...)
--   app focused, more windows: the next one in order, round and round: shown -> focus,
--   minimized -> restored
function oblio.toggle_app(addresses)
    finish_running()
    local all, shown, minimized, elsewhere, current = {}, {}, {}, {}, nil
    for _, address in ipairs(addresses) do
        local w = win(address)
        if w then
            table.insert(all, w)
            if w.active and not is_minimized(w) then current = #all end
            if is_minimized(w) then table.insert(minimized, w)
            elseif w.workspace and w.workspace.visible then table.insert(shown, w)
            else table.insert(elsewhere, w) end
        end
    end
    if current then
        if #all == 1 then return oblio.minimize(all[1]) end
        return oblio.focus(all[current % #all + 1].address)
    elseif #shown > 0 then
        oblio.focus(latest(shown).address)
    elseif #elsewhere > 0 then
        oblio.focus(latest(elsewhere).address)
    elseif #minimized > 0 then
        oblio.restore(latest(minimized))
    end
end

function oblio.close(addresses)
    for _, address in ipairs(addresses) do
        hl.dispatch(hl.dsp.window.close({ window = sel(address) }))
    end
end

-- minimize every window on this workspace; run again to bring them all back
function oblio.toggle_desktop()
    finish_running()
    together = true
    if s.desktop then
        local batch = s.desktop
        s.desktop = nil
        for _, address in ipairs(batch) do oblio.restore(address) end
    else
        local ws = hl.get_active_workspace()
        local batch = {}
        for _, w in ipairs(ws and hl.get_workspace_windows(ws.id) or {}) do
            if w.mapped then
                oblio.minimize(w)
                table.insert(batch, w.address)
            end
        end
        if #batch > 0 then s.desktop = batch end
    end
    together = false
end

-- the app's own minimize button, or a dock/taskbar asking (wlr foreign-toplevel)
hl.on("window.minimize", function(w, minimized)
    if minimized then oblio.minimize(w) else oblio.restore(w) end
end)

-- a closed window is no longer minimized, nor animated
hl.on("window.close", function(w)
    if not w then return end
    forget(w.address)
    if s.fx[w.address] then shell("drop", w.address) end
    s.fx[w.address], s.fx_n[w.address], s.waits[w.address] = nil, nil, nil
    s.floated[w.address] = nil
    save()
end)

-- a floating window that gets focus comes to the front, however it got it (a click
-- already does that; the dock, keys and Alt+Tab don't). Tiled windows can't: Hyprland
-- always draws floating windows above tiled ones.
hl.on("window.active", function(w)
    if w and w.floating then
        hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = sel(w.address) }))
    end
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
    if w and w.workspace and s.floating[w.workspace.id] then float_window(w); save() end
end)

-- moving a window into or out of a floating workspace follows that workspace's mode
hl.on("window.move_to_workspace", function(w, ws)
    if not w or not ws or ws.special then return end
    -- a concealed window that reaches a normal workspace any other way shows again
    if not s.fx[w.address] then
        local tags = type(w.tags) == "table" and table.concat(w.tags, " ") or tostring(w.tags or "")
        if tags:find("oblio-hidden", 1, true) then conceal(w.address, false) end
    end
    if s.floating[ws.id] then float_window(w) else tile_window(w) end
    save()
end)

-- a reload drops the timers: anything still animated finishes now
finish_running()
-- and nothing on screen stays concealed
for _, w in ipairs(hl.get_windows({ tag = "oblio-hidden" })) do
    if not is_minimized(w) then conceal(w.address, false) end
end

-- every oblio.* action saves the state when it's done
for name, fn in pairs(oblio) do
    if type(fn) == "function" then
        oblio[name] = function(...)
            local r = table.pack(fn(...))
            save()
            return table.unpack(r, 1, r.n)
        end
    end
end

return oblio
