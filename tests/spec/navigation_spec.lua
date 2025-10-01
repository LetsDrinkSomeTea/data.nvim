require("plenary.busted")

local actions = require("data.core.actions")
local state = require("data.core.state")
local config = require("data.config")

local function write_temp_csv(rows)
  local path = vim.fn.tempname() .. ".csv"
  vim.fn.writefile(rows, path)
  return path
end

describe("core.actions navigation", function()
  local snapshot_path

  before_each(function()
    config.setup({})
    snapshot_path = vim.fn.tempname() .. ".json"
    state.override_storage_path(snapshot_path)
    state.clear()
    actions.bootstrap()
    vim.api.nvim_command("enew")
  end)

  after_each(function()
    if snapshot_path then
      vim.fn.delete(snapshot_path)
      snapshot_path = nil
    end
    state.override_storage_path(nil)
  end)

  it("moves cursor within table", function()
    local path = write_temp_csv({ "First,Second", "alpha,beta", "gamma,delta" })

    local session = actions.open(path, { enter = false })
    assert.equals(1, session.cursor.row)
    assert.equals(1, session.cursor.col)

    actions.move(session, "down", 1)
    assert.equals(2, session.cursor.row)

    actions.move(session, "down", 10)
    assert.equals(2, session.cursor.row)

    actions.move(session, "right", 5)
    assert.equals(2, session.cursor.col)

    actions.move(session, "up", 2)
    assert.equals(1, session.cursor.row)

    actions.move(session, "left", 5)
    assert.equals(1, session.cursor.col)

    vim.fn.delete(path)
  end)

  it("switches between sessions and maintains focus", function()
    local path_a = write_temp_csv({ "First,Second", "alpha,beta" })
    local path_b = write_temp_csv({ "First,Second", "gamma,delta" })

    local session_a = actions.open(path_a)
    local session_b = actions.open(path_b)

    assert.equals(session_b.id, state.current().id)

    actions.move(session_b, "right")
    actions.switch(session_a.id)

    assert.equals(session_a.id, state.current().id)
    assert.equals(session_a.bufnr, vim.api.nvim_get_current_buf())

    local list = actions.list_sessions()
    assert.equals(2, #list)
    local current_entry
    for _, entry in ipairs(list) do
      if entry.current then
        current_entry = entry
        break
      end
    end
    assert.is_not_nil(current_entry)
    assert.equals(session_a.id, current_entry.id)

    vim.fn.delete(path_a)
    vim.fn.delete(path_b)
  end)

  it("restores sessions from snapshot", function()
    local path = write_temp_csv({ "First,Second", "alpha,beta" })
    local session = actions.open(path, { enter = false })
    actions.move(session, "down")
    state.persist_snapshot()

    local snapshot_lines = vim.fn.readfile(snapshot_path)

    state.clear()
    vim.fn.writefile(snapshot_lines, snapshot_path)

    local restored = actions.restore_sessions({ enter = false })
    assert.equals(1, #restored)

    local list = actions.list_sessions()
    assert.equals(1, #list)
    assert.equals(path, list[1].source)

    vim.fn.delete(path)
  end)
end)
