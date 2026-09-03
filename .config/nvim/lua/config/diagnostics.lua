local M = {}

local float_windows = {}

function M.is_enabled(bufnr)
	return vim.diagnostic.is_enabled({ bufnr = bufnr or vim.api.nvim_get_current_buf() })
end

local function close_float(bufnr)
	local win = float_windows[bufnr]
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
	float_windows[bufnr] = nil
end

function M.open_float(opts)
	opts = opts or {}
	local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
	if not M.is_enabled(bufnr) then
		return
	end

	local float_bufnr, win = vim.diagnostic.open_float(opts)
	if win then
		float_windows[bufnr] = win
	end
	return float_bufnr, win
end

function M.toggle(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local enabled = M.is_enabled(bufnr)
	vim.diagnostic.enable(not enabled, { bufnr = bufnr })
	if enabled then
		close_float(bufnr)
	end
	vim.cmd.redrawstatus()
	vim.notify("Diagnostics " .. (enabled and "disabled" or "enabled"))
	return not enabled
end

return M
