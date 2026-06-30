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
-- Pane/tab management is split across three non-overlapping namespaces so that
-- keys destined for tmux (local or over ssh) are never intercepted by wezterm:
--   - Alt + ...            -> passed through to the foreground tmux
--   - `        (backtick)  -> tmux prefix (passed through)
--   - Shift + Space (leader) -> wezterm-local panes/tabs (captured here)
-- Shift+Space is an ergonomics exception to the normal Shift-as-variant rule.
config.disable_default_key_bindings = true
config.leader = { key = "Space", mods = "SHIFT", timeout_milliseconds = 1000 }
config.keys = {
	-- Clipboard
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

	-- Scrollback
	{ key = "f", mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },

	-- Font size
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },

	-- Window
	{ key = "F11", mods = "NONE", action = act.ToggleFullScreen },
	{ key = "n", mods = "CTRL|SHIFT", action = act.SpawnWindow },

	-- WezTerm management
	{ key = "Enter", mods = "ALT", action = act.ActivateCommandPalette },
	{ key = "d", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },

	-- Leader: pane navigation (mirrors tmux Alt+arrow)
	{ key = "LeftArrow", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "LEADER", action = act.ActivatePaneDirection("Down") },

	-- Leader: pane split toward the arrow (mirrors tmux Ctrl+Alt+arrow)
	{ key = "LeftArrow", mods = "LEADER|ALT", action = act.SplitPane({ direction = "Left", size = { Percent = 50 } }) },
	{
		key = "RightArrow",
		mods = "LEADER|ALT",
		action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }),
	},
	{ key = "UpArrow", mods = "LEADER|ALT", action = act.SplitPane({ direction = "Up", size = { Percent = 50 } }) },
	{ key = "DownArrow", mods = "LEADER|ALT", action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },

	-- Leader: pane zoom / close
	{ key = "f", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "q", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

	-- Leader: tab management
	{ key = "t", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "PageUp", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "PageDown", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "w", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
}

-- Leader: jump to tab by number (1-9)
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

return config
