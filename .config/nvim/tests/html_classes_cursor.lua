vim.opt.runtimepath:prepend(vim.fn.getcwd())

local html_classes = require("config.html_classes")
html_classes.setup()

vim.cmd.enew()
vim.bo.filetype = "html"
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
	[[<div class="flex items-center gap-2">content</div>]],
})

html_classes.toggle()

-- A concealed class value should behave as a single, non-enterable unit.
-- This covers both mouse placement and stepping into it with h/l.
for _, column in ipairs({ 12, 17, 28 }) do
	vim.api.nvim_win_set_cursor(0, { 1, column })
	vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
	local actual = vim.api.nvim_win_get_cursor(0)[2]
	assert(actual < 11 or actual > 35, ("cursor remained inside concealed classes at column %d"):format(actual))
end
