hl.on("hyprland.start", function()
  hl.exec_cmd("uwsm-app -- hypridle")
  hl.exec_cmd("uwsm-app -- swaybg -i ~/.config/hypr/wallpaper.png -m fill")
  hl.exec_cmd("uwsm-app -- mako")
  hl.exec_cmd("pkill waybar; uwsm-app -- waybar")
  -- wob OSD: fifo + tail, so volume/brightness scripts just write a value.
  hl.exec_cmd("uwsm-app -- sh -c '[ -p /tmp/wobpipe ] || mkfifo /tmp/wobpipe; tail -f /tmp/wobpipe | wob &'")
  hl.exec_cmd(Browser)
end)
