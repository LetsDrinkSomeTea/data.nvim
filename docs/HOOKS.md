# Hook Events

| Event             | Payload Fields                            | Description |
|-------------------|-------------------------------------------|-------------|
| `TableOpened`     | `session`, `source`, `adapter`, `mode`    | Fired after a datasource is loaded into a session. |
| `TableSaved`      | `session`, `source`, `adapter`            | Emitted after a session is persisted via its adapter. |
| `ViewModeChanged` | `session`, `mode`                         | Triggered whenever the view mode changes (toggle or explicit). |
| `CellEdited`      | `session`, `row`, `col`, `before`, `after`| Fired after a cell edit is applied. |
| `UndoApplied`     | `session`, `change`                       | Emitted after an undo restores a change. |
| `RedoApplied`     | `session`, `change`                       | Emitted after a redo reapplies a change. |
| `ViewportChanged` | `session`, `leftcol`, `top`               | Triggered when horizontal/vertical viewport offsets update. |

## Registering Hooks

```lua
local data = require("data")

-- Persistent handler
local unsubscribe = data.on("TableOpened", function(payload)
  print("Opened", payload.source)
end)

-- One-shot handler
data.once("TableSaved", function(payload)
  print("Saved", payload.source)
end)

-- Remove handler
unsubscribe()
```

Handlers run in protected mode; runtime errors are reported via `vim.notify`.

## Custom Datasources

You can register adapters during `setup` or at runtime:

```lua
local my_adapter = {
  supports = function(path)
    return path:match("%.myfmt$") ~= nil
  end,
  load = function(path, opts)
    return {
      header = { "name", "value" },
      rows = { { "example", 42 } },
      source = path,
    }
  end,
  save = function(model, opts)
    -- persist model.rows to opts.source
  end,
}

require("data").setup({
  datasources = {
    register = {
      myfmt = my_adapter,
    },
    priority = { "myfmt", "csv", "sqlite" },
  },
})
```

Adapters must implement `load` and `save`, and may define optional fields:

- `supports(source, opts)` — return `true` if adapter can handle the source.
- `is_available()` — return `false` if adapter dependencies are missing (skips registration).

At runtime you can register via `require("data").register_datasource("name", adapter)`.
