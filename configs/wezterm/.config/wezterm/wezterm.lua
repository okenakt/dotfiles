local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- Default Program
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.default_prog = { "powershell.exe" }
end

-- Font
config.font = wezterm.font("Pennywort", { weight = "Regular", stretch = "Normal", style = "Normal" })
config.font_size = 12

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
config.disable_default_key_bindings = true
config.keys = {
	-- Clipboard
	{
		key = "c",
		mods = "CTRL|SHIFT",
		action = act.CopyTo("Clipboard"),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT",
		action = act.PasteFrom("Clipboard"),
	},

	-- Scrollback
	{
		key = "f",
		mods = "CTRL|SHIFT",
		action = act.Search("CurrentSelectionOrEmptyString"),
	},

	-- Font Size
	{
		key = "=",
		mods = "CTRL",
		action = act.IncreaseFontSize,
	},
	{
		key = "+",
		mods = "CTRL|SHIFT",
		action = act.IncreaseFontSize,
	},
	{
		key = "-",
		mods = "CTRL",
		action = act.DecreaseFontSize,
	},
	{
		key = "0",
		mods = "CTRL",
		action = act.ResetFontSize,
	},

	-- Window
	{
		key = "F11",
		mods = "NONE",
		action = act.ToggleFullScreen,
	},
	{
		key = "n",
		mods = "CTRL|SHIFT",
		action = act.SpawnWindow,
	},

	-- WezTerm Management
	{
		key = "p",
		mods = "CTRL|SHIFT",
		action = act.ActivateCommandPalette,
	},
	{
		key = "d",
		mods = "CTRL|SHIFT",
		action = act.ShowDebugOverlay,
	},
}

return config
