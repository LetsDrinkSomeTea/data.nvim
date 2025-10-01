require("plenary.busted")

local data = require("data")
local state = require("data.core.state")

local function write_temp_csv(lines)
  local path = vim.fn.tempname() .. ".csv"
  vim.fn.writefile(lines, path)
  return path
end

describe("edit actions", function()
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

  it("applies edit, undo, and redo", function()
    local path = write_temp_csv({ "First,Second", "alpha,beta" })
    paths[#paths + 1] = path

    local session = data.open(path, { enter = false })
    assert.is_false(session.dirty)

    data.edit("new", 1, 2)
    assert.equals("new", session.model.rows[1][2])
    assert.is_true(session.dirty)

    data.undo()
    assert.equals("beta", session.model.rows[1][2])
    assert.is_false(session.dirty)

    data.redo()
    assert.equals("new", session.model.rows[1][2])
    assert.is_true(session.dirty)
  end)
end)
