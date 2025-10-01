local config = require("data.config")
local state = require("data.core.state")

local M = {}

local applied = {}

local function map(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer = bufnr,
    silent = true,
    nowait = true,
    desc = desc,
  })
end

local function default_maps(bufnr)
  local data = require("data")

  map(bufnr, "n", "j", function()
    data.move("down")
  end, "data.nvim: move down")

  map(bufnr, "n", "k", function()
    data.move("up")
  end, "data.nvim: move up")

  map(bufnr, "n", "h", function()
    data.move("left")
  end, "data.nvim: move left")

  map(bufnr, "n", "l", function()
    data.move("right")
  end, "data.nvim: move right")

  map(bufnr, "n", "<C-d>", function()
    data.page(1)
  end, "data.nvim: page down")

  map(bufnr, "n", "<C-u>", function()
    data.page(-1)
  end, "data.nvim: page up")

  map(bufnr, "n", "]t", function()
    vim.cmd("DataNext")
  end, "data.nvim: next table")

  map(bufnr, "n", "[t", function()
    vim.cmd("DataPrev")
  end, "data.nvim: previous table")

  map(bufnr, "n", "gs", function()
    vim.cmd("DataSave")
  end, "data.nvim: save table")

  map(bufnr, "n", "gv", function()
    data.toggle_mode()
  end, "data.nvim: toggle view mode")

  map(bufnr, "n", "zH", function()
    data.hscroll(-1 * (config.get().view.scroll_columns or 8))
  end, "data.nvim: scroll view left")

  map(bufnr, "n", "zL", function()
    data.hscroll(config.get().view.scroll_columns or 8)
  end, "data.nvim: scroll view right")

  map(bufnr, "n", "gi", function()
    local session = state.current()
    if not session then
      return
    end
    local row = session.cursor and session.cursor.row or 1
    local col = session.cursor and session.cursor.col or 1
    local rows = session.model.rows or {}
    local current_value = ""
    if rows[row] and rows[row][col] ~= nil then
      current_value = tostring(rows[row][col])
    end
    local new_value = vim.fn.input("Cell value: ", current_value)
    if new_value ~= nil then
      data.edit(new_value, row, col)
    end
  end, "data.nvim: edit current cell")

  map(bufnr, "n", "gu", function()
    data.undo()
  end, "data.nvim: undo last edit")

  map(bufnr, "n", "gU", function()
    data.redo()
  end, "data.nvim: redo last edit")
end

function M.apply(session, opts)
  opts = opts or {}
  local cfg = config.get()
  if cfg.keymaps and cfg.keymaps.enabled == false then
    return
  end

  local bufnr = session.bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if applied[bufnr] and not opts.force then
    return
  end

  applied[bufnr] = true
  default_maps(bufnr)
end

return M
