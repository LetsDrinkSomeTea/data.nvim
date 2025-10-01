# Datasource Adapters

`data.nvim` interacts with tabular formats via datasource adapters. Built-ins cover CSV variants and SQLite; you can register additional adapters to parse REST APIs, Excel exports, Parquet files, etc.

## Adapter Contract

Each adapter should implement:

- `supports(source, opts)` (optional): return `true` if the adapter can handle the source. If omitted, the adapter is always considered.
- `load(source, opts)` (required): return a table model `{ header, rows, delimiter?, source? }`.
- `save(model, opts)` (required): persist `model.rows` back to storage (use `opts.source` as target path/connection string).
- `is_available()` (optional): return `false` when dependencies are missing; registration is skipped.

### Example

```lua
local rest_adapter = {}

function rest_adapter.supports(source)
  return vim.startswith(source, "https://api.example.com/")
end

function rest_adapter.load(source, opts)
  local json = vim.fn.system("curl -s " .. vim.fn.shellescape(source))
  local decoded = vim.json.decode(json)
  local header = decoded.columns
  local rows = decoded.rows
  return {
    header = header,
    rows = rows,
    source = source,
  }
end

function rest_adapter.save(model, opts)
  error("REST adapter is read-only")
end

return rest_adapter
```

## Registration

### During Setup

```lua
local rest_adapter = require("my_project.adapters.rest")

require("data").setup({
  datasources = {
    register = {
      rest = rest_adapter,
    },
    priority = { "rest", "sqlite", "csv" },
  },
})
```

### At Runtime

```lua
local data = require("data")
data.register_datasource("rest", rest_adapter)
```

## Priority & Resolution

The resolution order:
1. Explicit `adapter` option passed to `data.open(source, { adapter = "rest" })` (validated via `supports`).
2. `datasources.priority` list from config (first matching adapter wins).
3. Any remaining registered adapters.

## Testing Custom Adapters

Use the helper spec pattern:

```lua
local fake_adapter = {
  supports = function(source)
    return source == "memory://fake"
  end,
  load = function()
    return { header = { "A" }, rows = { { "1" } } }
  end,
  save = function() end,
}

describe("fake adapter", function()
  before_each(function()
    require("data").setup({ datasources = { register = { fake = fake_adapter }, priority = { "fake" } } })
  end)
end)
```

Remember to restore configuration or re-run `setup` between tests to avoid leaking adapters.
