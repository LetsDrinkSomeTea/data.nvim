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
  local cfg = require("data.config").get()
  local priority = cfg.datasources and cfg.datasources.priority or {}
  local checked = {}

  local function consider(candidate)
    if candidate and not checked[candidate] then
      checked[candidate] = true
      local adapter = adapters[candidate]
      if adapter and (not adapter.supports or adapter.supports(source, opts or {})) then
        return adapter
      end
    end
    return nil
  end

  for _, name in ipairs(priority) do
    local adapter = consider(name)
    if adapter then
      return adapter
    end
  end
  for name in pairs(adapters) do
    local adapter = consider(name)
    if adapter then
      return adapter
    end
  end
  return nil, string.format("no datasource registered for %s", source)
end

function M.bootstrap()
  adapters = {}
  for name, adapter in pairs(builtin) do
    M.register(name, adapter)
  end
end

return M
