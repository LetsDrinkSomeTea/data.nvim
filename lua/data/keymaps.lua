local config = require("data.config")

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
