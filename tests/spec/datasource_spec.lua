require("plenary.busted")

local data = require("data")
local state = require("data.core.state")

local fake_adapter = {
  rows = {
    header = { "A", "B" },
    rows = {
      { "1", "2" },
    },
  },
}

function fake_adapter.supports(source)
  return source == "memory://fake"
end

function fake_adapter.load(_source, _opts)
  return vim.deepcopy(fake_adapter.rows)
end

function fake_adapter.save(model, opts)
  fake_adapter.last_save = {
    model = model,
    opts = opts,
  }
end

local function reset()
  fake_adapter.last_save = nil
end

describe("datasource registry", function()
  before_each(function()
    reset()
    state.clear()
    data.clear_hooks()
    data.setup({
      datasources = {
        register = {
          fake = fake_adapter,
        },
        priority = { "fake", "csv", "sqlite" },
      },
      commands = false,
    })
  end)

  after_each(function()
    state.clear()
  end)

  it("loads using custom adapter", function()
    local session = data.open("memory://fake", { adapter = "fake" })
    assert.same({ "A", "B" }, session.model.header)
    assert.equals("fake", session.meta.adapter)
  end)

  it("saves via custom adapter", function()
    local session = data.open("memory://fake", { adapter = "fake" })
    data.save(session)
    assert.is_truthy(fake_adapter.last_save)
    assert.equals("memory://fake", fake_adapter.last_save.opts.source)
  end)
end)
