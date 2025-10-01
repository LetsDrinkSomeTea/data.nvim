local config = require("data.config")
local state = require("data.core.state")
local registry = require("data.datasources.registry")
local renderer = require("data.ui.renderer")

local M = {}

function M.bootstrap()
  registry.bootstrap()
end

function M.open(source, opts)
  assert(source, "data.nvim: source is required")
  local adapter, err = registry.resolve(source, opts)
  if not adapter then
    error(string.format("data.nvim: %s", err))
  end

  local load_opts = opts or {}
  local model = adapter.load(source, load_opts)
  local session = state.attach(model, { source = source, adapter = adapter.name })
  renderer.render(session, load_opts)
  return session
end

function M.save(session)
  local cfg = config.get()
  local adapter = registry.get(session.meta.adapter)
  if not adapter then
    error("data.nvim: adapter not available for save")
  end
  adapter.save(session.model, {
    source = session.meta.source,
    config = cfg,
  })
end

return M
