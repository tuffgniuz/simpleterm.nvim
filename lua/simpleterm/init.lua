local M = {}

local defaults = {
	mode = "bottom",
	size = 15,
	keymap = "<leader>t",
	scrollback = 1000,
	float = {
		width = 0.6,
		height = 0.6,
		border = "rounded",
	},
}

local state = {
	term_buf = nil,
	term_win = nil,
	config = vim.deepcopy(defaults),
	mapped_key = nil,
	initialized = false,
	augroup = nil,
}

local valid_modes = {
	left = true,
	right = true,
	float = true,
	bottom = true,
}

local function is_valid_buf(buf)
	return buf and vim.api.nvim_buf_is_valid(buf)
end

local function is_valid_win(win)
	return win and vim.api.nvim_win_is_valid(win)
end

local function has_term_buf()
	return is_valid_buf(state.term_buf)
end

local function has_term_win()
	return is_valid_win(state.term_win)
		and has_term_buf()
		and vim.api.nvim_win_get_buf(state.term_win) == state.term_buf
end

local function normalize_mode(mode)
	if not valid_modes[mode] then
		error(("simpleterm: invalid mode '%s'"):format(tostring(mode)))
	end

	return mode
end

local function normalize_float_dimension(value, total, fallback)
	if type(value) ~= "number" then
		value = fallback
	end

	if value > 0 and value < 1 then
		return math.max(1, math.floor(total * value))
	end

	return math.max(1, math.floor(value))
end

local function resolve_float_config()
	local cfg = state.config.float or {}
	local columns = vim.o.columns
	local lines = vim.o.lines - vim.o.cmdheight
	local width = normalize_float_dimension(cfg.width, columns, defaults.float.width)
	local height = normalize_float_dimension(cfg.height, lines, defaults.float.height)

	return {
		relative = "editor",
		width = math.min(width, columns),
		height = math.min(height, lines),
		col = math.floor((columns - width) / 2),
		row = math.floor((lines - height) / 2),
		style = "minimal",
		border = cfg.border or defaults.float.border,
	}
end

local function apply_float_window_style(win)
  vim.api.nvim_set_option_value("winhl", "Normal:SimpletermFloat,NormalFloat:SimpletermFloat,FloatBorder:SimpletermFloatBorder", {
    win = win,
  })
end

local function ensure_highlights()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local border = vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false })

  vim.api.nvim_set_hl(0, "SimpletermFloat", {
    bg = normal.bg,
    fg = normal.fg,
  })

  vim.api.nvim_set_hl(0, "SimpletermFloatBorder", {
    bg = normal.bg,
    fg = border.fg or normal.fg,
  })
end

local function focus_terminal()
	if not has_term_win() then
		return
	end

	vim.api.nvim_set_current_win(state.term_win)
	vim.cmd("startinsert")
end

local function open_split()
	if state.config.mode == "left" then
		local width = math.max(state.config.size, math.floor(vim.o.columns / 3))
		vim.cmd("topleft vsplit")
		vim.cmd(("vertical resize %d"):format(width))
	elseif state.config.mode == "right" then
		local width = math.max(state.config.size, math.floor(vim.o.columns / 3))
		vim.cmd("botright vsplit")
		vim.cmd(("vertical resize %d"):format(width))
	else
		vim.cmd("botright split")
		vim.cmd(("resize %d"):format(state.config.size))
	end

	return vim.api.nvim_get_current_win()
end

local function open_window_for_buffer(buf)
	if state.config.mode == "float" then
		local win = vim.api.nvim_open_win(buf, true, resolve_float_config())
		apply_float_window_style(win)
		return win
	end

	local win = open_split()
	vim.api.nvim_win_set_buf(win, buf)
	return win
end

local function create_terminal_window()
	if state.config.mode == "float" then
		local scratch = vim.api.nvim_create_buf(false, true)
		state.term_win = vim.api.nvim_open_win(scratch, true, resolve_float_config())
		apply_float_window_style(state.term_win)
	else
		state.term_win = open_split()
	end

	vim.cmd("terminal")

	state.term_buf = vim.api.nvim_get_current_buf()
	state.term_win = vim.api.nvim_get_current_win()
	vim.bo[state.term_buf].bufhidden = "hide"
	vim.bo[state.term_buf].scrollback = state.config.scrollback
end

local function reopen_terminal_window()
	state.term_win = open_window_for_buffer(state.term_buf)
end

local function close_terminal_window()
	if not has_term_win() then
		state.term_win = nil
		return
	end

	vim.api.nvim_win_close(state.term_win, true)
	state.term_win = nil
end

local function ensure_autocmds()
	if state.augroup then
		return
	end

	state.augroup = vim.api.nvim_create_augroup("simpleterm_state", { clear = true })

	vim.api.nvim_create_autocmd("WinClosed", {
		group = state.augroup,
		callback = function(args)
			if state.term_win == tonumber(args.match) then
				state.term_win = nil
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = state.augroup,
		callback = function(args)
			if state.term_buf == args.buf then
				state.term_buf = nil
				state.term_win = nil
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
		group = state.augroup,
		callback = function()
			if state.config.mode ~= "float" or not has_term_win() then
				return
			end

			vim.api.nvim_win_set_config(state.term_win, resolve_float_config())
			apply_float_window_style(state.term_win)
		end,
	})
end

local function set_keymaps(keymap)
	if state.mapped_key and state.mapped_key ~= keymap then
		pcall(vim.keymap.del, "n", state.mapped_key)
		pcall(vim.keymap.del, "t", state.mapped_key)
	end

	vim.keymap.set("n", keymap, M.toggle, {
		desc = "Toggle simpleterm",
		nowait = true,
		silent = true,
	})

	vim.keymap.set("t", keymap, [[<C-\><C-n><Cmd>lua require("simpleterm").toggle()<CR>]], {
		desc = "Toggle simpleterm",
		nowait = true,
		silent = true,
	})

	state.mapped_key = keymap
end

local function normalize_config(opts)
	local config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
	config.mode = normalize_mode(config.mode)
	config.size = math.max(1, math.floor(tonumber(config.size) or defaults.size))
	config.keymap = config.keymap or defaults.keymap
	config.scrollback = math.max(1, math.floor(tonumber(config.scrollback) or defaults.scrollback))
	config.float = vim.tbl_deep_extend("force", vim.deepcopy(defaults.float), config.float or {})

	return config
end

function M.setup(opts)
  state.config = normalize_config(opts)
  ensure_highlights()
  ensure_autocmds()
  set_keymaps(state.config.keymap)
  state.initialized = true
end

function M.toggle()
	if not state.initialized then
		M.setup()
	end

	if has_term_win() then
		close_terminal_window()
		return
	end

	if has_term_buf() then
		reopen_terminal_window()
	else
		create_terminal_window()
	end

	focus_terminal()
end

return M
