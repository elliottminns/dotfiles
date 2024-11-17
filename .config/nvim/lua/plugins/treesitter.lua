return {
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufReadPost", "BufNewFile" },
		cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
		build = ":TSUpdate",
		dependencies = {
			"apple/pkl-neovim",
			"windwp/nvim-ts-autotag",
			"EmranMR/tree-sitter-blade",
			"vrischmann/tree-sitter-templ",
		},
		opts = function()
			return require("plugins.configs.treesitter")
		end,
		config = function(_, opts)
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

			parser_config.blade = {
				install_info = {
					url = "https://github.com/EmranMR/tree-sitter-blade",
					files = { "src/parser.c" },
					branch = "main",
				},
				filetype = "blade",
			}
			parser_config.templ = {
				install_info = {
					url = "https://github.com/vrischmann/tree-sitter-templ",
					files = { "src/parser.c" },
					branch = "master",
				},
				filetype = "templ",
			}

			require("nvim-treesitter.configs").setup(opts)

			vim.filetype.add({
				pattern = {
					[".*%.blade%.php"] = "blade",
				},
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
