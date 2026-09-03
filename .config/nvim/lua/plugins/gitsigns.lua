return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = vim.tbl_deep_extend("force", require("plugins.configs.others").gitsigns, {
		linehl = false,
		on_attach = function(bufnr)
			local gitsigns = require("gitsigns")
			local function map(lhs, rhs, desc)
				vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
			end

			map("<leader>gn", function()
				gitsigns.nav_hunk("next")
			end, "Git: next change")
			map("<leader>gN", function()
				gitsigns.nav_hunk("prev")
			end, "Git: previous change")
			map("<leader>gp", gitsigns.preview_hunk, "Git: preview change")
			map("<leader>gr", gitsigns.reset_hunk, "Git: revert change")
			map("<leader>gth", gitsigns.toggle_linehl, "Git: toggle change highlight")
			map("<leader>gtl", gitsigns.toggle_signs, "Git: toggle left bar")
		end,
	}),
}
