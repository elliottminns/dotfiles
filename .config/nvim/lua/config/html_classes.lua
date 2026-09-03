local M = {}

local supported_filetypes = {
	astro = true,
	blade = true,
	eruby = true,
	html = true,
	htmldjango = true,
	javascriptreact = true,
	jsx = true,
	php = true,
	rust = true,
	svelte = true,
	templ = true,
	tsx = true,
	typescriptreact = true,
	vue = true,
}

-- Keep `class=` visible while replacing its quoted value with one character.
-- matchadd() is window-local and updates automatically as the buffer changes.
local class_value_pattern = [[\%(\<class\>\|\<className\>\)\s*=\s*\zs\%("[^"]*"\|'[^']*'\)]]

local function disable(win)
	local state = vim.w[win].html_classes_conceal
	if not state then
		return false
	end

	pcall(vim.fn.matchdelete, state.match_id, win)
	vim.wo[win].conceallevel = state.conceallevel
	vim.wo[win].concealcursor = state.concealcursor
	vim.wo[win].wrap = state.wrap
	vim.w[win].html_classes_conceal = nil
	return true
end

function M.toggle()
	local win = vim.api.nvim_get_current_win()
	if disable(win) then
		vim.notify("HTML classes expanded")
		return
	end

	if not supported_filetypes[vim.bo.filetype] then
		vim.notify("HTML class collapsing is not enabled for this filetype", vim.log.levels.WARN)
		return
	end

	local state = {
		conceallevel = vim.wo[win].conceallevel,
		concealcursor = vim.wo[win].concealcursor,
		wrap = vim.wo[win].wrap,
	}

	vim.wo[win].conceallevel = 2
	vim.wo[win].concealcursor = "nc"
	vim.wo[win].wrap = false
	state.match_id = vim.fn.matchadd("Conceal", class_value_pattern, 10, -1, { conceal = "…" })
	vim.w[win].html_classes_conceal = state
	vim.notify("HTML classes collapsed")
end

function M.setup()
	vim.api.nvim_create_user_command("ToggleHtmlClasses", M.toggle, {
		desc = "Toggle collapsed HTML class values",
	})

	vim.api.nvim_create_autocmd("FileType", {
		pattern = vim.tbl_keys(supported_filetypes),
		callback = function(event)
			vim.keymap.set("n", "<leader>tc", M.toggle, {
				buffer = event.buf,
				desc = "Toggle HTML classes",
			})
		end,
	})
end

return M
