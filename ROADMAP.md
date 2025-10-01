# ROADMAP

## Phase 0 · Projektstruktur (Woche 1)
- Repository-Grundstruktur mit Lua-Modulen, Tests, Beispieldateien.
- Setup-Skripte für stylua, luacheck, CI-Workflow.
- Definieren der Plugin-API (Datenquellen, Renderer, Actions, Themes).

## Phase 1 · Basisfunktionen (Wochen 2-4)
- CSV/TSV/SSV-Parser und Writer inklusive Encoding-Handling.
- SQLite-Adapter (Lesen/Schreiben, Tabellenliste, Statement-Ausführung).
- Puffer-Rendering mit Bildschirm-Fixierung und smarten Spaltenbreiten.
- Grundlegende Navigation (Cursor, Scrollen, PageUp/Down, Jump-to-Cell).

## Phase 2 · Darstellung & Interaktion (Wochen 5-7)
- Farbige Spalten, deutlich abgesetzte Kopfzeilen, Statusline-Integration.
- Umschaltbare Ansichten (gekürzte vs. Vollbreite) mit horizontalem Scrollen.
- Konfigurierbare Keymaps, Commands, Setup-Defaults.
- Undo/Redo-Stack pro Tabelle und Änderungs-Tracking.

## Phase 3 · Erweiterbare Module (Wochen 8-9)
- Plugin-Hooks und Autocommands für externe Integrationen (Telescope, LSP).
- API für zusätzliche Datenquellen & Renderer-Layouts.
- Presets für typische Workflows (Analyse, SQL, CSV-Editing).

## Phase 4 · Performance & Stabilität (Woche 10)
- Lazy Loading, Streaming großer Dateien, Benchmarks.
- Integrationstests für kritische Pfade, Regressionstests mit großen Datensätzen.
- Stabilisierung der Konfiguration, Dokumentation der Lua-APIs.

## Phase 5 · Release & Community (Woche 11+)
- Komplettes Nutzerhandbuch, Tutorial-Recording oder GIF-Demos.
- Release-Tagging, Changelog, Beitragsrichtlinien (CONTRIBUTING.md).
- Roadmap-Review, Feedback-Schleifen mit ersten Nutzer:innen.
