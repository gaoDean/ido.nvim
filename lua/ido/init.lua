local config = require("ido.config")

local M = {}

local function snake_to_pascal_case(snake_str)
  snake_str = snake_str:gsub("^(%l)", function (l) return l:upper() end, 1)
  return snake_str:gsub("_(%l)", function (l) return l:upper() end)
end

M.setup = function(opts)
  config.update(opts)
  for k, v in pairs(require("ido.ido")) do
    M[k] = v
    vim.cmd("command! "
      .. "Ido"
      .. snake_to_pascal_case(k)
      .. " lua require('ido')."
      .. k
      .. "()")
  end
end

return M
