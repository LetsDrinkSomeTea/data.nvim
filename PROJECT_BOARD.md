# PROJECT BOARD

## Milestone-Übersicht
| Meilenstein | Zeitraum | Ziel | Status |
|-------------|----------|------|--------|
| M0 · Projektstruktur | Woche 1 | Fundament für Entwicklung, Standards und API definieren | ✅ Abgeschlossen |
| M1 · Basisfunktionen | Wochen 2-4 | Kernfunktionen für Dateiquellen, Rendering und Navigation | 🔄 Laufend |
| M2 · Darstellung & Interaktion | Wochen 5-7 | UI-Veredelung, konfigurierbare Bedienung, Änderungsmanagement | 🛈 Teilfortschritt |
| M3 · Erweiterbarkeit | Wochen 8-9 | Offene API für Datenquellen/Layout, Presets & Integrationen | ⏳ Geplant |
| M4 · Performance & Stabilität | Woche 10 | Skalierbarkeit und Tests absichern | ⏳ Geplant |
| M5 · Release & Community | Woche 11+ | Veröffentlichung, Dokumentation und Feedbackschleifen | ⏳ Geplant |

## Issues nach Meilenstein

### M0 · Projektstruktur (Woche 1)
- [x] Issue #0.1 · Repo-Struktur & Lua-Boilerplate einrichten (Effort: 2 PT)
- [x] Issue #0.2 · Tooling & CI Skeleton (stylua, luacheck, CI-Workflow) vorbereiten (Effort: 1.5 PT)
- [x] Issue #0.3 · Plugin-API-Contracts spezifizieren (Module, Adapter, Hooks) (Effort: 1 PT)

- [x] Issue #1.1 · CSV/TSV/SSV Parser & Writer mit Encoding-Tests (Effort: 3 PT)
- [x] Issue #1.2 · SQLite-Adapter (Lesen/Schreiben, Tabellenliste, Querying) (Effort: 4 PT)
- [x] Issue #1.3 · Buffer-Renderer mit Bildschirmfixierung & smarten Spalten (Effort: 3 PT)
- [ ] Issue #1.4 · Navigation & Scroll-Logik (Line/Column, Page, Wrap) (Effort: 2 PT)
- [ ] Issue #1.5 · Mehrquellen-Workflow (Tabs/Buffers, Persistenz) (Effort: 2 PT)

### M2 · Darstellung & Interaktion (Wochen 5-7)
- [~] Issue #2.1 · Farbschemata, Headline-Styling, Statusline-Integration (Effort: 2 PT) — Spalten-Palette & Header-HL erledigt; Statusline offen.
- [ ] Issue #2.2 · Ansichtsmode-Umschaltung + Horizontal Scroll (Effort: 2.5 PT)
- [ ] Issue #2.3 · Konfigurierbare Keymaps & Commands (Effort: 1.5 PT)
- [ ] Issue #2.4 · Undo/Redo & Änderungs-Tracking (Effort: 2.5 PT)

### M3 · Erweiterbarkeit (Wochen 8-9)
- [ ] Issue #3.1 · Hook-System & Autocommands (Effort: 2 PT)
- [ ] Issue #3.2 · API für zusätzliche Datenquellen & Renderer (Effort: 2.5 PT)
- [ ] Issue #3.3 · Workflow-Presets (Analyse, SQL, CSV) (Effort: 1 PT)

### M4 · Performance & Stabilität (Woche 10)
- [ ] Issue #4.1 · Lazy Loading & Streaming großer Tabellen (Effort: 2 PT)
- [ ] Issue #4.2 · Benchmark-Suite & Regressionstests (Effort: 2.5 PT)
- [ ] Issue #4.3 · Konfiguration finalisieren & API-Dokumentation (Effort: 1.5 PT)

### M5 · Release & Community (Woche 11+)
- [ ] Issue #5.1 · Nutzerhandbuch + Screencasts/GIFs (Effort: 2 PT)
- [ ] Issue #5.2 · Release-Tagging & Changelog (Effort: 1 PT)
- [ ] Issue #5.3 · Feedback-Kanal & Roadmap-Review (Effort: 1 PT)

## Cross-Cutting Tasks
- [ ] Risiko-Backlog pflegen (Abhängigkeiten, Datenformate, Performance)
- [ ] Wöchentliche Syncs, Demo-Termine und Community-Updates planen
- [ ] Ressourcenplanung (Contributor-Zuteilung, Pairing-Slots)

> PT = Personentage (8h). Anpassungen je nach Teamgröße nötig.
> Status-Kürzel: ✅ erledigt · 🔄 laufend · 🛈 Teilfortschritt · ⏳ geplant · [~] Teilaufgabe in Arbeit.
