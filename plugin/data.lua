if vim.g.data_auto_setup == false then
  return
end

local ok, data = pcall(require, "data")
if not ok then
  return
end

if not vim.g.data_setup_completed then
  data.setup()
end
