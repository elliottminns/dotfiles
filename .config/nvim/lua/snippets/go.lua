local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("go", {
	s("slogerr", {
		t('logger.Error("'),
		i(1, "msg"),
		t('", slog.Any("error", err))'),
	}),

	s("iferr", {
		t({ "if err != nil {", "" }),
		i(1, "return"),
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
