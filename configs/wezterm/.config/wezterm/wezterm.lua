local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- Default Program
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.default_prog = { "powershell.exe" }
end

-- Font
config.font = wezterm.font("Pennywort23", { weight = "Regular", stretch = "Normal", style = "Normal" })
config.font_size = 10

-- Appearance
config.color_scheme = "Subliminal"
config.window_background_opacity = 0.8
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.initial_cols = 96
config.initial_rows = 48

-- Key Bindings
config.keys = {
	-- Pane Navigation
	{
		key = "LeftArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "RightArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "UpArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "DownArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Down"),
	},

	-- Pane Splitting
	{
		key = "LeftArrow",
		mods = "CTRL|ALT",
		action = act.SplitPane({ direction = "Left" }),
	},
	{
		key = "RightArrow",
		mods = "CTRL|ALT",
		action = act.SplitPane({ direction = "Right" }),
	},
	{
		key = "UpArrow",
		mods = "CTRL|ALT",
		action = act.SplitPane({ direction = "Up" }),
	},
	{
		key = "DownArrow",
		mods = "CTRL|ALT",
		action = act.SplitPane({ direction = "Down" }),
	},

	-- Pane Resizing
	{
		key = "=",
		mods = "ALT",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	{
		key = "+",
		mods = "ALT|SHIFT",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{
		key = "-",
		mods = "ALT",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "_",
		mods = "ALT|SHIFT",
		action = act.AdjustPaneSize({ "Up", 5 }),
	},
	{
		key = "f",
		mods = "ALT",
		action = act.TogglePaneZoomState,
	},

	-- Tab Management
	{
		key = "t",
		mods = "CTRL",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "PageUp",
		mods = "ALT",
		action = act.ActivateTabRelative(-1),
	},
	{
		key = "PageDown",
		mods = "ALT",
		action = act.ActivateTabRelative(1),
	},

	-- Closing
	{
		key = "q",
		mods = "ALT",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "q",
		mods = "CTRL|ALT",
		action = act.CloseCurrentTab({ confirm = true }),
	},

	-- Misc
	{
		key = "Enter",
		mods = "ALT",
		action = act.ActivateCommandPalette,
	},
	{
		key = "d",
		mods = "ALT",
		action = act.ShowDebugOverlay,
	},
}

return config
