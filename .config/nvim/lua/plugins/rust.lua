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

			local file_test_diag_namespace = vim.api.nvim_create_namespace("rust_file_tests")
			local file_test_marker_namespace = vim.api.nvim_create_namespace("rust_file_test_markers")
			local active_test_spinners = {}
			local last_file_test

			local function test_summary(output)
				return output:match("(test result:.*)")
			end

			local function test_message(message, hl_group)
				vim.api.nvim_echo({ { message, hl_group or "None" } }, false, {})
			end

			local function set_test_quickfix(title, output, open)
				vim.fn.setqflist({}, " ", {
					title = title,
					lines = vim.split(output, "\n"),
				})

				if open then
					local current_win = vim.api.nvim_get_current_win()
					vim.cmd.copen()
					pcall(vim.api.nvim_set_current_win, current_win)
				end
			end

			local function set_test_marker(bufnr, test, label, hl_group)
				if not test or not test.line or not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end

				local line = test.line - 1
				vim.api.nvim_buf_clear_namespace(bufnr, file_test_marker_namespace, line, line + 1)
				vim.api.nvim_buf_set_extmark(bufnr, file_test_marker_namespace, line, 0, {
					sign_text = label,
					sign_hl_group = hl_group,
					priority = 20,
				})
			end

			local function test_marker_key(bufnr, test)
				return bufnr .. ":" .. test.line
			end

			local function stop_test_spinner(bufnr, test)
				if not test then
					return
				end

				local key = test_marker_key(bufnr, test)
				local spinner = active_test_spinners[key]

				if not spinner then
					return
				end

				spinner.timer:stop()
				spinner.timer:close()
				active_test_spinners[key] = nil
			end

			local function start_test_spinner(bufnr, test)
				if not test or not test.line or not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end

				stop_test_spinner(bufnr, test)

				local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
				local frame = 1
				local timer = vim.uv.new_timer()

				if not timer then
					set_test_marker(bufnr, test, "[running]", "DiagnosticWarn")
					return
				end

				local key = test_marker_key(bufnr, test)
				active_test_spinners[key] = { timer = timer }

				local function render()
					if not active_test_spinners[key] then
						return
					end

					if not vim.api.nvim_buf_is_valid(bufnr) then
						stop_test_spinner(bufnr, test)
						return
					end

					set_test_marker(bufnr, test, frames[frame], "DiagnosticWarn")
					frame = frame % #frames + 1
				end

				render()
				timer:start(120, 120, function()
					vim.schedule(render)
				end)
			end

			local function find_cargo_root(bufnr)
				local file = vim.api.nvim_buf_get_name(bufnr)
				local dir = vim.fs.dirname(file)
				local cargo_toml = vim.fs.find("Cargo.toml", { path = dir, upward = true })[1]

				return cargo_toml and vim.fs.dirname(cargo_toml) or vim.fn.getcwd()
			end

			local function integration_test_target(bufnr, cargo_root)
				local file = vim.api.nvim_buf_get_name(bufnr)
				local root = vim.fs.normalize(cargo_root)
				local normalized = vim.fs.normalize(file)
				local rel = normalized:sub(#root + 2)

				return rel:match("^tests/([^/]+)%.rs$")
					or rel:match("^tests/([^/]+)/main%.rs$")
					or rel:match("^tests/([^/]+)/mod%.rs$")
			end

			local function is_rust_test_attr(line)
				return line:match("^%s*#%s*%[%s*test%s*[%]%)]")
					or line:match("^%s*#%s*%[%s*[%w_]+::test%s*[%]%)]")
					or line:match("^%s*#%s*%[%s*rstest%s*[%]%)]")
			end

			local function find_function_end(lines, start_idx)
				local depth = 0
				local saw_open_brace = false

				for idx = start_idx, #lines do
					for char in lines[idx]:gmatch("[{}]") do
						if char == "{" then
							depth = depth + 1
							saw_open_brace = true
						elseif char == "}" then
							depth = depth - 1
						end
					end

					if saw_open_brace and depth <= 0 then
						return idx
					end
				end

				return start_idx
			end

			local function rust_tests_in_buffer(bufnr)
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
				local tests = {}
				local pending_test_attr

				for idx, line in ipairs(lines) do
					if is_rust_test_attr(line) then
						pending_test_attr = idx
					elseif pending_test_attr then
						local name = line:match("^%s*[%w_%(%):%s]*fn%s+([%w_]+)")

						if name then
							table.insert(tests, {
								name = name,
								line = idx,
								attr_line = pending_test_attr,
								end_line = find_function_end(lines, idx),
							})
							pending_test_attr = nil
						elseif not line:match("^%s*#") and not line:match("^%s*$") then
							pending_test_attr = nil
						end
					end
				end

				return tests
			end

			local function execute_cargo_test(args, cwd, bufnr, test)
				vim.diagnostic.reset(file_test_diag_namespace, bufnr)
				start_test_spinner(bufnr, test)

				local cmd = vim.list_extend({ "cargo" }, args)
				local title = table.concat(cmd, " ")

				test_message("Running " .. title, "DiagnosticWarn")

				vim.system(cmd, { cwd = cwd }, function(result)
					local output = table.concat({
						result.stderr or "",
						result.stdout or "",
					}, "\n")
					local summary = test_summary(result.stdout or "") or test_summary(output)

					vim.schedule(function()
						stop_test_spinner(bufnr, test)
						set_test_quickfix(title, output, result.code ~= 0)

						if result.code == 0 then
							set_test_marker(bufnr, test, "✓", "DiagnosticOk")
							test_message(summary or "test passed!", "DiagnosticOk")
							return
						end

						local diagnostics = require("rustaceanvim.test").parse_cargo_test_diagnostics(output, bufnr)
						vim.diagnostic.set(file_test_diag_namespace, bufnr, diagnostics)
						set_test_marker(bufnr, test, "✗", "DiagnosticError")
						vim.cmd.redraw()
						test_message(summary or "test failed; opened quickfix with Cargo output.", "DiagnosticError")
					end)
				end)
			end

			local function run_cargo_test(test)
				local bufnr = vim.api.nvim_get_current_buf()
				local cwd = find_cargo_root(bufnr)
				local args = { "test" }
				local target = integration_test_target(bufnr, cwd)

				if target then
					vim.list_extend(args, { "--test", target })
				end

				vim.list_extend(args, { test.name, "--", "--nocapture" })
				last_file_test = { args = args, bufnr = bufnr, cwd = cwd, test = test }

				execute_cargo_test(args, cwd, bufnr, test)
			end

			local function run_all_tests()
				local bufnr = vim.api.nvim_get_current_buf()
				local cwd = find_cargo_root(bufnr)
				local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

				execute_cargo_test({ "test", "--", "--nocapture" }, cwd, bufnr, {
					name = "all tests",
					line = cursor_line,
				})
			end

			local function select_file_test()
				local bufnr = vim.api.nvim_get_current_buf()
				local tests = rust_tests_in_buffer(bufnr)

				if #tests == 0 then
					test_message("No Rust tests found in this file.", "DiagnosticWarn")
					return
				end

				vim.ui.select(tests, {
					prompt = "Rust tests in file",
					format_item = function(test)
						return test.name .. "  line " .. test.line
					end,
				}, function(test)
					if test then
						run_cargo_test(test)
					end
				end)
			end

			local function run_file_test_at_cursor()
				local bufnr = vim.api.nvim_get_current_buf()
				local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
				local tests = rust_tests_in_buffer(bufnr)

				for _, test in ipairs(tests) do
					if cursor_line >= test.attr_line and cursor_line <= test.end_line then
						run_cargo_test(test)
						return
					end
				end

				vim.cmd.RustLsp("run")
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

						vim.api.nvim_buf_create_user_command(bufnr, "RustTestAll", run_all_tests, {
							desc = "Run all Rust tests",
						})

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
						map("<leader>ru", rust_lsp("run"), "Rust run at cursor")
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
						map("<leader>rta", rust_lsp("testables"), "Rust analyzer testables")
						map("<leader>rtA", run_all_tests, "Rust test all")
						map("<leader>rtt", select_file_test, "Rust test in file")
						map("<leader>rtT", function()
							if last_file_test then
								execute_cargo_test(
									last_file_test.args,
									last_file_test.cwd,
									last_file_test.bufnr,
									last_file_test.test
								)
							else
								vim.cmd.RustLsp({ "testables", bang = true })
							end
						end, "Rust rerun last test")
						map("<leader>rtu", run_file_test_at_cursor, "Rust test at cursor")
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
