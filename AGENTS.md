# Repository Guidelines

## Project Structure & Module Organization
- Core plugin lives under `lua/data/` with submodules: `core/` (state, actions), `datasources/` (CSV, SQLite adapters), `ui/` (layout, renderer).
- User-facing commands live in `lua/data/commands.lua`; `lua/data/init.lua` exposes helper API wrappers.
- CI scripts reside in `scripts/ci/`; GitHub workflow definitions under `.github/workflows/`.
- Specs live in `tests/spec/`, bootstrapped by `tests/minimal_init.lua` and dependencies cached in `tests/.deps/`.
- Documentation and planning assets (`FEATURES.md`, `ROADMAP.md`, `PROJECT_BOARD.md`, `ARCHITECTURE.md`, `CI_SETUP.md`) sit in the repo root.

## Build, Test, and Development Commands
- `scripts/ci/run-tests.sh` — runs headless Neovim tests via Plenary+Busted (requires cached `tests/.deps/plenary.nvim`).
- `stylua lua` — formats Lua sources per `stylua.toml`.
- `luacheck lua` — static linting aligned with `.luacheckrc` rules.

## Coding Style & Naming Conventions
- Lua code: 2-space indentation, double quotes preferred, lines ≤100 columns (see `stylua.toml`).
- Module names snake_case; public APIs exposed via `lua/data/init.lua` and nested modules follow `data.<area>.<module>`.
- Maintain concise inline comments for complex logic; avoid redundant narration.
- Column farbpalette konfigurierst du über `theme.column_palette` (Index- oder Namenszuordnung, plus Fallback-HL-Gruppe).
- User Commands erhalten CamelCase (`DataOpen`, `DataMove`); ergänzende Lua-Funktionen bleiben snake_case.

## Testing Guidelines
- Framework: Plenary+Busted; place specs as `<feature>_spec.lua` under `tests/spec/`.
- Keep fixtures lightweight; share helpers via `tests/spec/support/` if needed.
- Ensure new features ship with matching specs; run `scripts/ci/run-tests.sh` before pushing.
- SQLite-spezifische Specs benötigen das optionale `sqlite3` CLI; ohne installiertes Binary werden sie übersprungen.

## Commit & Pull Request Guidelines
- Write commits in imperative mood (`Add CSV header handling`); keep scope focused.
- Reference issues in commit body or PR description (`Fixes #12`).
- PRs should summarize changes, list testing evidence (`scripts/ci/run-tests.sh`), and include screenshots/GIFs for UI updates.

## Architecture Notes
- Datasources implement `supports/load/save`; register via `data.datasources.registry`.
- Renderer relies on `data.ui.layout` for smart column sizing; keep layout pure and buffer-side effects inside `data.ui.renderer`.
