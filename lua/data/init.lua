local config = require("data.config")
local actions = require("data.core.actions")
local commands = require("data.commands")

local M = {}

function M.setup(opts)
  opts = opts or {}
  config.setup(opts)
  actions.bootstrap()
  if opts.commands ~= false then
    commands.setup(opts.commands)
  end
end

function M.open(source, opts)
  return actions.open(source, opts)
end

function M.switch(id, opts)
  return actions.switch(id, opts)
end

function M.sessions()
  return actions.list_sessions()
end

function M.move(direction, count)
  return actions.move(nil, direction, count)
end

function M.page(delta)
  return actions.page(nil, delta)
end

function M.jump(row, col)
  return actions.jump(nil, row, col)
end

function M.restore_sessions(opts)
  return actions.restore_sessions(opts)
end

function M.statusline()
  return require("data.ui.statusline").statusline_for_current()
end

return M
