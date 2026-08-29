hl.config({
  general = {
    gaps_in     = 1,
    gaps_out    = 3,
    border_size = 1,
    layout      = "dwindle",
  },

  decoration = { rounding = 0, },
  animations = { enabled = false, },

  ecosystem = {
    no_donation_nag = true,
    no_update_news = true,
  },

  xwayland = { force_zero_scaling = true }
})

hl.window_rule({
  match     = { class = "scratchpad-term" },
  workspace = "special:magic",
  float     = true,
  center    = true,
  size      = { 900, 500 },
})

hl.window_rule({
  match = { class = "localsend|org.gnome.Calculator" },
  float = true,
  center = true,
  size = { 400, 600 },
})

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
  name        = "no-gaps-wtv1",
  match       = { float = false, workspace = "w[tv1]" },
  border_size = 0,
  rounding    = 0,
})
hl.window_rule({
  name        = "no-gaps-f1",
  match       = { float = false, workspace = "f[1]" },
  border_size = 0,
  rounding    = 0,
})

-- fouces browser when opening opening tab
hl.on("window.title", function(w)
  if w ~= hl.get_active_window() and w.class == "zen" then
    hl.dispatch(hl.dsp.focus({ window = w }))
  end
end)
