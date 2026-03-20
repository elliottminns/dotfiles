return {
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.templ" }, callback = vim.lsp.buf.format })
			vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.rs" }, callback = vim.lsp.buf.format })

			local on_attach = function(_client, bufnr)
				local opts = { buffer = bufnr, silent = true }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
			end

			vim.lsp.config("lua_ls", {
				on_attach = on_attach,
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
							disable = { "different-requires" },
						},
					},
				},
			})
			vim.lsp.enable("lua_ls")

			vim.lsp.config("rust_analyzer", {
				on_attach = on_attach,
				capabilities = capabilities,
				settings = {
					["rust-analyzer"] = {
						cargo = {
							features = "all",
						},
						procMacro = {
							ignored = {
								leptos_macro = {
									"component",
									"server",
								},
							},
						},
						check = {
							command = "clippy",
						},
						inlayHints = {
							enable = true,
						},
						assist = {
							importGranularity = "module",
						},
					},
				},
			})
			vim.lsp.enable("rust_analyzer")

			vim.lsp.config("gopls", {
				on_attach = on_attach,
				capabilities = capabilities,
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				settings = {
					env = {
						GOEXPERIMENT = "rangefunc",
					},
					formatting = {
						gofumpt = true,
					},
				},
			})
			vim.lsp.enable("gopls")

			-- vim.lsp.config("tailwindcss", {
			-- 	on_attach = on_attach,
			-- 	capabilities = capabilities,
			-- 	filetypes = { "templ", "astro", "javascript", "typescript", "react" },
			-- 	settings = {
			-- 		tailwindCSS = {
			-- 			includeLanguages = {
			-- 				templ = "html",
			-- 			},
			-- 		},
			-- 	},
			-- })
			-- vim.lsp.enable("tailwindcss")

			vim.lsp.config("templ", {
				on_attach = on_attach,
				capabilities = capabilities,
			})
			vim.lsp.enable("templ")

			vim.lsp.config("nil_ls", {
				on_attach = on_attach,
				capabilities = capabilities,
			})
			vim.lsp.enable("nil_ls")

			vim.lsp.config("ts_ls", {
				on_attach = on_attach,
				capabilities = capabilities,
			})
			vim.lsp.enable("ts_ls")

			vim.lsp.config("html", {
				on_attach = on_attach,
				capabilities = capabilities,
				filetypes = { "html", "templ" },
			})
			vim.lsp.enable("html")

			vim.lsp.config("htmx", {
				on_attach = on_attach,
				capabilities = capabilities,
				filetypes = { "html", "templ" },
			})
			vim.lsp.enable("htmx")
		end,
	},
}
