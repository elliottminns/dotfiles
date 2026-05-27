local M = {}

local function char_at(line, index)
	return line:sub(index, index)
end

local function is_ident_char(char)
	return char:match("[%w_]") ~= nil
end

local function raw_string_start(line, index)
	local previous = index > 1 and char_at(line, index - 1) or ""

	if previous ~= "" and is_ident_char(previous) then
		return nil
	end

	local rest = line:sub(index)
	local prefix, hashes = rest:match("^(br)(#*)\"")

	if not prefix then
		prefix, hashes = rest:match("^(cr)(#*)\"")
	end

	if not prefix then
		prefix, hashes = rest:match("^(r)(#*)\"")
	end

	if not prefix then
		return nil
	end

	return {
		hashes = hashes,
		next_index = index + #prefix + #hashes + 1,
	}
end

local function skip_char_literal(line, index)
	if char_at(line, index) ~= "'" then
		return nil
	end

	local next_char = char_at(line, index + 1)

	if next_char == "\\" then
		local close_index = index + 3
		if char_at(line, close_index) == "'" then
			return close_index + 1
		end

		local unicode_close = line:find("}'", index + 2, true)
		if unicode_close and unicode_close - index <= 12 then
			return unicode_close + 2
		end
	elseif next_char ~= "" and char_at(line, index + 2) == "'" then
		return index + 3
	end

	return nil
end

local function scan_line(state, line)
	local index = 1
	local escaped = false

	while index <= #line do
		local char = char_at(line, index)
		local pair = line:sub(index, index + 1)

		if state.mode == "string" then
			if escaped then
				escaped = false
			elseif char == "\\" then
				escaped = true
			elseif char == "\"" then
				state.mode = "normal"
			end

			index = index + 1
		elseif state.mode == "raw_string" then
			local raw_hashes = state.raw_hashes

			if char == "\"" and line:sub(index + 1, index + #raw_hashes) == raw_hashes then
				state.mode = "normal"
				state.raw_hashes = nil
				index = index + #raw_hashes + 1
			else
				index = index + 1
			end
		elseif state.mode == "block_comment" then
			if pair == "/*" then
				state.comment_depth = state.comment_depth + 1
				index = index + 2
			elseif pair == "*/" then
				state.comment_depth = state.comment_depth - 1
				index = index + 2

				if state.comment_depth == 0 then
					state.mode = "normal"
				end
			else
				index = index + 1
			end
		elseif pair == "//" then
			return
		elseif pair == "/*" then
			state.mode = "block_comment"
			state.comment_depth = 1
			index = index + 2
		elseif char == "'" then
			index = skip_char_literal(line, index) or (index + 1)
		else
			local raw_start = raw_string_start(line, index)

			if raw_start then
				state.mode = "raw_string"
				state.raw_hashes = raw_start.hashes
				index = raw_start.next_index
			elseif char == "\"" then
				state.mode = "string"
				index = index + 1
			else
				index = index + 1
			end
		end
	end
end

local function begins_inside_string(bufnr, lnum)
	if lnum <= 1 then
		return false
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, lnum - 1, false)
	local state = {
		mode = "normal",
		comment_depth = 0,
		raw_hashes = nil,
	}

	for _, line in ipairs(lines) do
		scan_line(state, line)
	end

	return state.mode == "string" or state.mode == "raw_string"
end

function M.indentexpr()
	if vim.bo.filetype == "rust" and begins_inside_string(0, vim.v.lnum) then
		return 0
	end

	return require("nvim-treesitter").indentexpr()
end

M._begins_inside_string = begins_inside_string

return M
