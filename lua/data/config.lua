local M = {}

local default_config = {
  column_width = {
    strategy = "auto",
    min = 3,
    max = 50,
  },
  view = {
    modes = {
      compact = { wrap = false, strategy = "auto" },
      expanded = { wrap = true, strategy = "fixed" },
    },
    default_mode = "compact",
  },
  theme = {
    header = "Title",
    focused_cell = "Visual",
    column_palette = {
      by_index = { "Type", "Identifier", "Function", "Number" },
      fallback = "Normal",
    },
  },
  datasources = {
    priority = { "csv", "sqlite" },
  },
  performance = {
    chunk_size = 500,
    cache_rows = true,
  },
  keymaps = {
    enabled = true,
  },
  statusline = {
    enabled = true,
    format = "[%s] Row %d/%d · Col %d (%s)",
  },
}

local current_config

local function deep_copy(tbl)
  return vim.deepcopy(tbl)
end

function M.defaults()
  return deep_copy(default_config)
end

function M.setup(opts)
  current_config = vim.tbl_deep_extend("force", M.defaults(), opts or {})
  return current_config
end

function M.get()
  if not current_config then
    current_config = M.setup()
  end
  return current_config
end

return M
