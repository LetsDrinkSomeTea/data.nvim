# data.nvim

TUI table viewer/editor for Neovim supporting CSV/TSV/SSV and SQLite out of the box. Features include adaptive column layouts, view modes, per-column highlighting, session management with undo/redo, and extensibility via hooks and datasource adapters.

## Quick Start

```lua
require("data").setup({
  -- Optional: register additional datasources
  datasources = {
    register = {
      rest = require("my_project.adapters.rest"),
    },
    priority = { "rest", "sqlite", "csv" },
  },
})
```

Open a table:

```
:DataOpen path/to/file.csv
```

Keymaps (buffer-local, configurable):

- `hjkl` — move cursor
- `<C-d>/<C-u>` — page down/up
- `zL`/`zH` — horizontal scroll
- `gv` — toggle view mode
- `gi` — edit cell; `gu`/`gU` undo/redo
- `gs` — save; `]t`/`[t` cycle tables

Statusline text available via `require("data").statusline()`.

## Hooks

Hooks let you react to table events:

```lua
local data = require("data")

data.on("TableSaved", function(payload)
  vim.notify("Saved " .. payload.source)
end)
```

See [docs/HOOKS.md](docs/HOOKS.md) for the full list of events.

## Datasource Adapters

Adapters can be registered during setup or at runtime. The framework resolves adapters based on explicit `adapter` option, `datasources.priority`, and fallback iteration.

See [docs/DATASOURCES.md](docs/DATASOURCES.md) for adapter guidelines and examples.

## Development

- `scripts/ci/run-tests.sh` — run Plenary+Busted specs
- `stylua lua` / `luacheck lua`
- Tests live under `tests/spec/`

Enjoy editing data without leaving Neovim! Contributions welcome.
