
local M = {}

local function bind_autoclose(window)
	vim.api.nvim_create_autocmd("WinClosed", {
		buffer = window.buf,
		callback = function()
      window.close()
		end,
	})
	vim.keymap.set(
		{ "n", "i" },
		"<C-c>",
		window.close,
		{ buffer = window.buf }
	)
	vim.keymap.set(
		{ "n", "i" },
		"<Esc>",
		window.close,
		{ buffer = window.buf }
	)
end

function M.new_window(name, opts)
	local created_buffer = vim.api.nvim_create_buf(true, true)
	local window = vim.api.nvim_open_win(created_buffer, true, opts)
	local data = {
		buf = created_buffer,
		opts = opts,
		win = window,
		close = function()
			if vim.api.nvim_buf_is_valid(created_buffer) then
				vim.api.nvim_buf_delete(created_buffer, { force = true })
			end
		end,
	}
  bind_autoclose(data)
	return data
end

return M
