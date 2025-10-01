local config = require("data.config")
local state = require("data.core.state")
local registry = require("data.datasources.registry")
local renderer = require("data.ui.renderer")

local M = {}

local function clamp(value, min_value, max_value)
  if min_value and value < min_value then
    value = min_value
  end
  if max_value and value > max_value then
    value = max_value
  end
  return value
end

local function column_count(session)
  if session.layout and session.layout.columns then
    return math.max(session.layout.columns, 1)
  end
  local header = session.model.header or {}
  if #header > 0 then
    return #header
  end
  local rows = session.model.rows or {}
  local max_columns = 0
  for _, row in ipairs(rows) do
    if #row > max_columns then
      max_columns = #row
    end
  end
  return math.max(max_columns, 1)
end

local function ensure_cursor(session)
  session.cursor = session.cursor or { row = 1, col = 1 }
  local rows = session.model.rows or {}
  local max_row = math.max(#rows, 1)
  local max_column = column_count(session)
  session.cursor.row = clamp(session.cursor.row, 1, max_row)
  session.cursor.col = clamp(session.cursor.col, 1, max_column)
end

local function update_cursor(session, delta_row, delta_col)
  ensure_cursor(session)
  session.cursor.row = session.cursor.row + (delta_row or 0)
  session.cursor.col = session.cursor.col + (delta_col or 0)
  ensure_cursor(session)
  renderer.focus(session)
  return session.cursor
end

local function resolve_session(session_or_id)
  if session_or_id == nil then
    local current = state.current()
    assert(current, "data.nvim: no active session")
    return current
  end
  if type(session_or_id) == "table" then
    return session_or_id
  end
  local session = state.get(session_or_id)
  assert(session, string.format("data.nvim: unknown session '%s'", tostring(session_or_id)))
  return session
end

function M.bootstrap()
  registry.bootstrap()
  M.restore_sessions({ enter = false })
end

function M.open(source, opts)
  assert(source, "data.nvim: source is required")
  local load_opts = opts or {}

  local adapter, err = registry.resolve(source, load_opts)
  if not adapter then
    error(string.format("data.nvim: %s", err))
  end

  local model = adapter.load(source, load_opts)
  local meta = {
    source = source,
    adapter = adapter.name,
    table = load_opts.table,
    id = load_opts.id,
    activate = load_opts.activate,
    cursor = load_opts.cursor,
    view = load_opts.view,
  }

  local session = state.attach(model, meta)
  session.meta.table = session.meta.table or session.model.table
  renderer.render(session, load_opts)
  return session
end

function M.list_sessions()
  local entries = {}
  local current = state.current()
  for _, session in ipairs(state.list()) do
    entries[#entries + 1] = {
      id = session.id,
      source = session.meta.source,
      adapter = session.meta.adapter,
      table = session.model.table,
      bufnr = session.bufnr,
      current = current and current.id == session.id,
      cursor = session.cursor,
    }
  end
  return entries
end

function M.switch(id, opts)
  local session = resolve_session(id)
  state.set_current(session.id)

  if not session.bufnr or not vim.api.nvim_buf_is_valid(session.bufnr) then
    renderer.render(session, opts or {})
    return session
  end

  local win = (opts and opts.win) or vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, session.bufnr)
  renderer.focus(session)
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

function M.move(session_or_id, direction, count)
  local session = resolve_session(session_or_id)
  local step = math.max(count or 1, 1)

  if direction == "up" then
    return update_cursor(session, -step, 0)
  elseif direction == "down" then
    return update_cursor(session, step, 0)
  elseif direction == "left" then
    return update_cursor(session, 0, -step)
  elseif direction == "right" then
    return update_cursor(session, 0, step)
  end

  error(string.format("data.nvim: unknown navigation direction '%s'", tostring(direction)))
end

function M.page(session_or_id, delta)
  local session = resolve_session(session_or_id)
  local wins = vim.fn.win_findbuf(session.bufnr or -1)
  local win = vim.api.nvim_get_current_win()
  if wins and #wins > 0 then
    for _, candidate in ipairs(wins) do
      if vim.api.nvim_win_is_valid(candidate) then
        win = candidate
        break
      end
    end
  end

  local height = vim.api.nvim_win_get_height(win)
  local step = math.max(height - 3, 1)
  return update_cursor(session, (delta or 1) * step, 0)
end

function M.jump(session_or_id, row, col)
  local session = resolve_session(session_or_id)
  session.cursor = session.cursor or { row = 1, col = 1 }
  session.cursor.row = row or session.cursor.row
  session.cursor.col = col or session.cursor.col
  ensure_cursor(session)
  renderer.focus(session)
  return session.cursor
end

function M.restore_sessions(opts)
  if next(state.sessions()) then
    return {}
  end

  local restored = {}
  local target_current
  for _, entry in ipairs(state.load_snapshot()) do
    local adapter = registry.get(entry.adapter)
    if adapter then
      local ok, session = pcall(function()
        return M.open(entry.source, vim.tbl_extend("force", {
          id = entry.id,
          table = entry.table,
          cursor = entry.cursor,
          view = entry.view,
          activate = false,
          enter = false,
          restore = true,
        }, opts or {}))
      end)
      if ok and session then
        restored[#restored + 1] = session
        if entry.current then
          target_current = session.id
        end
      else
        local reason = session
        vim.notify(string.format("data.nvim: failed to restore %s (%s)", entry.source, tostring(reason)), vim.log.levels.WARN)
      end
    else
      vim.notify(string.format("data.nvim: adapter '%s' unavailable for %s", entry.adapter or "?", entry.source or "?"), vim.log.levels.WARN)
    end
  end

  if target_current then
    state.set_current(target_current)
    local current = state.get(target_current)
    if current then
      renderer.focus(current)
    end
  end

  return restored
end

return M
