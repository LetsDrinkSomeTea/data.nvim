local M = {}

local registry = {}

local function ensure_list(event)
  registry[event] = registry[event] or {}
  return registry[event]
end

function M.register(event, handler, opts)
  assert(type(event) == "string", "data.nvim hooks: event must be string")
  assert(type(handler) == "function", "data.nvim hooks: handler must be callable")
  local list = ensure_list(event)
  list[#list + 1] = { fn = handler, once = opts and opts.once }
  return function()
    for index, item in ipairs(list) do
      if item.fn == handler then
        table.remove(list, index)
        break
      end
    end
  end
end

function M.emit(event, payload)
  local list = registry[event]
  if not list then
    return
  end
  local survivors = {}
  for _, item in ipairs(list) do
    local ok, err = pcall(item.fn, payload)
    if not ok then
      vim.schedule(function()
        vim.notify(string.format("data.nvim hook '%s' error: %s", event, err), vim.log.levels.ERROR)
      end)
    end
    if not item.once then
      survivors[#survivors + 1] = item
    end
  end
  registry[event] = survivors
end

function M.clear()
  registry = {}
end

function M.list(event)
  return registry[event]
end

return M
