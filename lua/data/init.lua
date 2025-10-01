local config = require("data.config")
local actions = require("data.core.actions")

local M = {}

function M.setup(opts)
  config.setup(opts)
  actions.bootstrap()
end

function M.open(source, opts)
  return actions.open(source, opts)
end

return M
