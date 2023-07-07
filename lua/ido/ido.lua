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

local function display_paths(paths, threshold)
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

-- turn the output of display_paths back into a table
local function parse_paths(text)
  local paths = {text:match("%{%s(.-)%s|")}
  for path in text:gmatch("|%s(.-)%s|") do
    table.insert(paths, path)
  end
  if not text:match("|%s...%s%}") then
    table.insert(paths, text:match("|%s(.-)%s%}"))
  end
  return paths
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

local function update_msgarea()
  vim.defer_fn(function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(
      "<esc>:<up>",
      true,
      true,
      true
    ), "t", true)
  end, 1)
end

function M.complete(opts)
  local cmdline = vim.fn.getcmdline()
  if not cmdline:match("^e%s~?/") then
    if opts and opts.tab then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(
        "<c-z>",
        true,
        true,
        true
      ), "n", true)
    end
    return
  end
  local path = extract_path(cmdline)
  local newdir = ""
  if cmdline:match("%[.*%]$") and not cmdline:match("%[" .. config.no_matches .. "%s$") then
    newdir = cmdline:match("%[(.*)%]")
  elseif cmdline:match("%{.*%}$") then
    local parsed_paths = parse_paths(cmdline:match("%{.*%}$"))
    for i, parsed_path in ipairs(parsed_paths) do
      parsed_paths[i] = i .. ") " .. parsed_path
    end
    local path_index = vim.fn.inputlist({ "Select a path:", unpack(parsed_paths) })
    update_msgarea()
    if path_index == 0 then return end
    newdir = parsed_paths[path_index]:match("%d%)%s(.*)")
  end
  log(newdir)
  vim.fn.setcmdline("e " .. path:gsub("(.*/)[^/]*$", "%1") .. newdir)
  update_cmdline()
end

function M.predict()
  local cmdline = vim.fn.getcmdline()
  if not cmdline:match("^e%s~?/") then return end
  local path = extract_path(cmdline)
  if path == last_path then return end
  last_path = path
  local tree = ls(path:gsub("(.*/)[^/]*$", "%1"))
  local filtered = filter(tree, path:match("/([^/]*)$"))
  local display_path = ""
  if #filtered == 0 then
    display_path = "[" .. config.no_matches .. "]"
  elseif #filtered == 1 then
    if filtered[1]:match("/$") or filtered[1] ~= path:match("/([^/]*)$") then
      display_path = "[" .. filtered[1] .. "]"
    end
  else
    display_path = display_paths(filtered, string.len("e " .. path))
  end

  vim.fn.setcmdline("e " .. path .. display_path, string.len("e " .. path .. " "))
  update_cmdline()
end

-- write an autocmd that make sure that when the user is in the cmdline, when they type :e ~/ it will trigger a function called cmdline_handler with the argument as the result of getcmdline
-- use the autocmd CmdlineChanged
function M.create_autocmd()
  vim.api.nvim_create_autocmd( "CmdlineChanged", {
    callback = function()
      vim.defer_fn(function()
        M.predict()
      end, 20)
    end
  })
end

vim.api.nvim_set_keymap("c", "<c-a>", "<cmd>lua require('ido').predict()<cr>", {noremap = true})
vim.api.nvim_set_keymap("c", "<tab>", "<cmd>lua require('ido').complete({tab = true})<cr>", {noremap = true})

return M
