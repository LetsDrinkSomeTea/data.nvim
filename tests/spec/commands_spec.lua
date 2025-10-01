require("plenary.busted")

local data = require("data")
local state = require("data.core.state")

local function write_temp_csv(lines)
  local path = vim.fn.tempname() .. ".csv"
  vim.fn.writefile(lines, path)
  return path
end

describe("user commands", function()
  local snapshot_path
  local paths = {}

  local function cleanup_files()
    for _, path in ipairs(paths) do
      vim.fn.delete(path)
    end
    paths = {}
  end

  before_each(function()
    cleanup_files()
    snapshot_path = vim.fn.tempname() .. ".json"
    state.override_storage_path(snapshot_path)
    state.clear()
    data.setup({ commands = true })
    vim.api.nvim_command("enew")
  end)

  after_each(function()
    cleanup_files()
    if snapshot_path then
      vim.fn.delete(snapshot_path)
      snapshot_path = nil
    end
    state.override_storage_path(nil)
    state.clear()
  end)

  it("opens tables and moves via commands", function()
    local path = write_temp_csv({ "First,Second", "alpha,beta", "gamma,delta" })
    paths[#paths + 1] = path

    vim.cmd("DataOpen " .. vim.fn.fnameescape(path))

    local session = state.current()
    assert.is_truthy(session)
    assert.equals(1, session.cursor.row)

    local statusline = require("data").statusline()
    assert.matches("First", statusline)

    vim.cmd("DataMove down")
    assert.equals(2, session.cursor.row)

    vim.cmd("DataMove right 5")
    assert.equals(2, session.cursor.col)

    vim.cmd('DataEdit updated')
    assert.equals('updated', session.model.rows[2][2])

    vim.cmd('DataUndo')
    assert.equals('delta', session.model.rows[2][2])

    vim.cmd('DataRedo')
    assert.equals('updated', session.model.rows[2][2])

    vim.cmd('DataScroll 5')
    assert.is_true((session.view.leftcol or 0) >= 5)
  end)

  it("cycles sessions with DataNext and DataPrev", function()
    local path_a = write_temp_csv({ "First,Second", "alpha,beta" })
    local path_b = write_temp_csv({ "First,Second", "gamma,delta" })
    paths[#paths + 1] = path_a
    paths[#paths + 1] = path_b

    vim.cmd("DataOpen " .. vim.fn.fnameescape(path_a))
    vim.cmd("DataOpen " .. vim.fn.fnameescape(path_b))

    local sessions = state.list()
    assert.equals(2, #sessions)
    assert.equals(path_b, state.current().meta.source)

    vim.cmd("DataPrev")
    assert.equals(path_a, state.current().meta.source)

    vim.cmd("DataNext")
    assert.equals(path_b, state.current().meta.source)
  end)
end)
