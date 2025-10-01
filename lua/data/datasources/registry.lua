local csv = require("data.datasources.csv")
local sqlite = require("data.datasources.sqlite")

local M = {}

local adapters = {}
local builtin = {
  csv = csv,
  sqlite = sqlite,
}

function M.register(name, adapter)
  if adapter.is_available and not adapter.is_available() then
    return false
  end
  adapters[name] = adapter
  adapter.name = adapter.name or name
  return true
end

function M.get(name)
  return adapters[name]
end

function M.resolve(source, opts)
  for _, adapter in pairs(adapters) do
    if not adapter.supports or adapter.supports(source, opts or {}) then
      return adapter
    end
  end
  return nil, string.format("no datasource registered for %s", source)
end

function M.bootstrap()
  for name, adapter in pairs(builtin) do
    M.register(name, adapter)
  end
end

return M
