-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local termlunch = "uwsm-app -- " .. Terminal .. " "

-- main binds
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(Terminal))
hl.bind(mainMod .. " + X", hl.dsp.window.close())
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(Menu))
hl.bind(mainMod .. " + ALT + Space", hl.dsp.exec_cmd("menus"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(Browser))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(FileManager))

-- tuis
local function launch_tui(app)
  return function()
    hl.dispatch(hl.dsp.exec_cmd(termlunch .. app, {
      float = true,
      center = true,
      size = { 800, 600 }
    }))
  end
end

hl.bind(mainMod .. " + CTRL + W", launch_tui("impala"))
hl.bind(mainMod .. " + CTRL + B", launch_tui("bluetui"))
hl.bind(mainMod .. " + CTRL + A", launch_tui("wiremix"))
hl.bind(mainMod .. " + CTRL + I", launch_tui("installer"))

hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

-- Move focus with mainMod + arrow keys
-- Move with mainMod + SHIFT
local directions = { h = "left", j = "down", k = "up", l = "right", }
for key, direction in pairs(directions) do
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = direction }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

-- toggle float
hl.bind(mainMod .. " + V", function()
  hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  hl.dispatch(hl.dsp.window.resize({ x = 600, y = 500 }))
end)

-- scratchpad
hl.bind(mainMod .. " + S", function()
  if hl.get_window("class:^(scratchpad-term)$") == nil then
    hl.exec_cmd(termlunch .. "--class scratchpad-term", { workspace = "special:magic" })
  else
    hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
  end
end)

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness (wob OSD via bin scripts)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("volume up"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("volume down"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("volume mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightness up"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightness down"), { repeating = true })
hl.bind("XF86Display",
  hl.dsp.exec_cmd(
    'sh -c \'[[ $(brightnessctl get -d "tpacpi::kbd_backlight") -eq 2 ]] && brightnessctl set -d "tpacpi::kbd_backlight" 0 || brightnessctl set -d "tpacpi::kbd_backlight" +1\''))
