-- Custom plugin configurations
-- Every spec file under the "plugins" directory will be loaded automatically by lazy.nvim

return {
	-- Add tokyonight.nvim colorscheme
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "night", -- Use the night variant
		},
	},

	-- Configure LazyVim to use tokyonight
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight-night",
		},
	},
}
