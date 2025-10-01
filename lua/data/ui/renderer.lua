local config = require("data.config")
local layout = require("data.ui.layout")

local M = {}

local namespace = vim.api.nvim_create_namespace("data.nvim.renderer")

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

local function apply_highlights(bufnr, lines, cfg, header_exists)
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  if header_exists and lines[1] then
    local hl = cfg.theme and cfg.theme.header or "Title"
    vim.api.nvim_buf_add_highlight(bufnr, namespace, hl, 0, 0, -1)
  end
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
  apply_highlights(bufnr, lines, cfg, header ~= nil)

  return session
end

return M
