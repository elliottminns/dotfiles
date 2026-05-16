return {
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			vim.api.nvim_create_user_command("LspStop", function(args)
				local name = args.fargs[1]
				local clients = vim.lsp.get_clients({ name = name })
				for _, client in ipairs(clients) do
					client:stop()
				end
			end, {
				nargs = "?",
				complete = function()
					return vim.tbl_map(function(c)
						return c.name
					end, vim.lsp.get_clients())
				end,
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			vim.diagnostic.config({
				severity_sort = true,
				virtual_text = {
					source = "if_many",
				},
				float = {
					border = "rounded",
					focusable = false,
					source = "if_many",
				},
			})

			local diagnostic_group = vim.api.nvim_create_augroup("DiagnosticFloat", { clear = true })
			vim.api.nvim_create_autocmd("CursorHold", {
				group = diagnostic_group,
				callback = function()
					vim.diagnostic.open_float(nil, {
						focus = false,
						scope = "cursor",
					})
				end,
			})

			vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.templ" }, callback = vim.lsp.buf.format })
			vim.api.nvim_create_autocmd({ "BufWritePre" }, {
				pattern = { "*.rs" },
				callback = function(args)
					vim.lsp.buf.format({
						bufnr = args.buf,
						timeout_ms = 3000,
						filter = function(client)
							return client.name == "rust-analyzer" or client.name == "rust_analyzer"
						end,
					})
				end,
			})

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

			if vim.fn.executable("taplo") == 1 then
				vim.lsp.config("taplo", {
					on_attach = on_attach,
					capabilities = capabilities,
				})
				vim.lsp.enable("taplo")
			end

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
