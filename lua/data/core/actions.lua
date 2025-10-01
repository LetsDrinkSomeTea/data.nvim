local config = require("data.config")
local state = require("data.core.state")
local hooks = require("data.core.hooks")
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
  session.view = session.view or { top = 1, leftcol = 0 }
  session.view.top = session.view.top or 1
  session.view.leftcol = session.view.leftcol or 0
  local rows = session.model.rows or {}
  local max_row = math.max(#rows, 1)
  local max_column = column_count(session)
  session.cursor.row = clamp(session.cursor.row, 1, max_row)
  session.cursor.col = clamp(session.cursor.col, 1, max_column)
  session.view.top = session.cursor.row
end

local apply_view_mode

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

local function resolve_mode(mode)
  local cfg = config.get()
  local modes_cfg = (cfg.view and cfg.view.modes) or {}
  local fallback = (cfg.view and cfg.view.default_mode) or "compact"
  local name = mode or fallback
  if not modes_cfg[name] then
    name = fallback
  end
  local view_opts = vim.tbl_deep_extend("force", {}, modes_cfg[name] or {})
  view_opts.mode = name
  return name, view_opts
end

function M.bootstrap()
  registry.bootstrap()
  local cfg = config.get()
  if cfg.datasources then
    local custom = cfg.datasources.registry
    if cfg.datasources.register and next(cfg.datasources.register) then
      custom = cfg.datasources.register
    end
    if custom then
      cfg.datasources.registry = custom
      cfg.datasources.register = nil
      for name, adapter in pairs(custom) do
        registry.register(name, adapter)
      end
    end
  end
  M.restore_sessions({ enter = false })
end

function M.open(source, opts)
  assert(source, "data.nvim: source is required")
  local load_opts = opts or {}

  local adapter
  local err
  if load_opts.adapter then
    adapter = registry.get(load_opts.adapter)
    if not adapter then
      err = string.format("adapter '%s' is not registered", load_opts.adapter)
    elseif adapter.supports and not adapter.supports(source, load_opts) then
      err = string.format("adapter '%s' cannot handle %s", load_opts.adapter, source)
      adapter = nil
    end
  else
    adapter, err = registry.resolve(source, load_opts)
  end
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
    mode = load_opts.mode,
  }

  local session = state.attach(model, meta)
  session.meta.table = session.meta.table or session.model.table
  local mode_name, view_opts = resolve_mode(load_opts.mode or session.mode)
  session.mode = mode_name
  local render_opts = vim.tbl_deep_extend("force", {}, view_opts, load_opts)
  renderer.render(session, render_opts)
  state.persist_snapshot()
  hooks.emit("TableOpened", {
    session = session,
    source = session.meta.source,
    adapter = session.meta.adapter,
    mode = session.mode,
  })
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
      table = session.meta.table or session.model.table,
      bufnr = session.bufnr,
      current = current and current.id == session.id,
      cursor = session.cursor,
      mode = session.mode,
    }
  end
  return entries
end

