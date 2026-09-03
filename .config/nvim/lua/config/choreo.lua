local M = {}

local defaults = {
	max_pause_ms = 1500,
	min_delay_ms = 12,
	jitter = 0.18,
	paste_char_delay_ms = 35,
}

local state = {
	recording = nil,
	last = nil,
	playback = nil,
}

local function now_ms()
	return vim.uv.hrtime() / 1e6
end

local function buffer_text(bufnr)
	return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
end

local function text_lines(text)
	return vim.split(text, "\n", { plain = true })
end

local function common_edit(before, after)
	local prefix = 0
	local limit = math.min(#before, #after)

	while prefix < limit and before:byte(prefix + 1) == after:byte(prefix + 1) do
		prefix = prefix + 1
	end

	-- Keep byte offsets on UTF-8 character boundaries.
	while prefix > 0 and before:byte(prefix + 1) and before:byte(prefix + 1) >= 0x80 and before:byte(prefix + 1) < 0xC0 do
		prefix = prefix - 1
	end

	local suffix = 0
	local before_left = #before - prefix
	local after_left = #after - prefix
	while suffix < before_left and suffix < after_left do
		if before:byte(#before - suffix) ~= after:byte(#after - suffix) then
			break
		end
		suffix = suffix + 1
	end

	while suffix > 0 do
		local before_start = #before - suffix + 1
		local byte = before:byte(before_start)
		if not byte or byte < 0x80 or byte >= 0xC0 then
			break
		end
		suffix = suffix - 1
	end

	return {
		offset = prefix,
		deleted = before:sub(prefix + 1, #before - suffix),
		inserted = after:sub(prefix + 1, #after - suffix),
	}
end

local function point_at(text, offset)
	local before = text:sub(1, offset)
	local _, newline_count = before:gsub("\n", "")
	local last_newline = before:match(".*()\n")
	return newline_count, last_newline and (offset - last_newline) or offset
end

local function replace_bytes(bufnr, current, offset, deleted_bytes, replacement)
	local start_row, start_col = point_at(current, offset)
	local end_row, end_col = point_at(current, offset + deleted_bytes)
	vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, text_lines(replacement))
	return current:sub(1, offset) .. replacement .. current:sub(offset + deleted_bytes + 1)
end

local function utf8_chars(text)
	local chars = {}
	local index = 1
	while index <= #text do
		local byte = text:byte(index)
		local length = byte < 0x80 and 1 or byte < 0xE0 and 2 or byte < 0xF0 and 3 or 4
		table.insert(chars, text:sub(index, index + length - 1))
		index = index + length
	end
	return chars
end

local function units_text(units)
	local chars = {}
	for index, unit in ipairs(units) do
		chars[index] = unit.char
	end
	return table.concat(chars)
end

local function copy_units(units)
	local copy = {}
	for index, unit in ipairs(units) do
		copy[index] = unit
	end
	return copy
end


local function unit_index_at_offset(units, offset)
	local bytes = 0
	for index, unit in ipairs(units) do
		if bytes == offset then
			return index - 1
		end
		bytes = bytes + #unit.char
	end
	assert(bytes == offset, "Choreo edit offset is not on a character boundary")
	return #units
end

local function find_unit(units, id)
	for index, unit in ipairs(units) do
		if unit.id == id then
			return index
		end
	end
end

local function compile_clean_edits(initial, edits)
	local recorded_units = {}
	for index, char in ipairs(utf8_chars(initial)) do
		recorded_units[index] = { id = "initial:" .. index, char = char }
	end

	local events = {}
	for edit_index, edit in ipairs(edits) do
		local start_index = unit_index_at_offset(recorded_units, edit.offset)
		local end_index = unit_index_at_offset(recorded_units, edit.offset + #edit.deleted)
		local before_ids = {}
		for index, unit in ipairs(recorded_units) do
			before_ids[index] = unit.id
		end

		local deleted_ids = {}
		for index = start_index + 1, end_index do
			table.insert(deleted_ids, recorded_units[index].id)
		end

		local inserted_units = {}
		for char_index, char in ipairs(utf8_chars(edit.inserted)) do
			table.insert(inserted_units, {
				id = string.format("edit:%d:%d", edit_index, char_index),
				char = char,
			})
		end

		for _ = start_index + 1, end_index do
			table.remove(recorded_units, start_index + 1)
		end
		for index, unit in ipairs(inserted_units) do
			table.insert(recorded_units, start_index + index, unit)
		end

		table.insert(events, {
			start_index = start_index,
			end_index = end_index,
			before_ids = before_ids,
			deleted_ids = deleted_ids,
			inserted_units = inserted_units,
			delay_ms = edit.delay_ms,
		})
	end

	local survives = {}
	for _, unit in ipairs(recorded_units) do
		survives[unit.id] = true
	end

	local replay_units = {}
	for index, char in ipairs(utf8_chars(initial)) do
		replay_units[index] = { id = "initial:" .. index, char = char }
	end

	local clean = {}
	local pending_delay = 0
	for _, event in ipairs(events) do
		local before = units_text(replay_units)
		pending_delay = pending_delay + event.delay_ms

		local deleted = {}
		for _, id in ipairs(event.deleted_ids) do
			deleted[id] = true
		end
		for index = #replay_units, 1, -1 do
			if deleted[replay_units[index].id] then
				table.remove(replay_units, index)
			end
		end

		local insertion_index
		for index = event.start_index, 1, -1 do
			local found = find_unit(replay_units, event.before_ids[index])
			if found then
				insertion_index = found
				break
			end
		end
		if not insertion_index then
			for index = event.end_index + 1, #event.before_ids do
				local found = find_unit(replay_units, event.before_ids[index])
				if found then
					insertion_index = found - 1
					break
				end
			end
		end
		insertion_index = insertion_index or #replay_units

		local inserted_count = 0
		for _, unit in ipairs(event.inserted_units) do
			if survives[unit.id] then
				inserted_count = inserted_count + 1
				table.insert(replay_units, insertion_index + inserted_count, unit)
			end
		end

		local after = units_text(replay_units)
		if before ~= after then
			local clean_edit = common_edit(before, after)
			clean_edit.delay_ms = pending_delay
			pending_delay = 0
			table.insert(clean, clean_edit)
		end
	end

	return clean, units_text(recorded_units)
end

local function set_cursor_at_offset(bufnr, text, offset)
	local row, col = point_at(text, offset)
	local win = vim.fn.bufwinid(bufnr)
	if win ~= -1 then
		pcall(vim.api.nvim_win_set_cursor, win, { row + 1, col })
	end
end

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "Choreo" })
end

local function capture_change()
	local recording = state.recording
	if not recording or recording.busy or not vim.api.nvim_buf_is_valid(recording.bufnr) then
		return
	end

	local current = buffer_text(recording.bufnr)
	if current == recording.current then
		return
	end

	local timestamp = now_ms()
	local edit = common_edit(recording.current, current)
	edit.delay_ms = math.min(timestamp - recording.last_at, M.config.max_pause_ms)
	edit.cursor = vim.api.nvim_win_get_cursor(0)
	table.insert(recording.edits, edit)
	recording.current = current
	recording.last_at = timestamp
end

function M.record()
	if state.playback then
		notify("Cancel playback before recording", vim.log.levels.WARN)
		return
	end
	if state.recording then
		notify("Already recording", vim.log.levels.WARN)
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local initial = buffer_text(bufnr)
	state.recording = {
		bufnr = bufnr,
		initial = initial,
		current = initial,
		edits = {},
		last_at = now_ms(),
		busy = false,
	}
	local recording = state.recording

	vim.api.nvim_buf_attach(bufnr, false, {
		on_lines = function()
			if state.recording ~= recording then
				return true
			end
			vim.schedule(capture_change)
		end,
		on_detach = function()
			if state.recording and state.recording.bufnr == bufnr then
				state.recording = nil
			end
		end,
	})
	notify("Recording edits; run :ChoreoStop when the buffer is correct")
end

function M.stop()
	local recording = state.recording
	if not recording then
		notify("Nothing is being recorded", vim.log.levels.WARN)
		return
	end

	capture_change()
	state.recording = nil
	local clean_edits, compiled_final = compile_clean_edits(recording.initial, recording.edits)
	if compiled_final ~= recording.current then
		notify("Could not compile the rehearsal into a clean take", vim.log.levels.ERROR)
		return
	end
	state.last = {
		bufnr = recording.bufnr,
		initial = recording.initial,
		final = recording.current,
		edits = clean_edits,
	}
	notify(string.format("Compiled %d rehearsal edits into a clean take; run :ChoreoPlay", #recording.edits))
end

function M.cancel()
	if state.recording then
		state.recording = nil
		notify("Recording discarded")
		return
	end
	if state.playback then
		state.playback.cancelled = true
		state.playback = nil
		notify("Playback cancelled")
		return
	end
	notify("Nothing to cancel", vim.log.levels.WARN)
end

local function jittered_delay(delay)
	local spread = delay * M.config.jitter
	local value = delay + ((math.random() * 2 - 1) * spread)
	return math.max(M.config.min_delay_ms, math.floor(value + 0.5))
end

function M.play(opts)
	opts = opts or {}
	local take = state.last
	if not take then
		notify("Record a take first with :ChoreoRecord", vim.log.levels.WARN)
		return
	end
	if state.recording or state.playback then
		notify("Choreo is already active", vim.log.levels.WARN)
		return
	end
	if not vim.api.nvim_buf_is_valid(take.bufnr) then
		notify("The recorded buffer no longer exists", vim.log.levels.ERROR)
		return
	end
	if not opts.force and buffer_text(take.bufnr) ~= take.final then
		notify("Buffer changed since recording; use :ChoreoPlay! to overwrite it", vim.log.levels.ERROR)
		return
	end

	vim.api.nvim_buf_set_lines(take.bufnr, 0, -1, false, text_lines(take.initial))
	local playback = { cancelled = false, text = take.initial, edit_index = 1 }
	state.playback = playback
	vim.schedule(function()
		if state.playback == playback then
			vim.cmd.startinsert()
		end
	end)

	local run_edit
	local function finish()
		if state.playback ~= playback then
			return
		end
		state.playback = nil
		notify("Playback complete")
	end

	local function insert_chars(edit, chars, index, offset)
		if state.playback ~= playback or playback.cancelled then
			return
		end
		if index > #chars then
			playback.edit_index = playback.edit_index + 1
			run_edit()
			return
		end

		local char = chars[index]
		playback.text = replace_bytes(take.bufnr, playback.text, offset, 0, char)
		set_cursor_at_offset(take.bufnr, playback.text, offset + #char)
		vim.defer_fn(function()
			insert_chars(edit, chars, index + 1, offset + #char)
		end, jittered_delay(M.config.paste_char_delay_ms))
	end

	run_edit = function()
		if state.playback ~= playback or playback.cancelled then
			return
		end
		local edit = take.edits[playback.edit_index]
		if not edit then
			finish()
			return
		end

		vim.defer_fn(function()
			if state.playback ~= playback or playback.cancelled then
				return
			end
			playback.text = replace_bytes(take.bufnr, playback.text, edit.offset, #edit.deleted, "")
			set_cursor_at_offset(take.bufnr, playback.text, edit.offset)
			local chars = utf8_chars(edit.inserted)
			if #chars == 0 then
				playback.edit_index = playback.edit_index + 1
				run_edit()
			else
				insert_chars(edit, chars, 1, edit.offset)
			end
		end, jittered_delay(edit.delay_ms))
	end

	run_edit()
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", defaults, opts or {})

	vim.api.nvim_create_user_command("ChoreoRecord", M.record, { desc = "Record a code-editing take" })
	vim.api.nvim_create_user_command("ChoreoStop", M.stop, { desc = "Finish the current Choreo take" })
	vim.api.nvim_create_user_command("ChoreoCancel", M.cancel, { desc = "Cancel Choreo recording or playback" })
	vim.api.nvim_create_user_command("ChoreoPlay", function(command)
		M.play({ force = command.bang })
	end, { bang = true, desc = "Replay the last Choreo take" })
end

M._test = {
	compile_clean_edits = compile_clean_edits,
	common_edit = common_edit,
	point_at = point_at,
}

return M
