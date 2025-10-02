local config = require("data.config")
local actions = require("data.core.actions")
local hooks = require("data.core.hooks")
local state = require("data.core.state")
local commands = require("data.commands")
local datasource_registry = require("data.datasources.registry")

local M = {}

function M.setup(opts)
  opts = opts or {}
  config.setup(opts)
  vim.g.data_setup_completed = true
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

function M.edit(value, row, col)
  return actions.edit(nil, value, row, col)
end

function M.save(session)
  return actions.save(session or state.current())
end

function M.undo()
  return actions.undo(nil)
end

function M.redo()
  return actions.redo(nil)
end

function M.hscroll(delta)
  return actions.hscroll(nil, delta)
end

function M.mode(new_mode)
  if new_mode == "toggle" then
    return actions.toggle_mode(nil)
  end
  return actions.mode(nil, new_mode)
end

function M.toggle_mode()
  return actions.toggle_mode(nil)
end

function M.restore_sessions(opts)
  return actions.restore_sessions(opts)
end

function M.statusline()
  return require("data.ui.statusline").statusline_for_current()
end

function M.on(event, handler, opts)
  return hooks.register(event, handler, opts)
end

function M.once(event, handler)
  return hooks.register(event, handler, { once = true })
end

function M.clear_hooks()
  hooks.clear()
end

function M.register_datasource(name, adapter)
  return datasource_registry.register(name, adapter)
end

return M
