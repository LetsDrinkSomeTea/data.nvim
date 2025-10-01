local M = {}

local sessions = {}

local function generate_id(source)
  local key = source or tostring(#sessions + 1)
  if not sessions[key] then
    return key
  end
  local suffix = 1
  while sessions[key .. ":" .. suffix] do
    suffix = suffix + 1
  end
  return key .. ":" .. suffix
end

function M.attach(model, opts)
  local meta = opts or {}
  local id = generate_id(meta.source)
  local session = {
    id = id,
    model = model,
    meta = meta,
  }
  sessions[id] = session
  return session
end

function M.sessions()
  return sessions
end

function M.clear()
  sessions = {}
end

return M
