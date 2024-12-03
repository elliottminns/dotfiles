local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node

local ts_locals = require("nvim-treesitter.locals")
local ts_utils = require("nvim-treesitter.ts_utils")
local get_node_text = vim.treesitter.get_node_text

vim.treesitter.query.set(
	"go",
	"method_receiver_name",
	[[ [
		(method_declaration
			receiver: (parameter_list
				(parameter_declaration
					name: (identifier) @receiver_name
					)
				)
			)
	] ]]
)

local function get_go_receiver_name()
	local cursor_node = ts_utils.get_node_at_cursor()
	local scope = ts_locals.get_scope_tree(cursor_node, 0)

	local function_node
	for _, v in ipairs(scope) do
		if v:type() == "method_declaration" then
			function_node = v
			break
		end
	end

	if function_node == nil then
		return nil
	end

	local bufnr = 0

	local query = vim.treesitter.query.get("go", "method_receiver_name")
	for id, node in query:iter_captures(function_node, bufnr) do
		local name = query.captures[id]
		if name == "receiver_name" then
			local receiver_name = vim.treesitter.get_node_text(node, bufnr)
			return receiver_name
		end
	end

	return nil
end

local go_receiver_name = function()
	local receiver_name = get_go_receiver_name()
	print(receiver_name)

	if receiver_name == nil then
		return
	end

	return ls.sn(nil, { t(receiver_name .. ".") })
end

ls.add_snippets("go", {
	s("slogerr", {
		d(1, go_receiver_name),
		t('logger.Error("'),
		i(2, "msg"),
		t('", slog.Any("error", err))'),
	}),

	s("iferr", {
		t({ "if err != nil {", "" }),
		i(1, "  return"),
		t({ "", "}" }),
	}),

	s("fmterr", {
		t('fmt.Errorf("'),
		i(1, "msg"),
		t(': %w", err)'),
	}),

	s("httperr", {
		t({ "if err != nil {", "  w.WriteHeader(http." }),
		i(1, "StatusInternalServerError"),
		t({ ")", "  return", "}" }),
	}),
})
