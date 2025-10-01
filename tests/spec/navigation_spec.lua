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
  before_each(function()
    config.setup({})
    state.clear()
    actions.bootstrap()
    vim.api.nvim_command("enew")
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
end)
