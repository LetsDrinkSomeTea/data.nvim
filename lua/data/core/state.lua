local M = {}

local sessions = {}
local order = {}
local current_id

local function generate_id(source)
  local key = source or tostring(#order + 1)
  if not sessions[key] then
    return key
  end
  local suffix = 1
  while sessions[key .. ":" .. suffix] do
    suffix = suffix + 1
  end
  return key .. ":" .. suffix
end

local function snapshot()
  local items = {}
  for _, id in ipairs(order) do
    local session = sessions[id]
    if session then
      items[#items + 1] = {
        id = session.id,
        source = session.meta.source,
        adapter = session.meta.adapter,
        table = session.model.table,
        current = current_id == session.id,
      }
    end
  end
  return items
end

local function storage_path()
  local ok, dir = pcall(vim.fn.stdpath, "data")
  if not ok then
    return nil
  end
  local target = dir .. "/data.nvim"
  local mkdir_ok = pcall(vim.fn.mkdir, target, "p")
  if not mkdir_ok then
    return nil
  end
  return target .. "/sessions.json"
end

local function persist_sessions()
  local path = storage_path()
  if not path then
    vim.notify_once("data.nvim: unable to persist sessions (no writable data path)", vim.log.levels.WARN)
    return
  end

  local ok, encoded = pcall(vim.json.encode, snapshot())
  if not ok then
    vim.notify_once("data.nvim: failed to encode sessions for persistence", vim.log.levels.WARN)
    return
  end
  local write_ok = pcall(vim.fn.writefile, { encoded }, path)
  if not write_ok then
    vim.notify_once("data.nvim: unable to write session snapshot", vim.log.levels.WARN)
  end
end

local function set_current(id)
  current_id = id
  persist_sessions()
end

function M.attach(model, opts)
  local meta = opts or {}
  local id = generate_id(meta.source)
  local session = {
    id = id,
    model = model,
    meta = meta,
    cursor = { row = 1, col = 1 },
    view = { top = 1 },
    dirty = false,
  }
  sessions[id] = session
  order[#order + 1] = id
  set_current(id)
  return session
end

function M.get(id)
  return sessions[id]
end

function M.current()
  return current_id and sessions[current_id] or nil
end

function M.set_current(id)
  if sessions[id] then
    set_current(id)
  end
end

function M.for_buf(bufnr)
  for _, session in pairs(sessions) do
    if session.bufnr == bufnr then
      return session
    end
  end
  return nil
end

function M.list()
  local items = {}
  for _, id in ipairs(order) do
    local session = sessions[id]
    if session then
      items[#items + 1] = session
    end
  end
  return items
end

function M.record_dirty(session, dirty)
  session.dirty = dirty or false
end

function M.sessions()
  return sessions
end

function M.clear()
  sessions = {}
  order = {}
  current_id = nil
  persist_sessions()
end

function M.persist_snapshot()
  persist_sessions()
end

return M
