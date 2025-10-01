local config = require("data.config")
local layout = require("data.ui.layout")
local keymaps = require("data.keymaps")
local statusline = require("data.ui.statusline")

local M = {}

local namespace = vim.api.nvim_create_namespace("data.nvim.renderer")
local focus_namespace = vim.api.nvim_create_namespace("data.nvim.renderer.focus")

local function build_column_spans(layout_info)
  local spans = {}
  if not layout_info or not layout_info.widths then
    return spans
  end

  local gap = layout_info.separator_width or (layout_info.separator and #layout_info.separator) or 0
  local col_start = 0
  for index, width in ipairs(layout_info.widths) do
    spans[index] = { col_start, col_start + width }
    col_start = col_start + width + gap
  end

  return spans
end

local function resolve_column_highlight(palette, column_index, column_name)
  if not palette or type(palette) ~= "table" then
    return nil
  end

  if palette.by_name and column_name and palette.by_name[column_name] then
    return palette.by_name[column_name]
  end

  if palette.by_index and palette.by_index[column_index] then
    return palette.by_index[column_index]
  end

  if type(palette[column_index]) == "string" then
    return palette[column_index]
  end

  return palette.fallback or palette.default
end

local function ensure_buffer(session, opts)
  opts = opts or {}
  local bufnr = session.bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    session.bufnr = bufnr
  end

  if opts.enter then
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, bufnr)
  end

  return bufnr
end

local function apply_column_highlights(session, cfg, header_exists)
  local palette = cfg.theme and cfg.theme.column_palette
  if not palette then
    return
  end

  local layout_info = session.layout
  local spans = build_column_spans(layout_info)
  if #spans == 0 then
    return
  end

  local header = session.model.header
  local rows = session.model.rows or {}
  if #rows == 0 then
    return
  end

  local data_start = header_exists and 2 or 0
  for row_index, _ in ipairs(rows) do
    local line_nr = data_start + row_index - 1
    for column_index, span in ipairs(spans) do
      local group = resolve_column_highlight(palette, column_index, header and header[column_index])
      if group then
        vim.api.nvim_buf_add_highlight(session.bufnr, namespace, group, line_nr, span[1], span[2])
      end
    end
  end
end

local function apply_focus_highlight(session, cfg)
  vim.api.nvim_buf_clear_namespace(session.bufnr, focus_namespace, 0, -1)

  local rows = session.model.rows or {}
  if not rows or #rows == 0 then
    return
  end

  local cursor = session.cursor or { row = 1, col = 1 }
  local layout_info = session.layout
  if not layout_info then
    return
  end

  local spans = build_column_spans(layout_info)
  if #spans == 0 then
    return
  end

  local header_exists = session.model.header ~= nil
  local data_start = header_exists and 2 or 0
  local row = math.min(math.max(cursor.row or 1, 1), #rows)
  local col = math.min(math.max(cursor.col or 1, 1), #spans)
  local span = spans[col]
  local line_idx = data_start + (row - 1)

  local group = cfg.theme and cfg.theme.focused_cell or "Visual"
  vim.api.nvim_buf_add_highlight(session.bufnr, focus_namespace, group, line_idx, span[1], span[2])

  local wins = vim.fn.win_findbuf(session.bufnr)
  if wins and #wins > 0 then
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_cursor(win, { line_idx + 1, span[1] })
      end
    end
  end

  statusline.apply(session)
end

local function apply_highlights(session, cfg)
  local header_exists = session.model.header ~= nil
  local lines = session.rendered_lines or {}

  vim.api.nvim_buf_clear_namespace(session.bufnr, namespace, 0, -1)

  if header_exists and lines[1] then
    local hl = cfg.theme and cfg.theme.header or "Title"
    vim.api.nvim_buf_add_highlight(session.bufnr, namespace, hl, 0, 0, -1)
  end

  apply_column_highlights(session, cfg, header_exists)
  apply_focus_highlight(session, cfg)
end

function M.render(session, opts)
  opts = opts or {}
  local cfg = config.get()
  local rows = session.model.rows or {}
  local header = session.model.header
  local available_width = opts.available_width or vim.api.nvim_win_get_width(0)

  local layout_info = layout.measure(rows, {
    header = header,
    available_width = available_width,
    min_width = cfg.column_width and cfg.column_width.min,
    max_width = cfg.column_width and cfg.column_width.max,
  })

  local lines = layout.render(rows, layout_info, { header = header })
  session.layout = layout_info
  session.rendered_lines = lines

  local bufnr = ensure_buffer(session, { enter = opts.enter ~= false })
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  keymaps.apply(session)
  apply_highlights(session, cfg)

  return session
end

function M.focus(session)
  local cfg = config.get()
  if session.bufnr and vim.api.nvim_buf_is_valid(session.bufnr) then
    apply_focus_highlight(session, cfg)
  end
end

return M
