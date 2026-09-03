vim.opt.runtimepath:prepend(vim.fn.getcwd())

local choreo = require("config.choreo")
choreo.setup({
	max_pause_ms = 20,
	min_delay_ms = 1,
	jitter = 0,
	paste_char_delay_ms = 1,
})

local function wait_for(predicate, message)
	assert(vim.wait(1000, predicate, 1), message)
end

local function text()
	return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

local function flush_scheduled_capture()
	vim.wait(10, function()
		return false
	end, 1)
end

-- The edit detector must use byte offsets that Neovim can safely apply, even
-- when the common prefix ends beside a multibyte character.
local unicode_edit = choreo._test.common_edit("café", "cafés")
assert(unicode_edit.offset == #"café")
assert(unicode_edit.deleted == "")
assert(unicode_edit.inserted == "s")

vim.cmd.enew()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "fn main() {", "}" })
local initial = text()

choreo.record()

-- Rehearse a typo, correct it, and then finish the intended text.
vim.api.nvim_buf_set_text(0, 1, 0, 1, 0, { "    pritn", "" })
flush_scheduled_capture()

vim.api.nvim_buf_set_text(0, 1, 4, 1, 9, { "print" })
flush_scheduled_capture()

vim.api.nvim_buf_set_text(0, 1, 9, 1, 9, { [[ln!("hello");]] })
flush_scheduled_capture()

local final = text()
choreo.stop()
choreo.play()

assert(text() == initial, "playback did not restore the starting state")
choreo.cancel()
assert(text() == initial, "cancelled playback changed the starting state")

local replayed_typo = false
vim.api.nvim_buf_attach(0, false, {
	on_lines = function()
		if text():find("pritn", 1, true) then
			replayed_typo = true
		end
	end,
})

choreo.play({ force = true })
wait_for(function()
	return text() == final
end, "playback did not reproduce the corrected final buffer")
assert(not replayed_typo, "playback visibly replayed a typo that was corrected during rehearsal")

print("choreo tests: ok")
