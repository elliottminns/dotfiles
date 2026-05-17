return function(cmp)
	local cmp_ui = {
		icons = true,
		lspkind_text = true,
		style = "default", -- default/flat_light/flat_dark/atom/atom_colored
		border_color = "grey_fg", -- only applicable for "default" style, use color names from base30 variables
		selected_item_bg = "simple", -- colored / simple
	}
	local cmp_style = cmp_ui.style

	local field_arrangement = {
		atom = { "kind", "abbr", "menu" },
		atom_colored = { "kind", "abbr", "menu" },
	}

	local function truncate(value, max_width)
		if not value or vim.fn.strdisplaywidth(value) <= max_width then
			return value
		end

		return vim.fn.strcharpart(value, 0, max_width - 3) .. "..."
	end

	local formatting_style = {
		-- default fields order i.e completion word + item.kind + item.kind icons
		fields = field_arrangement[cmp_style] or { "abbr", "kind", "menu" },

		format = function(_, item)
			--jlocal icons = require "nvchad.icons.lspkind"
			local icon = "" --(cmp_ui.icons and icons[item.kind]) or ""

			if cmp_style == "atom" or cmp_style == "atom_colored" then
				icon = " " .. icon .. " "
				item.menu = cmp_ui.lspkind_text and "   (" .. item.kind .. ")" or ""
				item.kind = icon
			else
				icon = cmp_ui.lspkind_text and (" " .. icon .. " ") or icon
				item.kind = string.format("%s %s", icon, cmp_ui.lspkind_text and item.kind or "")
			end

			item.abbr = truncate(item.abbr, 44)
			item.menu = truncate(item.menu, 18)

			return item
		end,
	}

	local function border(hl_name)
		return {
			{ "╭", hl_name },
			{ "─", hl_name },
			{ "╮", hl_name },
			{ "│", hl_name },
			{ "╯", hl_name },
			{ "─", hl_name },
			{ "╰", hl_name },
			{ "│", hl_name },
		}
	end

	vim.api.nvim_set_hl(0, "CmpPmenu", { link = "Pmenu" })
	vim.api.nvim_set_hl(0, "CmpSel", { link = "Visual" })
	vim.api.nvim_set_hl(0, "CmpDoc", { link = "NormalFloat" })

	local options = {
		completion = {
			completeopt = "menu,menuone",
		},

		view = {
			entries = {
				name = "custom",
				selection_order = "top_down",
			},
			docs = {
				auto_open = true,
			},
		},

		window = {
			completion = {
				side_padding = (cmp_style ~= "atom" and cmp_style ~= "atom_colored") and 1 or 0,
				winhighlight = "Normal:CmpPmenu,FloatBorder:Pmenu,CursorLine:CmpSel,Search:None",
				scrollbar = false,
			},
			documentation = {
				border = border("CmpDocBorder"),
				winhighlight = "Normal:CmpDoc",
				max_width = 88,
				max_height = 20,
			},
		},
		snippet = {
			expand = function(args)
				require("luasnip").lsp_expand(args.body)
			end,
		},

		formatting = formatting_style,

		mapping = {
			["<C-p>"] = cmp.mapping.select_prev_item(),
			["<C-n>"] = cmp.mapping.select_next_item(),
			["<C-d>"] = cmp.mapping.scroll_docs(-4),
			["<C-f>"] = cmp.mapping.scroll_docs(4),
			["<C-g>"] = cmp.mapping(function()
				if cmp.visible_docs() then
					cmp.close_docs()
				else
					cmp.open_docs()
				end
			end),
			["<C-Space>"] = cmp.mapping.complete(),
			["<C-e>"] = cmp.mapping.close(),
			["<CR>"] = cmp.mapping.confirm({
				behavior = cmp.ConfirmBehavior.Insert,
				select = true,
			}),
			["<Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_next_item()
				elseif require("luasnip").expand_or_jumpable() then
					vim.fn.feedkeys(
						vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true),
						""
					)
				else
					fallback()
				end
			end, {
				"i",
				"s",
			}),
			["<S-Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item()
				elseif require("luasnip").jumpable(-1) then
					vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
				else
					fallback()
				end
			end, {
				"i",
				"s",
			}),
		},
		sources = {
			{ name = "nvim_lsp" },
			{ name = "luasnip" },
			{ name = "buffer" },
			{ name = "nvim_lua" },
			{ name = "path" },
		},
	}

	if cmp_style ~= "atom" and cmp_style ~= "atom_colored" then
		options.window.completion.border = border("CmpBorder")
	end

	return options
end
