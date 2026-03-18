return {
	{
		"saecki/crates.nvim",
		ft = { "rust", "toml" },
		config = function()
			local crates = require("crates")
			crates.setup({
				completion = {
					cmp = {
						enabled = true,
					},
				},
				lsp = {
					enabled = true,
					actions = true,
					completion = true,
					hover = true,
				},
			})
			crates.show()
		end,
	},
}
