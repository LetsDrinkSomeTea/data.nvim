local M = {}

local sessions = {}
local order = {}
local current_id
local custom_storage_path

local function generate_id(source)
  local base = source or tostring(#order + 1)
  if not sessions[base] then
    return base
  end
  local suffix = 1
  while sessions[string.format("%s:%d", base, suffix)] do
    suffix = suffix + 1
  end
  return string.format("%s:%d", base, suffix)
end

local function remove_from_order(id)
  for index, value in ipairs(order) do
    if value == id then
      table.remove(order, index)
      return
    end
  end
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
        table = session.model.table or session.meta.table,
        cursor = session.cursor,
        view = session.view,
        mode = session.mode,
        current = current_id == session.id,
        dirty = session.dirty,
      }
    end
  end
  return items
end

function M.override_storage_path(path)
  custom_storage_path = path
end

local function storage_path()
  if custom_storage_path ~= nil then
    if not custom_storage_path or custom_storage_path == false then
      return nil
    end
    local dir = vim.fn.fnamemodify(custom_storage_path, ":h")
    pcall(vim.fn.mkdir, dir, "p")
    return custom_storage_path
  end

  if vim.g.data_nvim_session_file then
    local dir = vim.fn.fnamemodify(vim.g.data_nvim_session_file, ":h")
    pcall(vim.fn.mkdir, dir, "p")
    return vim.g.data_nvim_session_file
  end

  local ok, base = pcall(vim.fn.stdpath, "state")
  if not ok or not base or base == "" then
    ok, base = pcall(vim.fn.stdpath, "data")
    if not ok or not base or base == "" then
      return nil
    end
  end

  local target_dir = base .. "/data.nvim"
  if not pcall(vim.fn.mkdir, target_dir, "p") then
    return nil
  end
  return target_dir .. "/sessions.json"
end

local function persist_sessions()
  local path = storage_path()
  if not path then
    return
  end

  local ok, encoded = pcall(vim.json.encode, snapshot())
  if not ok then
    vim.notify_once("data.nvim: failed to encode sessions for persistence", vim.log.levels.WARN)
    return
  end

  local write_ok, err = pcall(vim.fn.writefile, { encoded }, path, "b")
  if not write_ok then
    vim.notify_once("data.nvim: unable to write session snapshot: " .. tostring(err), vim.log.levels.WARN)
  end
end

local function set_current(id)
  current_id = id
  persist_sessions()
end

function M.attach(model, meta)
  meta = meta and vim.deepcopy(meta) or {}
  local requested_id = meta.id
  if requested_id and sessions[requested_id] then
    remove_from_order(requested_id)
  end

  local id = requested_id or generate_id(meta.source or (model and model.source))
  meta.id = id
  meta.table = meta.table or (model and model.table)

  local mode = meta.mode or meta.view_mode or (meta.view and meta.view.mode)

  meta.view = meta.view or {}
  meta.view.top = meta.view.top or 1
  meta.view.leftcol = meta.view.leftcol or 0

  local session = {
    id = id,
    model = model,
    meta = meta,
    cursor = meta.cursor and vim.deepcopy(meta.cursor) or { row = 1, col = 1 },
    view = vim.deepcopy(meta.view),
    mode = mode or nil,
    dirty = meta.dirty or false,
    bufnr = meta.bufnr,
    history = meta.history and vim.deepcopy(meta.history) or { past = {}, future = {} },
  }

  sessions[id] = session
  remove_from_order(id)
  order[#order + 1] = id

  if meta.activate == nil or meta.activate then
    set_current(id)
  else
    persist_sessions()
  end

  return session
end

function M.get(id)
  return sessions[id]
end

function M.current()
  if current_id then
    return sessions[current_id]
  end
  return nil
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
  session.dirty = not not dirty
  persist_sessions()
end

local function ensure_history(session)
  session.history = session.history or { past = {}, future = {} }
  session.history.past = session.history.past or {}
  session.history.future = session.history.future or {}
  return session.history
end

function M.record_change(session, change)
  local history = ensure_history(session)
  history.past[#history.past + 1] = change
  history.future = {}
  session.dirty = true
  persist_sessions()
end

function M.undo_change(session)
  local history = ensure_history(session)
  local change = table.remove(history.past)
  if not change then
    return nil
  end
  history.future[#history.future + 1] = change
  session.dirty = #history.past > 0
  persist_sessions()
  return change
end

function M.redo_change(session)
  local history = ensure_history(session)
  local change = table.remove(history.future)
  if not change then
    return nil
  end
  history.past[#history.past + 1] = change
  session.dirty = true
  persist_sessions()
  return change
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

function M.load_snapshot()
  local path = storage_path()
  if not path or vim.fn.filereadable(path) == 0 then
    return {}
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines or #lines == 0 then
    return {}
  end

  local raw = table.concat(lines, "\n")
  local decode_ok, data = pcall(vim.json.decode, raw)
  if not decode_ok or type(data) ~= "table" then
    return {}
  end

  return data
end

function M.snapshot()
  return snapshot()
end

return M
