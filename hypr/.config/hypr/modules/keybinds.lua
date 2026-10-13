---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "nautilus"
local menu        = "hyprlauncher"

---------------------
---- KEYBINDINGS ----
---------------------

hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + W", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind("SUPER + SHIFT + RETURN", hl.dsp.exec_cmd("zen-browser"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen("maximized", "toggle"))

-- Move focus with SUPER + arrow keys
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with SUPER + [0-9]
-- Move active window to a workspace with SUPER + SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })




---------------
---- SHELL ----
---------------

-- Helpers

local function ipc(call)
  return hl.dsp.exec_cmd("qs ipc call " .. call)
end

local held = { locked = true, repeating = true } -- volume, brightness
local tap  = { locked = true }                   -- mute, media

-- Shell Keybinds
hl.bind("SUPER + Escape", ipc("session toggle"),
  { description = "Session menu (shutdown, reboot, ...)" })

hl.bind("SUPER + L", ipc("lock lock"),
  { description = "Lock the screen" })

hl.bind("SUPER + N", ipc("notifications toggleDoNotDisturb"),
  { description = "Toggle Do Not Disturb" })

hl.bind("SUPER + SHIFT + N", ipc("notifications dismissAll"),
  { description = "Dismiss all notifications" })

hl.bind("SUPER + Space", ipc("launcher toggle"),
  { description = "App launcher" })

hl.bind("SUPER + CTRL + Space", ipc("wallpaper toggle"),
  { description = "Wallpaper & theme" })

-- Volume
hl.bind("XF86AudioRaiseVolume", ipc("audio increase"), held)
hl.bind("XF86AudioLowerVolume", ipc("audio decrease"), held)
hl.bind("XF86AudioMute", ipc("audio toggleMute"), tap)

-- Media
hl.bind("XF86AudioPlay", ipc("media togglePlaying"), tap)
hl.bind("XF86AudioPause", ipc("media togglePlaying"), tap)
hl.bind("XF86AudioNext", ipc("media next"), tap)
hl.bind("XF86AudioPrev", ipc("media previous"), tap)

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), held)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), held)
