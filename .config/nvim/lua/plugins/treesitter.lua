return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		cmd = { "TSInstall", "TSUpdate", "TSUninstall", "TSLog" },
		build = ":TSUpdate",
		dependencies = {
			"apple/pkl-neovim",
			"windwp/nvim-ts-autotag",
			--"vrischmann/tree-sitter-templ",
		},
		opts = function()
			return require("plugins.configs.treesitter")
		end,
		config = function(_, languages)
			require("nvim-treesitter").setup()
			require("nvim-treesitter").install(languages)

			vim.api.nvim_create_autocmd("FileType", {
				pattern = languages,
				callback = function()
					pcall(vim.treesitter.start)
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		event = { "BufReadPost", "BufNewFile" },
		config = function(_, opts)
			require("nvim-ts-autotag").setup({
				opts = {
					-- Defaults
					enable_close = true,      -- Auto close tags
					enable_rename = true,     -- Auto rename pairs of tags
					enable_close_on_slash = false, -- Auto close on trailing </
				},
				-- Also override individual filetype configs, these take priority.
				-- Empty by default, useful if one of the "opts" global settings
				-- doesn't work well in a specific filetype
				aliases = {
					["template"] = "html",
				},
			})
		end,
	},
}
