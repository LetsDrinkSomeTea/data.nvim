local M = {}

local json = require("vim.json")

M.name = "rest"

function M.is_available()
  return vim.fn.executable("curl") == 1
end

local function request(url, opts)
  opts = opts or {}
  local headers = opts.headers or {}
  local header_args = {}
  for key, value in pairs(headers) do
    header_args[#header_args + 1] = "-H"
    header_args[#header_args + 1] = string.format("%s: %s", key, value)
  end

  local method = opts.method or "GET"
  local args = { "curl", "-s", "-X", method }
  vim.list_extend(args, header_args)
  if opts.body then
    args[#args + 1] = "-d"
    args[#args + 1] = opts.body
  end
  args[#args + 1] = url

  local output = vim.fn.system(args)
  if vim.v.shell_error ~= 0 then
    error(string.format("curl request failed (%s)", url))
  end
  local parsed = json.decode(output)
  return parsed
end

local function normalize_table(decoded)
  if decoded.rows and decoded.columns then
    return decoded.columns, decoded.rows
  end
  if decoded.data and decoded.headers then
    return decoded.headers, decoded.data
  end
  if decoded.items and vim.islist(decoded.items) then
    local first = decoded.items[1] or {}
    local headers = {}
    for key in pairs(first) do
      headers[#headers + 1] = key
    end
    table.sort(headers)
    local rows = {}
    for _, item in ipairs(decoded.items) do
      local row = {}
      for index, header in ipairs(headers) do
        row[index] = item[header]
      end
      rows[#rows + 1] = row
    end
    return headers, rows
  end
  error("rest adapter: unable to determine headers/rows from payload")
end

function M.supports(source)
  return type(source) == "string" and source:match("^https?://") ~= nil
end

function M.load(source, opts)
  local decoded = request(source, opts)
  local headers, rows = normalize_table(decoded)
  return {
    header = headers,
    rows = rows,
    source = source,
  }
end

function M.save(_model, _opts)
  error("rest adapter is read-only")
end

return M
