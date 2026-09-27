return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		keys = {
			{
				"<leader>ta",
				function()
					local cmp = require("cmp")
					local enabled = cmp.get_config().completion.autocomplete ~= false
					cmp.setup({
						completion = {
							autocomplete = not enabled and { cmp.TriggerEvent.TextChanged } or false,
						},
					})
					if enabled then
						cmp.close()
					end
					vim.notify("Autocomplete " .. (enabled and "disabled" or "enabled"))
				end,
				desc = "Toggle autocomplete",
			},
		},
		dependencies = {
			{
				-- snippet plugin
				"L3MON4D3/LuaSnip",
				dependencies = "rafamadriz/friendly-snippets",
				opts = { history = true, updateevents = "TextChanged,TextChangedI" },
				config = function(_, opts)
					require("plugins.configs.others").luasnip(opts)
				end,
			},
			-- autopairing of (){}[] etc
			{
				"windwp/nvim-autopairs",
				opts = {
					fast_wrap = {},
					disable_filetype = { "TelescopePrompt", "vim" },
				},
				config = function(_, opts)
					require("nvim-autopairs").setup(opts)

					-- setup cmp for autopairs
					local cmp_autopairs = require("nvim-autopairs.completion.cmp")
					require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
				end,
			},
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
		},
		config = function()
			local cmp = require("cmp")
			cmp.setup(require("plugins.configs.cmp")(cmp))
		end,
	},
}
