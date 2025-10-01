local M = {}

local delimiter_by_ext = {
  csv = ",",
  tsv = "\t",
  ssv = ";",
}

local function infer_delimiter(source, opts)
  opts = opts or {}
  if opts.delimiter then
    return opts.delimiter
  end
  if opts.format then
    return delimiter_by_ext[opts.format] or ","
  end
  local ext = source:match("%.([%a%d]+)$")
  if ext then
    return delimiter_by_ext[ext:lower()] or ","
  end
  return ","
end

local function trim_trailing_newline(s)
  return (s:gsub("\r?\n$", ""))
end

function M.parse_line(line, delimiter)
  delimiter = delimiter or ","
  local fields = {}
  local buf = {}
  local in_quotes = false
  local i = 1
  while i <= #line do
    local ch = line:sub(i, i)
    if ch == '"' then
      local next_char = line:sub(i + 1, i + 1)
      if in_quotes and next_char == '"' then
        table.insert(buf, '"')
        i = i + 1
      else
        in_quotes = not in_quotes
      end
    elseif ch == delimiter and not in_quotes then
      table.insert(fields, table.concat(buf))
      buf = {}
    else
      table.insert(buf, ch)
    end
    i = i + 1
  end
  table.insert(fields, table.concat(buf))
  return fields
end

function M.serialize_row(row, delimiter)
  delimiter = delimiter or ","
  local out = {}
  for _, value in ipairs(row) do
    local cell = tostring(value or "")
    local needs_quotes = cell:find(delimiter, 1, true) or cell:find('"', 1, true) or cell:find("\n", 1, true)
    if needs_quotes then
      cell = cell:gsub('"', '""')
      cell = string.format('"%s"', cell)
    end
    table.insert(out, cell)
  end
  return table.concat(out, delimiter)
end

function M.load(source, opts)
  opts = opts or {}
  local delimiter = infer_delimiter(source, opts)
  local lines = vim.fn.readfile(source)
  local rows = {}
  for _, line in ipairs(lines) do
    local cleaned = trim_trailing_newline(line)
    table.insert(rows, M.parse_line(cleaned, delimiter))
  end

  local header
  if opts.header ~= false and #rows > 0 then
    header = rows[1]
    table.remove(rows, 1)
  end

  return {
    header = header,
    rows = rows,
    delimiter = delimiter,
    source = source,
  }
end

function M.save(model, opts)
  opts = opts or {}
  local target = opts.source or model.source
  assert(target, "data.nvim.csv: missing target path for save")

  local delimiter = model.delimiter or infer_delimiter(target, opts)
  local lines = {}

  if model.header and opts.header ~= false then
    table.insert(lines, M.serialize_row(model.header, delimiter))
  end

  for _, row in ipairs(model.rows or {}) do
    table.insert(lines, M.serialize_row(row, delimiter))
  end

  vim.fn.writefile(lines, target, "b")
end

function M.supports(source, opts)
  local delimiter = infer_delimiter(source or "", opts)
  return delimiter ~= nil
end

function M.infer_delimiter(source, opts)
  return infer_delimiter(source or "", opts)
end

return M
