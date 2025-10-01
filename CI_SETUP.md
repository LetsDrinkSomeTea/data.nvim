# CI & Testing Setup Plan

## Tooling
- **Formatter**: Stylua (install via GitHub Release zips, config in `stylua.toml`).
- **Linter**: Luacheck (install via luarocks, config in `.luacheckrc`).
- **Test Runner**: Plenary+Busted (`scripts/ci/run-tests.sh` lädt Abhängigkeiten und führt Suites aus).
- **Static Checks**: Optional `selene` für erweitertes Linting (Phase M4).
- **Optionale Abhängigkeit**: `sqlite3` CLI, um SQLite-bezogene Specs lokal laufen zu lassen.

## GitHub Actions Workflow (`.github/workflows/ci.yml`)
1. Checkout Repo.
2. Setup LuaJIT + Luarocks.
3. Install Stylua und Luacheck.
4. Installiere Neovim (Matrix `stable`, `nightly`).
5. Führe Formatter/Linter nur aus, wenn `lua/` existiert (vermeidet frühe Fehlermeldungen).
6. Starte Tests via Skript `scripts/ci/run-tests.sh` (falls vorhanden).

## Test-Skript (zu erstellen)
`scripts/ci/run-tests.sh`
- Lädt Plugin in temporäres Runtimepath.
- Installiert Abhängigkeiten (`plenary.nvim`) via Git-Checkout oder Paketmanager.
- Führt `nvim --headless` mit `PlenaryBustedDirectory` aus und propagiert Exitcode.
- Akzeptiert Neovim-Version als Parameter (Matrix).

## Verzeichnis-Layout (geplant)
```
lua/
  data/
    init.lua          -- Plugin entrypoint
    core/
    ui/
    datasources/

tests/
  minimal_init.lua    -- setzt runtimepath & lädt Plugin
  spec/
    <feature>_spec.lua

scripts/
  ci/
    run-tests.sh      -- s. o.

.github/workflows/
  ci.yml
```

## Nächste Schritte
- `scripts/ci/run-tests.sh` implementieren, inkl. optionaler Cache für Dependencies.
- `tests/spec` mit ersten Parser-, Renderer- und Action-Tests befüllen.
- Evaluiere Add-ons wie Coverage (`nvim-coverage`) in späteren Phasen.
- Ergänze Badges (Build, Coverage) im zukünftigen `README.md`.
