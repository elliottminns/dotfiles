return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = "ConformInfo",
	opts = {
		formatters = {
			topcoat = {
				command = "topcoat",
				args = { "fmt", "--stdin" },
				require_cwd = true,
				cwd = function(self, ctx)
					return require("conform.util").root_file({ "Topcoat.toml" })(self, ctx)
				end,
			},
		},
		formatters_by_ft = {
			rust = { "topcoat", lsp_format = "first" },
		},
		format_on_save = {
			timeout_ms = 3000,
			lsp_format = "first",
		},
	},
}
