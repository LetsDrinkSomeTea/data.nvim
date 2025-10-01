require("plenary.busted")

local has_sqlite = vim.fn.executable("sqlite3") == 1

if not has_sqlite then
  describe("datasource.sqlite", function()
    it("skips when sqlite3 CLI is unavailable", function()
      pending("sqlite3 executable not available; skipping sqlite datasource specs")
    end)
  end)
  return
end

local sqlite_adapter = require("data.datasources.sqlite")

local function sqlite_exec(path, sql)
  local result = vim.fn.system({ "sqlite3", path }, sql)
  if vim.v.shell_error ~= 0 then
    error(string.format("sqlite3 exec failed: %s", result))
  end
  return result
end

local function sqlite_query(path, sql)
  local rows = vim.fn.systemlist({ "sqlite3", "-readonly", path, sql })
  if vim.v.shell_error ~= 0 then
    error("sqlite3 query failed")
  end
  return rows
end

describe("datasource.sqlite", function()
  local db_path

  local function seed_database()
    sqlite_exec(db_path, [[
CREATE TABLE people (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);
INSERT INTO people (name, age) VALUES ('Ada', 30);
INSERT INTO people (name, age) VALUES ('Grace', 35);
]])
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
    model.rows[1][3] = "31"
    model.rows[2][2] = "Grace Hopper"

    sqlite_adapter.save(model, { source = db_path, table = "people" })

    local ages = sqlite_query(db_path, "SELECT age FROM people ORDER BY id;")
    assert.same({ "31", "35" }, ages)

    local reloaded = sqlite_adapter.load(db_path, { table = "people" })
    assert.equal("Grace Hopper", reloaded.rows[2][2])
  end)
end)
