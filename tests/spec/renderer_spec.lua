require("plenary.busted")

local renderer = require("data.ui.renderer")

describe("ui.renderer", function()
  before_each(function()
    vim.api.nvim_command("enew")
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
end)
