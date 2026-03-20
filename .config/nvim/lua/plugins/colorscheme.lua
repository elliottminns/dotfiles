return {
	{
		"folke/tokyonight.nvim",
		name = "tokyonight",
		priority = 1000,
		config = function(_, opts)
			local function set_markdown_strikethrough()
				for _, group in ipairs({
					"@markup.strikethrough",
					"@markup.strikethrough.markdown",
					"markdownStrike",
					"htmlStrike",
				}) do
					vim.api.nvim_set_hl(0, group, { strikethrough = true })
				end
			end

			require("tokyonight").setup({
				transparent = true,
			})

			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = set_markdown_strikethrough,
			})

			vim.cmd([[colorscheme tokyonight-night]])
			set_markdown_strikethrough()
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		priority = 1000,
	},
}
