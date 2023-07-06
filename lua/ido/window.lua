
local M = {}

function M.bind_autoclose(master, slave1, slave2)
	vim.api.nvim_create_autocmd("WinClosed", {
		buffer = master.buf,
		callback = function()
      master.close()
      slave1.close()
      slave2.close()
		end,
	})
	vim.keymap.set(
		{ "n", "i" },
		"<C-c>",
		master.close,
		{ buffer = master.buf }
	)
	vim.keymap.set(
		{ "n", "i" },
		"<Esc>",
		master.close,
		{ buffer = master.buf }
	)
end

function M.new_window(name, opts, enter)
	local created_buffer = vim.api.nvim_create_buf(true, true)
	local window = vim.api.nvim_open_win(created_buffer, enter or false, opts)
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
	return data
end

return M
