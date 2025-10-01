require("plenary.busted")

local renderer = require("data.ui.renderer")
local config = require("data.config")

describe("ui.renderer", function()
  before_each(function()
    vim.api.nvim_command("enew")
    config.setup({})
  end)

  it("creates a buffer and renders rows", function()
    local session = {
      model = {
        header = { "First", "Second" },
        rows = {
          { "alpha", "beta" },
        },
      },
      meta = {
        source = "memory://test.csv",
      },
    }

    renderer.render(session, { enter = false, available_width = 40 })

    assert.is_truthy(session.bufnr)
    assert.is_true(vim.api.nvim_buf_is_valid(session.bufnr))

    local lines = vim.api.nvim_buf_get_lines(session.bufnr, 0, -1, false)
    assert.equal(3, #lines)
    assert.matches("First", lines[1])
    assert.matches("alpha", lines[3])
    assert.is_truthy(session.layout)
  end)

  it("applies column highlights from config palette", function()
    config.setup({
      theme = {
        column_palette = {
          by_index = { "Constant", "String" },
          fallback = "Identifier",
        },
      },
    })

    local session = {
      model = {
        header = { "Name", "Value" },
        rows = {
          { "alpha", "beta" },
        },
      },
      meta = {
        source = "memory://palette.csv",
      },
    }

    renderer.render(session, { enter = false, available_width = 40 })

    local ns = vim.api.nvim_get_namespaces()["data.nvim.renderer"]
    assert.is_truthy(ns)

    local marks = vim.api.nvim_buf_get_extmarks(
      session.bufnr,
      ns,
      { 2, 0 },
      { 3, 0 },
      { details = true }
    )

    local groups = {}
    for _, mark in ipairs(marks) do
      groups[#groups + 1] = mark[4].hl_group
    end

    assert.same({ "Constant", "String" }, groups)
  end)
end)
