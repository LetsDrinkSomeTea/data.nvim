local csv = require("data.datasources.csv")

local M = {}

M.name = "sqlite"

local function is_available()
  return vim.fn.executable("sqlite3") == 1
end

M.is_available = is_available

local function assert_available()
  if not is_available() then
    error("data.nvim.sqlite: command 'sqlite3' is required")
  end
end

local function quote_identifier(name)
  return string.format('"%s"', tostring(name):gsub('"', '""'))
end

local function run_sqlite(args, input)
  local output = vim.fn.systemlist(args, input)
  if vim.v.shell_error ~= 0 then
    local message = table.concat(output, "\n")
    if message == "" then
      message = string.format("data.nvim.sqlite: command failed (%s)", table.concat(args, " "))
    end
    return nil, message
  end
  return output
end

local function run_sqlite_query(source, opts)
  local args = { "sqlite3" }
  if opts and opts.readonly then
    table.insert(args, "-readonly")
  end
  if opts and opts.mode then
    vim.list_extend(args, opts.mode)
  end
  table.insert(args, source)
  table.insert(args, opts.query)
  return run_sqlite(args)
end

local function run_sqlite_csv(source, query)
  local args = {
    "sqlite3",
    "-readonly",
    "-header",
    "-csv",
    source,
    query,
  }
  return run_sqlite(args)
end

local function list_tables(source)
  local output, err = run_sqlite_query(source, {
    readonly = true,
    query = "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name;",
  })
  if not output then
    return nil, err
  end

  local tables = {}
  for _, line in ipairs(output) do
    local name = vim.trim(line)
    if name ~= "" then
      tables[#tables + 1] = name
    end
  end
  return tables
end

local function parse_table_info(lines)
  if not lines or #lines == 0 then
    return nil, nil
  end

  local header = csv.parse_line(lines[1])
  local name_index, pk_index = 0, 0
  for index, column in ipairs(header) do
    if column == "name" then
      name_index = index
    elseif column == "pk" then
      pk_index = index
    end
  end

  if name_index == 0 then
    return nil, nil
  end

  local columns, primary_keys = {}, {}
  for row_index = 2, #lines do
    local fields = csv.parse_line(lines[row_index])
    local name = fields[name_index]
    columns[#columns + 1] = name
    if pk_index > 0 and tonumber(fields[pk_index]) == 1 then
      primary_keys[#primary_keys + 1] = name
    end
  end
  return columns, primary_keys
end

local function table_info(source, table_name)
  local query = string.format("PRAGMA table_info(%s);", quote_identifier(table_name))
  local output, err = run_sqlite_csv(source, query)
  if not output then
    return nil, nil, err
  end
  return parse_table_info(output)
end

local function fetch_rows(source, table_name)
  local query = string.format("SELECT * FROM %s;", quote_identifier(table_name))
  local output, err = run_sqlite_csv(source, query)
  if not output then
    return nil, nil, err
  end
  if #output == 0 then
    return {}, {}
  end

  local header = csv.parse_line(output[1])
  local rows = {}
  for index = 2, #output do
    rows[#rows + 1] = csv.parse_line(output[index])
  end
  return header, rows
end

local function sanitize_table_name(name)
  if not name or name == "" then
    return nil, "table name is required"
  end
  return name
end

local function sql_quote(value)
  if value == nil then
    return "NULL"
  end
  if type(value) == "number" then
    return tostring(value)
  end
  local str = tostring(value)
  str = str:gsub("'", "''")
  return string.format("'%s'", str)
end

local function run_sqlite_script(source, commands)
  local script = table.concat(commands, "\n") .. "\n"
  local args = { "sqlite3", source }
  local output = vim.fn.system(args, script)
  if vim.v.shell_error ~= 0 then
    local message = (output and output ~= "") and output or "data.nvim.sqlite: script execution failed"
    return nil, message
  end
  return true
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

  local table_name = opts.table
  if not table_name then
    local tables, err = list_tables(source)
    if not tables then
      error(err)
    end
    table_name = tables and tables[1]
  end

  if not table_name then
    error("data.nvim.sqlite: no tables found in database")
  end

  local columns, primary_keys, err = table_info(source, table_name)
  if not columns then
    error(err or string.format("data.nvim.sqlite: unable to read schema for '%s'", table_name))
  end
  if #columns == 0 then
    error(string.format("data.nvim.sqlite: table '%s' has no columns", table_name))
  end

  local header, rows, row_err = fetch_rows(source, table_name)
  if not header then
    error(row_err)
  end

  return {
    source = source,
    table = table_name,
    header = header,
    primary_key = primary_keys,
    rows = rows,
  }
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

  local quoted_columns = {}
  for index, column in ipairs(columns) do
    quoted_columns[index] = quote_identifier(column)
  end
  local column_list = table.concat(quoted_columns, ", ")

  local commands = {
    "BEGIN TRANSACTION;",
    string.format("DELETE FROM %s;", quote_identifier(table_name)),
  }

  for _, row in ipairs(rows) do
    local values = {}
    for index, value in ipairs(row) do
      values[index] = sql_quote(value)
    end
    local value_list = table.concat(values, ", ")
    commands[#commands + 1] = string.format(
      "INSERT INTO %s (%s) VALUES (%s);",
      quote_identifier(table_name),
      column_list,
      value_list
    )
  end

  commands[#commands + 1] = "COMMIT;"

  local ok, err = run_sqlite_script(source, commands)
  if not ok then
    error(err)
  end
end

return M
