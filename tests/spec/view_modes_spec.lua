require("plenary.busted")

local data = require("data")
local state = require("data.core.state")

local function write_temp_csv(lines)
  local path = vim.fn.tempname() .. ".csv"
  vim.fn.writefile(lines, path)
  return path
end

describe("view modes", function()
  local snapshot_path
  local paths = {}

  local function cleanup()
    for _, path in ipairs(paths) do
      vim.fn.delete(path)
    end
    paths = {}
  end

  before_each(function()
    cleanup()
    snapshot_path = vim.fn.tempname() .. ".json"
    state.override_storage_path(snapshot_path)
    state.clear()
    data.setup({ commands = true })
    vim.api.nvim_command("enew")
  end)

  after_each(function()
    cleanup()
    if snapshot_path then
      vim.fn.delete(snapshot_path)
      snapshot_path = nil
    end
    state.override_storage_path(nil)
    state.clear()
  end)

  it("toggles between modes", function()
    local path = write_temp_csv({ "First,Second", "alpha,beta" })
    paths[#paths + 1] = path

    data.open(path, { enter = false })
    local session = state.current()
    assert.equals("compact", session.mode)

    data.toggle_mode()
    assert.equals("expanded", session.mode)

    data.mode("compact")
    assert.equals("compact", session.mode)
  end)

  it("persists mode in snapshot", function()
    local path = write_temp_csv({ "First,Second", "alpha,beta" })
    paths[#paths + 1] = path

    data.open(path, { enter = false })
    data.toggle_mode() -- expanded

    state.persist_snapshot()
    local snapshot_lines = vim.fn.readfile(snapshot_path)
    state.clear()
    vim.fn.writefile(snapshot_lines, snapshot_path)

    local restored = data.restore_sessions({ enter = false })
    assert.equals(1, #restored)
    local session = restored[1]
    assert.equals("expanded", session.mode)
  end)
end)
