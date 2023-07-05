local window = require("ido.window")
local config = require("ido.config")

local M = {}

function M.highlight_line(linenum, buf, highlight, namespace)
	-- vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
	vim.api.nvim_buf_add_highlight(buf, namespace, highlight, linenum, 0, -1)
end

local function set_highlights()
  ns = vim.api.nvim_create_namespace("")

  vim.api.nvim_set_hl(ns, "IdoSelectedLine", {
    standout = true,
  })

  vim.api.nvim_set_hl(0, "IdoBold", {
    bold = true,
  })

  return ns
end

M.match_files = function()
  local namespace = set_highlights()

  local win = window.new_window("IdoFindFiles", {
    style = "minimal",
    relative = "editor",
    row = vim.o.lines,
    col = 0,
    width = vim.o.columns,
    height = config.num_results + 1,
  })

  vim.api.nvim_buf_set_lines(win.buf, 0, 1, false, {"Find file: "})
  M.highlight_line(0, win.buf, "IdoBold", namespace)

  return win
end

return M
