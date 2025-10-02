# data.nvim

**data.nvim** is a Neovim-focused TUI for inspecting and editing tabular datasets (CSV/TSV/SSV, SQLite, extensible adapters). It keeps data interaction inside the editor with smart layouts, view modes, undo/redo, hooks, and pluggable datasources.

## Features

- Adaptive layouts that fit the current window (compact vs expanded view modes).
- Column highlighting, statusline integration, horizontal scrolling and full-keyboard navigation.
- Editing workflow with undo/redo history, dirty tracking, and save commands.
- Session restore across restarts, multi-table switching, and horizontal/vertical viewport persistence.
- Hook system (open/save/edit/viewport events) for automation.
- Datasource registry for custom adapters (REST, Excel, Parquet, etc.).

## Installation

### lazy.nvim

```lua
{
  "LetsDrinkSomeTea/data.nvim",
  -- auto-setup runs by default; provide opts to configure
  config = function()
    require("data").setup({
      -- optional datasource registration
      datasources = {
        register = {
          -- rest = require("my_project.adapters.rest"),
        },
        priority = { "sqlite", "csv" },
      },
    })
  end,
}
```

### packer.nvim

```lua
use {
  "LetsDrinkSomeTea/data.nvim",
  config = function()
    require("data").setup()
  end,
}
```

Automatic setup runs as soon as the plugin loads. To opt out (for deferred configuration), set `vim.g.data_auto_setup = false` **before** loading and call `require("data").setup()` manually.

You can also clone and add to `runtimepath` manually.

## Usage

Open a table:

```
:DataOpen path/to/file.csv
```

Navigation & editing (buffer-local keymaps; configurable via `keymaps.enabled = false`):

- `h/j/k/l` move between cells; `<C-d>/<C-u>` page vertically.
- `zL` / `zH` shift the viewport horizontally.
- `gv` toggle view mode (compact ↔ expanded).
- `gi` edit current cell, `gu` undo, `gU` redo.
- `gs` save current table; `]t` / `[t` cycle between sessions.

Statusline text is exposed via `require("data").statusline()`.

## Hooks

React to lifecycle events:

```lua
local data = require("data")

data.on("TableSaved", function(payload)
  vim.notify("Saved " .. payload.source)
end)

data.once("ViewModeChanged", function(payload)
  print("Mode switched to", payload.mode)
end)
```

See [docs/HOOKS.md](docs/HOOKS.md) for the full event list.

## Custom Datasources

Register adapters during setup or at runtime:

```lua
local rest_adapter = require("data.datasources.rest")

require("data").setup({
  datasources = {
    register = {
      rest = rest_adapter,
    },
    priority = { "rest", "sqlite", "csv" },
  },
})

-- Later on
require("data").register_datasource("excel", require("my.adapters.excel"))
```

Resolution order prefers explicit `adapter` option, then `datasources.priority`, then remaining registered adapters. Details in [docs/DATASOURCES.md](docs/DATASOURCES.md).

## Development

- `scripts/ci/run-tests.sh` — run Plenary+Busted specs
- `stylua lua` / `luacheck lua`
- Tests live under `tests/spec/`

Roadmap & design notes are in `ROADMAP.md`, `PROJECT_BOARD.md`, and `docs/`.

Enjoy editing data without leaving Neovim! Contributions welcome.
