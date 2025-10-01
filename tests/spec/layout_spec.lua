require("plenary.busted")

local layout = require("data.ui.layout")

describe("ui.layout", function()
  it("keeps total width within available width", function()
    local rows = {
      { "alpha", "beta" },
      { "gamma", "delta" },
    }
    local info = layout.measure(rows, {
      header = { "First", "Second" },
      available_width = 20,
      min_width = 3,
      max_width = 10,
      separator = " | ",
    })

    assert.same(2, info.columns)
    assert.is_true(info.total_width <= 20)
  end)

  it("renders header, separator and rows", function()
    local rows = {
      { "alpha", "beta" },
    }
    local info = layout.measure(rows, {
      header = { "First", "Second" },
      available_width = 30,
      min_width = 3,
      max_width = 10,
    })

    local lines = layout.render(rows, info, { header = { "First", "Second" } })
    assert.equal(3, #lines)
    assert.matches("First", lines[1])
    assert.matches("alpha", lines[3])
  end)
end)
