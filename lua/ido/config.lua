local default_config = {
  num_results = 5,
  prompt = "Find file: ",
  ls_flags = "",
  max_paths = 10,
  no_matches = "No Matches",
  highlights = {
    prompt = "Bold",
    matches = "IncSearch",
  }
}

local M = vim.deepcopy(default_config)

M.update = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	if not newconf.enabled then return end

	for k, v in pairs(newconf) do
		M[k] = v
	end
end

return M
