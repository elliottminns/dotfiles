return {
	{
		"mrcjkb/rustaceanvim",
		version = "^9",
		lazy = false,
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		init = function()
			local function readable_float_opts()
				local available_width = math.max(vim.o.columns - 6, 20)
				local width = math.min(
					math.max(math.floor(vim.o.columns * 0.72), math.min(64, available_width)),
					96,
					available_width
				)

				return {
					border = "rounded",
					width = width,
					max_width = width,
					max_height = math.min(math.max(math.floor(vim.o.lines * 0.35), 12), 24),
					wrap = true,
				}
			end

			local function resolve_rust_analyzer()
				local path = vim.fn.exepath("rust-analyzer")
				if path ~= "" and not path:match("/rustup%-%d") then
					return path
				end

				local nix_profile_path = "/etc/profiles/per-user/" .. vim.env.USER .. "/bin/rust-analyzer"
				if vim.fn.executable(nix_profile_path) == 1 then
					return nix_profile_path
				end

				return "rust-analyzer"
			end

			local function rust_lsp(command)
				return function()
					vim.cmd.RustLsp(command)
				end
			end

			local function rust_lsp_args(command)
				return function()
					vim.cmd.RustLsp(command)
				end
			end

			vim.g.rustaceanvim = {
				tools = {
					code_actions = {
						ui_select_fallback = true,
					},
					float_win_config = readable_float_opts(),
					test_executor = "background",
				},
				server = {
					cmd = { resolve_rust_analyzer() },
					on_attach = function(_client, bufnr)
						local opts = { buffer = bufnr, silent = true }
						local map = function(lhs, rhs, desc, mode)
							vim.keymap.set(mode or "n", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
						end

						if vim.lsp.inlay_hint then
							vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
						end

						map("gd", vim.lsp.buf.definition, "Go to definition")
						map("gr", vim.lsp.buf.references, "References")
						map("K", rust_lsp_args({ "hover", "actions" }), "Rust hover actions")
						map("<leader>ca", rust_lsp("codeAction"), "Rust code action")
						map("<leader>rn", vim.lsp.buf.rename, "Rename")
						map("<leader>d", vim.diagnostic.open_float, "Line diagnostics")

						map("<leader>rr", rust_lsp("runnables"), "Rust runnables")
						map("<leader>rh", function()
							if not vim.lsp.inlay_hint then
								return
							end

							local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
							vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
						end, "Toggle Rust hints")
						map("<leader>rl", function()
							vim.cmd.RustLsp({ "runnables", bang = true })
						end, "Rust rerun last")
						map("<leader>rt", rust_lsp("testables"), "Rust testables")
						map("<leader>rd", rust_lsp("debuggables"), "Rust debuggables")
						map("<leader>re", rust_lsp("explainError"), "Rust explain error")
						map("<leader>rD", rust_lsp("renderDiagnostic"), "Rust render diagnostic")
						map("<leader>rf", function()
							vim.cmd.RustLsp({ "flyCheck", "run" })
						end, "Rust fly check")
						map("<leader>rm", rust_lsp("expandMacro"), "Rust expand macro")
						map("<leader>rM", rust_lsp("rebuildProcMacros"), "Rust rebuild proc macros")
						map("<leader>rc", rust_lsp("openCargo"), "Rust open Cargo.toml")
						map("<leader>rC", rust_lsp("crateGraph"), "Rust crate graph")
						map("<leader>rj", rust_lsp("joinLines"), "Rust join lines", { "n", "x" })
						map("<leader>rp", rust_lsp("parentModule"), "Rust parent module")
						map("<leader>ro", rust_lsp("openDocs"), "Rust docs.rs")
					end,
					default_settings = {
						["rust-analyzer"] = {
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								buildScripts = {
									enable = true,
								},
							},
							check = {
								command = "clippy",
								extraArgs = { "--all-targets" },
							},
							procMacro = {
								enable = true,
								ignored = {
									leptos_macro = {
										"component",
										"server",
									},
								},
							},
							completion = {
								fullFunctionSignatures = {
									enable = true,
								},
							},
							imports = {
								granularity = {
									group = "module",
								},
								prefix = "crate",
							},
							inlayHints = {
								bindingModeHints = {
									enable = true,
								},
								chainingHints = {
									enable = true,
								},
								closingBraceHints = {
									enable = true,
								},
								closureCaptureHints = {
									enable = true,
								},
								closureReturnTypeHints = {
									enable = "always",
								},
								discriminantHints = {
									enable = "always",
								},
								expressionAdjustmentHints = {
									enable = "always",
								},
								genericParameterHints = {
									const = {
										enable = true,
									},
									lifetime = {
										enable = true,
									},
									type = {
										enable = true,
									},
								},
								implicitDrops = {
									enable = true,
								},
								implicitSizedBoundHints = {
									enable = true,
								},
								impliedDynTraitHints = {
									enable = true,
								},
								lifetimeElisionHints = {
									enable = "always",
									useParameterNames = true,
								},
								parameterHints = {
									enable = true,
									missingArguments = {
										enable = true,
									},
								},
								rangeExclusiveHints = {
									enable = true,
								},
								reborrowHints = {
									enable = "always",
								},
								typeHints = {
									enable = true,
									hideClosureInitialization = false,
									hideClosureParameter = false,
									hideInferredTypes = false,
									hideNamedConstructor = false,
								},
							},
							lens = {
								enable = true,
							},
							workspace = {
								symbol = {
									search = {
										kind = "all_symbols",
									},
								},
							},
						},
					},
				},
			}
		end,
	},
	{
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
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

			local opts = { silent = true, buffer = true }
			vim.keymap.set("n", "<leader>ct", crates.toggle, vim.tbl_extend("force", opts, { desc = "Crates toggle" }))
			vim.keymap.set("n", "<leader>cr", crates.reload, vim.tbl_extend("force", opts, { desc = "Crates reload" }))
			vim.keymap.set(
				"n",
				"<leader>cv",
				crates.show_versions_popup,
				vim.tbl_extend("force", opts, { desc = "Crates versions" })
			)
			vim.keymap.set(
				"n",
				"<leader>cf",
				crates.show_features_popup,
				vim.tbl_extend("force", opts, { desc = "Crates features" })
			)
			vim.keymap.set(
				"n",
				"<leader>cu",
				crates.update_crate,
				vim.tbl_extend("force", opts, { desc = "Crates update crate" })
			)
			vim.keymap.set(
				"v",
				"<leader>cu",
				crates.update_crates,
				vim.tbl_extend("force", opts, { desc = "Crates update crates" })
			)
			vim.keymap.set(
				"n",
				"<leader>cua",
				crates.update_all_crates,
				vim.tbl_extend("force", opts, { desc = "Crates update all" })
			)
			vim.keymap.set(
				"n",
				"<leader>cU",
				crates.upgrade_crate,
				vim.tbl_extend("force", opts, { desc = "Crates upgrade crate" })
			)
			vim.keymap.set(
				"v",
				"<leader>cU",
				crates.upgrade_crates,
				vim.tbl_extend("force", opts, { desc = "Crates upgrade crates" })
			)
			vim.keymap.set(
				"n",
				"<leader>cUa",
				crates.upgrade_all_crates,
				vim.tbl_extend("force", opts, { desc = "Crates upgrade all" })
			)
			vim.keymap.set(
				"n",
				"<leader>cH",
				crates.open_homepage,
				vim.tbl_extend("force", opts, { desc = "Crates homepage" })
			)
			vim.keymap.set(
				"n",
				"<leader>cR",
				crates.open_repository,
				vim.tbl_extend("force", opts, { desc = "Crates repository" })
			)
			vim.keymap.set(
				"n",
				"<leader>cD",
				crates.open_documentation,
				vim.tbl_extend("force", opts, { desc = "Crates documentation" })
			)
			vim.keymap.set(
				"n",
				"<leader>cC",
				crates.open_crates_io,
				vim.tbl_extend("force", opts, { desc = "Crates.io" })
			)
		end,
	},
}
