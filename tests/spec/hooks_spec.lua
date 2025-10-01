require("plenary.busted")

local data = require("data")
local hooks = require("data.core.hooks")
local state = require("data.core.state")

local function write_temp_csv(lines)
  local path = vim.fn.tempname() .. ".csv"
  vim.fn.writefile(lines, path)
  return path
end

describe("hooks", function()
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
    hooks.clear()
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
    hooks.clear()
    state.clear()
  end)

  it("fires open/save hooks", function()
    local opened = {}
    hooks.register("TableOpened", function(payload)
      opened[#opened + 1] = payload
    end)

    local saved
    hooks.register("TableSaved", function(payload)
      saved = payload
    end)

    local path = write_temp_csv({ "First,Second", "alpha,beta" })
    paths[#paths + 1] = path

    local session = data.open(path, { enter = false })
    assert.equals(1, #opened)
    assert.equals(session.id, opened[1].session.id)

    data.save(session)
    assert.is_truthy(saved)
    assert.equals(session.id, saved.session.id)
  end)

  it("fires view and cell edit hooks", function()
    local mode_changes = 0
    hooks.register("ViewModeChanged", function(payload)
      mode_changes = mode_changes + 1
    end)

    local edits = {}
    hooks.register("CellEdited", function(payload)
      edits[#edits + 1] = payload
    end)

    local path = write_temp_csv({ "First,Second", "alpha,beta" })
    paths[#paths + 1] = path
    local session = data.open(path, { enter = false })

    data.toggle_mode()
    data.edit("new", 1, 2)

    assert.is_true(mode_changes >= 2)
    assert.equals("new", edits[#edits].after)
    assert.equals("beta", edits[#edits].before)

    data.undo()
    data.redo()
  end)

  it("supports once handlers", function()
    local count = 0
    data.once("TableOpened", function()
      count = count + 1
    end)

    local path = write_temp_csv({ "First" })
    paths[#paths + 1] = path
    data.open(path, { enter = false })
    local second = write_temp_csv({ "A" })
    paths[#paths + 1] = second
    data.open(second, { enter = false })
    assert.equals(1, count)
  end)
end)
