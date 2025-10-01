# ROADMAP

## Phase 0 · Projektstruktur (Woche 1) — ✅ Abgeschlossen
- [x] Repository-Grundstruktur mit Lua-Modulen, Tests, Beispieldateien.
- [x] Setup-Skripte für stylua, luacheck, CI-Workflow.
- [x] Plugin-API-Contracts (Datenquellen, Renderer, Actions, Themes) abgesteckt.

## Phase 1 · Basisfunktionen (Wochen 2-4) — 🔄 Laufend
- [x] CSV/TSV/SSV-Parser und Writer inklusive Encoding-Handling.
- [x] SQLite-Adapter (Lesen/Schreiben, Tabellenliste) über `sqlite3` CLI realisiert.
- [x] Puffer-Rendering mit Bildschirm-Fixierung und smarten Spaltenbreiten.
- [x] Grundlegende Navigation (Cursor, Scrollen, PageUp/Down, Jump-to-Cell).
- [x] Persistente Speicherpfade & Session-Restore für Mehrquellen-Workflows.

## Phase 2 · Darstellung & Interaktion (Wochen 5-7)
- [x] Farbige Spalten & klar markierte Kopfzeilen (Theme-Palette, Highlighting).
- [ ] Statusline-Integration und Fokus-Indikatoren.
- [ ] Umschaltbare Ansichten (gekürzte vs. Vollbreite) mit horizontalem Scrollen.
- [~] Konfigurierbare Commands (User Commands vorhanden; Default-Keymaps folgen).
- [ ] Undo/Redo-Stack pro Tabelle und Änderungs-Tracking.

## Phase 3 · Erweiterbare Module (Wochen 8-9) — ⏳ Geplant
- Plugin-Hooks und Autocommands für externe Integrationen (Telescope, LSP).
- API für zusätzliche Datenquellen & Renderer-Layouts.
- Presets für typische Workflows (Analyse, SQL, CSV-Editing).

## Phase 4 · Performance & Stabilität (Woche 10) — ⏳ Geplant
- Lazy Loading, Streaming großer Dateien, Benchmarks.
- Integrationstests für kritische Pfade, Regressionstests mit großen Datensätzen.
- Stabilisierung der Konfiguration, Dokumentation der Lua-APIs.

## Phase 5 · Release & Community (Woche 11+) — ⏳ Geplant
- Komplettes Nutzerhandbuch, Tutorial-Recording oder GIF-Demos.
- Release-Tagging, Changelog, Beitragsrichtlinien (CONTRIBUTING.md).
- Roadmap-Review, Feedback-Schleifen mit ersten Nutzer:innen.
