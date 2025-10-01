local M = {}

local ok, sqlite3 = pcall(require, "lsqlite3")

local unpack = table.unpack or unpack

local function is_available()
  return ok and sqlite3 ~= nil
end

M.is_available = is_available
M.name = "sqlite"

local function assert_available()
  if not is_available() then
    error("data.nvim.sqlite: optional dependency 'lsqlite3' is required")
  end
end

local function quote_identifier(name)
  return string.format('"%s"', tostring(name):gsub('"', '""'))
end

local function with_db(path, callback)
  local db = sqlite3.open(path)
  if not db then
    return nil, string.format("data.nvim.sqlite: unable to open database '%s'", path)
  end
  db:busy_timeout(1000)

  local ok_cb, result = pcall(callback, db)
  local close_ok, close_err = db:close()
  if close_ok == false then
    return nil, close_err or "data.nvim.sqlite: failed to close database"
  end
  if not ok_cb then
    return nil, result
  end
  return result
end

local function list_tables(db)
  local tables = {}
  for row in db:nrows("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name;") do
    tables[#tables + 1] = row.name
  end
  return tables
end

local function table_info(db, table_name)
  local columns = {}
  local primary_keys = {}
  local pragma = string.format("PRAGMA table_info(%s);", quote_identifier(table_name))
  for row in db:nrows(pragma) do
    columns[#columns + 1] = row.name
    if tonumber(row.pk) == 1 then
      primary_keys[#primary_keys + 1] = row.name
    end
  end
  return columns, primary_keys
end

local function fetch_rows(db, table_name, columns)
  local rows = {}
  local select_sql = string.format("SELECT * FROM %s;", quote_identifier(table_name))
  for row in db:nrows(select_sql) do
    local ordered = {}
    for index, column in ipairs(columns) do
      ordered[index] = row[column]
    end
    rows[#rows + 1] = ordered
  end
  return rows
end

local function sanitize_table_name(name)
  if not name or name == "" then
    return nil, "table name is required"
  end
  return name
end

function M.supports(source, opts)
  if not is_available() then
    return false
  end
  opts = opts or {}
  if opts.datasource == "sqlite" or opts.format == "sqlite" then
    return true
  end
  if type(source) ~= "string" then
    return false
  end
  local ext = source:match("%.([%w]+)$")
  if not ext then
    return false
  end
  ext = ext:lower()
  return ext == "db" or ext == "sqlite" or ext == "sqlite3"
end

function M.load(source, opts)
  assert_available()
  opts = opts or {}
  local result, err = with_db(source, function(db)
    local table_name = opts.table
    if not table_name then
      local tables = list_tables(db)
      table_name = tables[1]
    end
    if not table_name then
      error("data.nvim.sqlite: no tables found in database")
    end

    local columns, primary_keys = table_info(db, table_name)
    if #columns == 0 then
      error(string.format("data.nvim.sqlite: table '%s' has no columns", table_name))
    end

    local rows = fetch_rows(db, table_name, columns)
    return {
      source = source,
      table = table_name,
      header = columns,
      primary_key = primary_keys,
      rows = rows,
    }
  end)

  if not result then
    error(err)
  end
  return result
end

local function to_sqlite_values(values)
  local converted = {}
  for index, value in ipairs(values) do
    if value == nil then
      converted[index] = sqlite3.NULL
    else
      converted[index] = value
    end
  end
  return converted
end

local function delete_rows(db, table_name)
  local sql = string.format("DELETE FROM %s;", quote_identifier(table_name))
  local rc = db:exec(sql)
  if rc ~= sqlite3.OK then
    error(db:errmsg())
  end
end

local function insert_rows(db, table_name, columns, rows)
  if #rows == 0 then
    return
  end

  local column_list = {}
  local placeholders = {}
  for _, column in ipairs(columns) do
    column_list[#column_list + 1] = quote_identifier(column)
    placeholders[#placeholders + 1] = "?"
  end

  local insert_sql = string.format(
    "INSERT INTO %s (%s) VALUES (%s);",
    quote_identifier(table_name),
    table.concat(column_list, ", "),
    table.concat(placeholders, ", ")
  )

  local stmt = db:prepare(insert_sql)
  if not stmt then
    error(db:errmsg())
  end

  local function finalize()
    local rc = stmt:finalize()
    if rc ~= sqlite3.OK then
      error(db:errmsg())
    end
  end

  local ok2, err = pcall(function()
    for _, row in ipairs(rows) do
      local converted = to_sqlite_values(row)
      local bind_rc = stmt:bind_values(unpack(converted))
      if bind_rc ~= sqlite3.OK then
        error(db:errmsg())
      end
      local step_rc = stmt:step()
      if step_rc ~= sqlite3.DONE then
        error(db:errmsg())
      end
      stmt:reset()
      stmt:clear_bindings()
    end
  end)

  finalize()

  if not ok2 then
    error(err)
  end
end

local function write_table(db, table_name, columns, rows)
  local rc = db:exec("BEGIN TRANSACTION;")
  if rc ~= sqlite3.OK then
    error(db:errmsg())
  end

  local ok_tx, err = pcall(function()
    delete_rows(db, table_name)
    insert_rows(db, table_name, columns, rows)
  end)

  if ok_tx then
    local commit_rc = db:exec("COMMIT;")
    if commit_rc ~= sqlite3.OK then
      error(db:errmsg())
    end
    return
  end

  db:exec("ROLLBACK;")
  error(err)
end

function M.save(model, opts)
  assert_available()
  opts = opts or {}

  local source = opts.source or model.source
  if not source then
    error("data.nvim.sqlite: source is required for save")
  end

  local table_name = sanitize_table_name(opts.table or model.table)
  if not table_name then
    error("data.nvim.sqlite: table name is required for save")
  end

  local columns = model.header
  if not columns or #columns == 0 then
    error("data.nvim.sqlite: header is required to save rows")
  end

  local rows = model.rows or {}

  local ok_save, err = with_db(source, function(db)
    write_table(db, table_name, columns, rows)
  end)

  if not ok_save then
    error(err)
  end
end

return M
