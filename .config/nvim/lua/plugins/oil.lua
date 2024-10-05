return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {},
	-- Optional dependencies
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	config = function()
		vim.keymap.set("n", "<space>o", require("oil").toggle_float)
		require("oil").setup()
	end,
}
