local config = require("ido.config")

local M = {}

local last_path = ""

local function log(message)
  local file = io.open("log.txt", "a")
  file:write(message .. "\n")
  file:close()
end

local function filter(paths, search)
  return vim.tbl_filter(function(path)
    if search:lower() == search then
      return (path:lower()):match(search)
    else
      return path:match(search)
    end
  end, paths)
end

local function ls(dir)
  local output = vim.fn.systemlist("ls " .. dir)
  local mapped = vim.tbl_map(function(path)
    if vim.fn.isdirectory(dir:gsub("~", vim.env.HOME) .. "/" .. path) > 0 then
      return path .. "/"
    else
      return path
    end
  end, output)
  return mapped
end

local function format_paths(paths, threshold)
  local formatted = vim.tbl_map(function(path)
    return " " .. path .. " "
  end, paths)
  local joined = table.concat(formatted, "|")
  if #joined > vim.o.columns - threshold then
    local total = 0
    local i = 1
    while total < vim.o.columns - threshold - 27 do
      total = total + #formatted[i]
      i = i + 1
    end
    joined = table.concat(formatted, "|", 1, i - 2) .. "| ... "
  end
  return "{" .. joined .. "}"
end

local function extract_path(text)
  local path = text:gsub("%[.*%]", "")
  path = path:gsub("%{.*%}", "")
  local res = path:match("^e%s(~?/.-/)$")
  if not res then
    res = path:match("^e%s(~?/.-)$")
  end
  return res
end

-- idk why it doesn't rerender
local function update_cmdline()
  -- press space and then backspace to update cmdline
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(
    "<Space><Backspace>",
    true,
    true,
    true
  ), "n", true)
end

function M.complete()
  local cmdline = vim.fn.getcmdline()
  local path = extract_path(cmdline)
  if cmdline:match("%[.*%]") and not cmdline:match("%[" .. config.no_matches .. "%]$") then
    vim.fn.setcmdline("e "
      .. path:gsub("(.*/)[^/]*$", "%1")
      .. cmdline:match("%[%s(.*)%s%]")
    )
    update_cmdline()
  end
end

function M.predict()
  local cmdline = vim.fn.getcmdline()
  local path = extract_path(cmdline)
  local tree = ls(path:gsub("(.*/)[^/]*$", "%1"))
  local filtered = filter(tree, path:match("/([^/]*)$"))
  local formatted
  if #filtered == 0 then
    formatted = "[" .. config.no_matches .. "]"
  elseif #filtered == 1 then
    formatted = "[ " .. filtered[1] .. " ]"
  else
    formatted = format_paths(filtered, string.len("e " .. path))
  end
  vim.fn.setcmdline("e " .. path .. formatted, string.len("e " .. path .. " "))

  update_cmdline()
end

-- write an autocmd that make sure that when the user is in the cmdline, when they type :e ~/ it will trigger a function called cmdline_handler with the argument as the result of getcmdline
-- use the autocmd CmdlineChanged
-- function M.create_autocmd()
--   vim.api.nvim_create_autocmd( "CmdlineChanged", {
--     callback = function()
--       local cmdline = vim.fn.getcmdline()
--       if cmdline:match("^e%s~?/") then
--         handle_cmdline()
--       end
--     end
--   })
-- end

-- map handle_cmdline to <c-,> in the cmdline
vim.api.nvim_set_keymap("c", "<c-a>", "<cmd>lua require('ido').predict()<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("c", "<tab>", "<cmd>lua require('ido').complete()<cr>", { noremap = true, silent = true })

return M
