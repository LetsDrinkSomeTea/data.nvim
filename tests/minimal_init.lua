local current = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(current, ":p:h:h")
local deps = root .. "/tests/.deps"
local plenary = deps .. "/plenary.nvim"

vim.opt.runtimepath:append(root)
if vim.fn.isdirectory(plenary) == 1 then
  vim.opt.runtimepath:append(plenary)
end

local session_dir = root .. "/.test-data"
vim.fn.mkdir(session_dir, "p")
vim.g.data_nvim_session_file = session_dir .. "/sessions.json"

vim.g.loaded_perl_provider = 0
vim.g.loaded_python_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

return {}
