local default_sort = {
	{ "type", "asc" },
	{ "name", "asc" },
}

local rust_project_sort = {
	{ "name", "asc" },
}

local function is_rust_project_dir(dir)
	return dir and vim.fs.find("Cargo.toml", { path = dir, upward = true })[1] ~= nil
end

local function set_oil_sort(sort)
	local config = require("oil.config")

	if not vim.deep_equal(config.view_options.sort, sort) then
		require("oil").set_sort(sort)
	end
end

local function apply_project_sort(bufnr)
	local dir = require("oil").get_current_dir(bufnr)
	set_oil_sort(is_rust_project_dir(dir) and rust_project_sort or default_sort)
end

return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {
		view_options = {
			sort = default_sort,
		},
	},
	-- Optional dependencies
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	config = function(_, opts)
		vim.keymap.set("n", "<space>o", require("oil").toggle_float)
		require("oil").setup(opts)
		local group = vim.api.nvim_create_augroup("OilProjectSort", { clear = true })

		vim.api.nvim_create_autocmd("User", {
			group = group,
			pattern = "OilEnter",
			callback = function(args)
				apply_project_sort(args.data and args.data.buf or args.buf)
			end,
		})
		vim.api.nvim_create_autocmd("BufEnter", {
			group = group,
			callback = function(args)
				if vim.bo[args.buf].filetype == "oil" then
					apply_project_sort(args.buf)
				end
			end,
		})
	end,
}
