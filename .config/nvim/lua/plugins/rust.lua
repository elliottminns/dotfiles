return {
	{
		"saecki/crates.nvim",
		ft = { "rust", "toml" },
		config = function()
			local crates = require("crates")
			crates.setup({
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