function M.switch(id, opts)
  local session = resolve_session(id)
  state.set_current(session.id)

  if not session.bufnr or not vim.api.nvim_buf_is_valid(session.bufnr) then
    apply_view_mode(session, session.mode, opts)
    return session
  end

  local win = (opts and opts.win) or vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, session.bufnr)
  apply_view_mode(session, session.mode, vim.tbl_extend("force", { enter = false }, opts or {}))
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
  state.persist_snapshot()
  hooks.emit("TableSaved", {
    session = session,
    source = session.meta.source,
    adapter = session.meta.adapter,
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
  session.view = session.view or { top = 1, leftcol = 0 }
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
  local rows = session.model.rows or {}
  local cursor = update_cursor(session, (delta or 1) * step, 0)
  session.view.top = clamp(cursor.row - math.floor(height / 2), 1, math.max(#rows, 1))
  apply_view_mode(session, session.mode, { enter = false })
  return cursor
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

apply_view_mode = function(session, mode, extra_opts)
  local name, view_opts = resolve_mode(mode or session.mode)
  session.mode = name
  local render_opts = vim.tbl_deep_extend("force", {}, view_opts, extra_opts or {})
  if render_opts.wrap then
    session.view.leftcol = 0
  end
  renderer.render(session, render_opts)
  state.persist_snapshot()
  hooks.emit("ViewModeChanged", {
    session = session,
    mode = session.mode,
  })
  return session.mode
end

function M.mode(session_or_id, new_mode)
  local session = resolve_session(session_or_id)
  if not new_mode then
    return session.mode
  end
  return apply_view_mode(session, new_mode)
end

function M.toggle_mode(session_or_id)
  local session = resolve_session(session_or_id)
  local cfg = config.get()
  local modes = cfg.view and cfg.view.modes or {}
  local keys = {}
  for key in pairs(modes) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  if #keys == 0 then
    return session.mode
  end

  local current = session.mode or cfg.view.default_mode or keys[1]
  local index = 1
  for i, key in ipairs(keys) do
    if key == current then
      index = i
      break
    end
  end
  local next_index = (index % #keys) + 1
  return apply_view_mode(session, keys[next_index])
end

local function apply_change(session, change, direction)
  if change.type == "cell" then
    local row = change.row
    local col = change.col
    local rows = session.model.rows or {}
    if not rows[row] then
      rows[row] = {}
    end
    if direction == "undo" then
      rows[row][col] = change.before
    else
      rows[row][col] = change.after
    end
  end
end

function M.edit(session_or_id, value, row, col)
  local session = resolve_session(session_or_id)
  ensure_cursor(session)
  local rows = session.model.rows or {}
  if not rows or #rows == 0 then
    error("data.nvim: no rows loaded")
  end

  local target_row = row or session.cursor.row
  local target_col = col or session.cursor.col

  if target_row < 1 or target_row > #rows then
    error("data.nvim: row out of range")
  end

  rows[target_row] = rows[target_row] or {}
  while #rows[target_row] < target_col do
    rows[target_row][#rows[target_row] + 1] = ""
  end

  local previous = rows[target_row][target_col]
  rows[target_row][target_col] = value

  state.record_change(session, {
    type = "cell",
    row = target_row,
    col = target_col,
    before = previous,
    after = value,
  })

  apply_view_mode(session, session.mode, { enter = false })
  hooks.emit("CellEdited", {
    session = session,
    row = target_row,
    col = target_col,
    before = previous,
    after = value,
  })
  return rows[target_row][target_col]
end

function M.undo(session_or_id)
  local session = resolve_session(session_or_id)
  local change = state.undo_change(session)
  if not change then
    return false
  end
  apply_change(session, change, "undo")
  apply_view_mode(session, session.mode, { enter = false })
  hooks.emit("UndoApplied", {
    session = session,
    change = change,
  })
  return true
end

function M.redo(session_or_id)
  local session = resolve_session(session_or_id)
  local change = state.redo_change(session)
  if not change then
    return false
  end
  apply_change(session, change, "redo")
  apply_view_mode(session, session.mode, { enter = false })
  hooks.emit("RedoApplied", {
    session = session,
    change = change,
  })
  return true
end

function M.hscroll(session_or_id, delta)
  local session = resolve_session(session_or_id)
  session.view = session.view or { top = 1, leftcol = 0 }
  local cfg = config.get()
  local step = delta
  if step == nil then
    step = cfg.view and cfg.view.scroll_columns or 8
  end
  session.view.leftcol = math.max((session.view.leftcol or 0) + step, 0)
  apply_view_mode(session, session.mode, { enter = false })
  hooks.emit("ViewportChanged", {
    session = session,
    leftcol = session.view.leftcol,
    top = session.view.top,
  })
  return session.view.leftcol
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
          mode = entry.mode,
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
