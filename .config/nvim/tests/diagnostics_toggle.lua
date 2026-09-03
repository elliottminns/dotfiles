vim.opt.runtimepath:prepend(vim.fn.getcwd())

local diagnostics = require("config.diagnostics")
local lualine_spec = dofile("lua/plugins/lualine.lua")
local statusline_diagnostics = lualine_spec[1].opts.sections.lualine_b[3]

vim.cmd.enew()
local bufnr = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "broken" })

local namespace = vim.api.nvim_create_namespace("diagnostics_toggle_test")
vim.diagnostic.set(namespace, bufnr, {
	{
		lnum = 0,
		col = 0,
		end_lnum = 0,
		end_col = 6,
		message = "test error",
		severity = vim.diagnostic.severity.ERROR,
	},
})

assert(statusline_diagnostics.cond(), "statusline diagnostics should begin enabled")
local _, float_win = diagnostics.open_float({ scope = "cursor", focus = false })
assert(float_win and vim.api.nvim_win_is_valid(float_win), "enabled diagnostics should open a float")

diagnostics.toggle(bufnr)
assert(not diagnostics.is_enabled(bufnr), "diagnostics were not disabled")
assert(not statusline_diagnostics.cond(), "disabled diagnostics still appear in the statusline")
assert(not vim.api.nvim_win_is_valid(float_win), "existing diagnostic float remained open")
assert(diagnostics.open_float({ scope = "cursor" }) == nil, "disabled diagnostics opened a new float")

diagnostics.toggle(bufnr)
assert(diagnostics.is_enabled(bufnr), "diagnostics were not re-enabled")
assert(statusline_diagnostics.cond(), "re-enabled diagnostics are absent from the statusline")

print("diagnostics toggle tests: ok")
