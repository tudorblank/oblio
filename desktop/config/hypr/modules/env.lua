-- Environment variables: https://wiki.hypr.land/configuring/core/environment-variables/
-- Also works out what kind of machine this is, for the other modules.

oblio = oblio or {}

-- Oblio's shell (bar, dock, settings, notifications), copied here by desktop/setup; oblio.qs is
-- the one command that starts it (autostart, desktop/setup)
oblio.shell = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/oblio-shell"
oblio.qs = "qs -p '" .. oblio.shell .. "'"

local function output(cmd)
    local p = io.popen(cmd)
    if not p then return "" end
    local out = p:read("*a") or ""
    p:close()
    return (out:gsub("%s+$", ""))
end

local function exists(path)
    local f = io.open(path)
    if f then f:close() end
    return f ~= nil
end

local virt = output("systemd-detect-virt --vm")
oblio.vm = virt ~= "" and virt ~= "none"
oblio.nvidia = exists("/proc/driver/nvidia/version")
-- NVIDIA is the only GPU (no AMD/Intel one next to it, as on PRIME laptops)
oblio.nvidia_only = oblio.nvidia and output("cat /sys/class/drm/card*/device/vendor 2>/dev/null | sort -u") == "0x10de"
-- more than one GPU (a PRIME laptop): the second one sleeps until something asks for it
oblio.hybrid = tonumber(output("ls -d /sys/class/drm/card[0-9]* 2>/dev/null | grep -c 'card[0-9]*$'")) > 1

-- Qt apps take colors, light/dark, accent, fonts and file dialogs from the GTK theme
-- (Settings > Appearance), and follow it live
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-- GTK 4 draws with Vulkan by default, and starting Vulkan wakes every GPU: on a hybrid laptop each
-- GTK 4 app (Files) waited ~1.4 s for the sleeping NVIDIA GPU (2.2 s to open, measured). OpenGL draws
-- on the GPU that drives the screen and lets the other one sleep (0.7 s)
if oblio.hybrid then hl.env("GSK_RENDERER", "ngl") end

hl.env("XCURSOR_THEME", "capitaine-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- only when NVIDIA drives everything: on a PRIME laptop these would send every video and
-- X11 app to the NVIDIA GPU and keep it awake; there `prime-run APP` uses it for one app
if oblio.nvidia_only then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")         -- video decoding
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia") -- OpenGL
    hl.env("NVD_BACKEND", "direct")
end
