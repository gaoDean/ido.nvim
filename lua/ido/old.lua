local window = require("ido.window")
local config = require("ido.config")

local M = {}

-- TODO: isdir doesn't work

local function filter(paths, search)
  local mapped = vim.tbl_map(function(path)
    local startIndex, endIndex
    if search:lower() == search then
      startIndex, endIndex = (path:lower()):find(search)
    else
      startIndex, endIndex = path:find(search)
    end
    return {
      startIndex = startIndex,
      endIndex = endIndex,
      path = " " .. path
    }
  end, paths)
  return vim.tbl_filter(function(path)
    return path.startIndex and path.endIndex and path
  end, mapped)
end

local function handleSearch()

end

-- write a function that takes a directory, and returns the output of "ls" in table form
-- if the path is a directory, then append "/" at the end (ls doesn't append it by itself)
local function ls(path)
  local output = vim.fn.systemlist("ls " .. path)
  local mapped = vim.tbl_map(function(newpath)
    if vim.fn.isdirectory(path:gsub("~", vim.env.HOME) .. newpath) > 0 then
      return newpath .. "/"
    else
      return newpath
    end
  end, output)
  return mapped
end

local function render(buf, ns, files, search)
  local result = filter(files, search)

  while #result > config.num_results do
    table.remove(result, #result)
  end

  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    vim.tbl_map(function(path) return path.path end, result)
  )

  for i, res in ipairs(result) do
    vim.api.nvim_buf_add_highlight(
      buf,
      ns,
      config.highlights.matches,
      i - 1,
      result[i].startIndex,
      result[i].endIndex + 1
    )
  end
end

local function create_win()

  local winresults = window.new_window("TaperFindFilesResults", {
    style = "minimal",
    relative = "editor",
    row = vim.o.lines,
    col = 0,
    width = vim.o.columns,
    height = config.num_results,
  }, false)

  local winprompt = window.new_window("TaperFindFilesPrompt", {
    style = "minimal",
    relative = "editor",
    row = vim.o.lines - config.num_results - 2,
    col = 0,
    width = config.prompt:len() + 1,
    height = 1,
  }, false)

  local winsearch = window.new_window("TaperFindFilesSearch", {
    style = "minimal",
    relative = "editor",
    row = vim.o.lines - config.num_results - 2,
    col = config.prompt:len() + 1,
    width = vim.o.columns - config.prompt:len() - 1,
    height = 1,
  }, true)

  window.bind_autoclose(winsearch, winprompt, winresults)

  return {
    winresults = winresults,
    winprompt = winprompt,
    winsearch = winsearch
  }
end

function M.match_files()

  data = create_win()

  local cur_dir = "~/org/"

  ns = vim.api.nvim_create_namespace("")
  vim.api.nvim_buf_set_lines(data.winprompt.buf, 0, 1, false, {" " .. config.prompt})
  vim.api.nvim_buf_set_lines(data.winsearch.buf, 0, 1, false, {cur_dir})
	vim.api.nvim_buf_add_highlight(data.winprompt.buf, ns, config.highlights.prompt, 0, 0, -1)

  vim.api.nvim_create_autocmd({"CursorMoved", "TextChangedI" }, {
    buffer = data.winsearch.buf,
    callback = function()
      local cur_path = vim.fn.getline(1)
      render(
        data.winresults.buf,
        ns,
        ls(cur_path:gsub("/[^/]*$", "/")),
        cur_path:gsub("^" .. cur_dir, "")
      );

      local last_char = cur_path:sub(-1)
      local first_line = vim.api.nvim_buf_get_lines(data.winresults.buf, 0, 1, false)[1]
      print(first_line, "test", last_char, cur_path, cur_dir)
      if last_char == "/" and cur_path ~= cur_dir then
        cur_dir = cur_dir .. first_line
        vim.api.nvim_buf_set_lines(data.winsearch.buf, 0, 1, false, {cur_dir})
        vim.api.nvim_buf_set_lines(data.winresults.buf, 0, -1, false, {})
      end
    end
  })

  vim.api.nvim_feedkeys("A", "n", false)
end

-- run vim.fn.getcmdline after 2 seconds delay and write it to ~/test.txt
-- vim.defer_fn(function()
--   local cmd = vim.fn.getcmdline()
--   local file = io.open("/Users/deangao/test.txt", "w")
--   file:write(cmd)
--   file:close()
-- end, 2000)

-- run match_files when the text in the command line has changed
-- vim.api.nvim_exec([[
--   augroup TaperFindFiles
--     autocmd!
--     autocmd CmdlineChanged * lua require("ido").match_files()
--   augroup END
-- ]], false)

return M
