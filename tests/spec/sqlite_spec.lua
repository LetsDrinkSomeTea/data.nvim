require("plenary.busted")

local ok, sqlite3 = pcall(require, "lsqlite3")

if not ok then
  describe("datasource.sqlite", function()
    it("skips when lsqlite3 is unavailable", function()
      pending("lsqlite3 not available; skipping sqlite datasource specs")
    end)
  end)
  return
end

local sqlite_adapter = require("data.datasources.sqlite")

local function collect_ages(path)
  local db = sqlite3.open(path)
  assert.is_truthy(db)

  local ages = {}
  for row in db:nrows("SELECT age FROM people ORDER BY id;") do
    ages[#ages + 1] = row.age
  end

  assert.is_true(db:close())
  return ages
end

describe("datasource.sqlite", function()
  local db_path

  local function seed_database()
    local db = sqlite3.open(db_path)
    assert.is_truthy(db)

    assert.equals(sqlite3.OK, db:exec([[CREATE TABLE people (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);]]))
    assert.equals(sqlite3.OK, db:exec([[INSERT INTO people (name, age) VALUES ('Ada', 30);]]))
    assert.equals(sqlite3.OK, db:exec([[INSERT INTO people (name, age) VALUES ('Grace', 35);]]))

    assert.is_true(db:close())
  end

  before_each(function()
    db_path = vim.fn.tempname() .. ".sqlite3"
    seed_database()
  end)

  after_each(function()
    if db_path then
      os.remove(db_path)
      db_path = nil
    end
  end)

  it("supports sqlite file extensions", function()
    assert.is_true(sqlite_adapter.supports("data/example.db"))
    assert.is_true(sqlite_adapter.supports("data/example.sqlite"))
    assert.is_true(sqlite_adapter.supports("data/example.sqlite3"))
    assert.is_false(sqlite_adapter.supports("data/example.csv"))
  end)

  it("loads rows and headers from the selected table", function()
    local model = sqlite_adapter.load(db_path, { table = "people" })

    assert.same({ "id", "name", "age" }, model.header)
    assert.equal("people", model.table)
    assert.equal(2, #model.rows)
    assert.equal("Ada", model.rows[1][2])
  end)

  it("persists row updates via save", function()
    local model = sqlite_adapter.load(db_path, { table = "people" })
    model.rows[1][3] = 31
    model.rows[2][2] = "Grace Hopper"

    sqlite_adapter.save(model, { source = db_path, table = "people" })

    local ages = collect_ages(db_path)
    assert.same({ 31, 35 }, ages)

    local reloaded = sqlite_adapter.load(db_path, { table = "people" })
    assert.equal("Grace Hopper", reloaded.rows[2][2])
  end)
end)
