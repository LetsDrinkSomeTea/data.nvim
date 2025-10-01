local config = require("data.config")
local state = require("data.core.state")

local M = {}

local function buffer_for_session(session)
  return session and session.bufnr
end

local function column_name(session, column_index)
  local header = session.model and session.model.header
  if header and header[column_index] then
    return header[column_index]
  end
  return string.format("C%d", column_index)
end

local function row_counts(session)
  local rows = session.model and session.model.rows or {}
  return #rows
end

local function session_label(session)
  if session.meta and session.meta.table and session.meta.table ~= "" then
    return session.meta.table
  end
  if session.meta and session.meta.source then
    return vim.fn.fnamemodify(session.meta.source, ":t")
  end
  return session.id or "table"
end

function M.format_status(session)
  local cfg = config.get()
  if cfg.statusline and cfg.statusline.enabled == false then
    return ""
  end

  local cursor = session.cursor or { row = 1, col = 1 }
  local total_rows = row_counts(session)
  local col_name = column_name(session, cursor.col or 1)
  local template = (cfg.statusline and cfg.statusline.format) or "[%s] Row %d/%d · Col %d (%s)"
  return string.format(template, session_label(session), cursor.row or 1, total_rows, cursor.col or 1, col_name)
end

function M.apply(session)
  local cfg = config.get()
  if cfg.statusline and cfg.statusline.enabled == false then
    return
  end

  local bufnr = buffer_for_session(session)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local status_text = M.format_status(session)
  vim.b[bufnr].data_statusline = status_text
end

function M.statusline_for_current()
  local session = state.for_buf(vim.api.nvim_get_current_buf())
  if not session then
    return ""
  end
  return M.format_status(session)
end

return M
