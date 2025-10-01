# Architektur-Übersicht

## High-Level
```
+--------------------+
| User Interaction   |
| (Keymaps, Commands)|
+---------+----------+
          |
          v
+--------------------+        +------------------+
| Controller Layer   |<------>| Config Provider  |
| (Actions)          |        | (Defaults/User)  |
+---------+----------+        +------------------+
          |
          v
+--------------------+
| State Manager      |
| (Tabellen- & UI-Zustand)
+----+-----------+---+
     |           |
     v           v
+---------+   +-----------------+
| Renderer|   | Data Source Hub |
| (TUI)   |   | (Adapters)      |
+----+----+   +----+------------+
     |             |
     v             v
+---------+   +-----------------+
| Buffer  |   | CSV/SQLite/...  |
| Abstr.  |   | Provider        |
+---------+   +-----------------+
```

## Module
- `core.config`: Lädt Defaults, merge mit Nutzer:innen-Override, stellt Validierung bereit.
- `core.state`: Verwaltet Tabellenmetadaten, Cursor, Filter, Undo/Redo, Dirty Flags.
- `core.actions`: Bündelt Commands (Öffnen, Speichern, Sortieren, Scrollen), ruft Renderer & State an.
- `ui.renderer`: Berechnet Layout (Spaltenbreiten, Farben, Kopfzeilen) und schreibt in Neovim-Buffer.
- `ui.widgets`: Reusable Widgets (Statusline, Scrollbar, Inline-Hinweise).
- `datasources.*`: Adapter pro Quelle (`csv`, `tsv`, `sqlite`, `excel_export`). Gemeinsame `Datasource`-Schnittstelle.
- `plugins`: Registrierung externer Module (Hooks, Themes, Datasource-Provider).
- `commands`: Benutzer-facing Commands, Autocommands, Keymaps.
- `utils`: Helfer für Formatierung, Encoding, IO, Logging.

## Datenfluss
1. **Open**: Command -> `core.actions.open_table` -> `datasources.X.load` -> `core.state.attach_table` -> `ui.renderer.render`.
2. **Edit**: Keymap -> `core.actions.edit_cell` -> `core.state.apply_change` (Undo-Stack) -> `ui.renderer.patch`.
3. **Save**: Command -> `datasources.X.save` via State Snapshot -> Erfolg/Fehler an Statusline.
4. **Switch View**: Command -> `core.state.set_viewmode` -> Renderer recalculates Layout -> Buffer Update.

## Erweiterbarkeit
- **Datasource API**
  - `supports(file_uri|connection_string)`
  - `load(opts) -> table_model`
  - `save(table_model, opts)`
  - Event-Hooks `on_row_change`, `on_schema_change` (optional)
- **Renderer API**
  - `render(table_model, viewport, theme)`
  - `patch(changeset)`
- **Hooks**
  - `TableOpened`, `TableSaved`, `SchemaRefreshed`, `ViewModeChanged` mit Payload.

## Konfiguration
- Default Config in `lua/data/opts.lua` mit:
  - `column_width.strategy` (`auto`, `fixed`, `full`)
  - `view.modes` (`compact`, `expanded`, Custom)
  - `theme.colors` (per column kind / data type)
  - `datasource.priority`
  - `performance` (chunk size, caching)
- Nutzer:innen-Setup via `require("data").setup({ ... })`.

## Persistenz & Undo/Redo
- `core.state.history`: Doppel-Stack (past/future) mit Diffs auf Zellenebene.
- Persistente Snapshots optional in `.data.nvim/<table_id>.json` für Crash-Recovery.

## Tests
- Unit-Tests für Parser (`busted`), Renderer (Snapshot), Actions (Mock-State).
- Integration: Fake-Neovim Buffer + Cursor-Simulation.
- Contract-Tests pro Datasource (Load/Save Roundtrips).
