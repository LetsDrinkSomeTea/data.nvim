# FEATURES

## Kernfunktionen
- Lesen und Schreiben von CSV-, SSV-, TSV- und SQLite-Tabellen direkt in Neovim.
- Fixierung der Tabellenansicht auf die aktuelle Bildschirmgröße mit dynamischem Reflow.
- Smarte Spaltenbreiten mit automatischer Anpassung an Inhalt und verfügbarem Platz.
- Umschaltbar zwischen geklippten Spalten (angepasst an den Bildschirm) und voller Spaltenbreite mit horizontalem Scrollen.
- Schnelles Umschalten zwischen unterschiedlichen Tabellenansichten (z. B. Rohdaten, gefilterte Sicht, Pivot-Sicht).
- Anzeigen von mehreren Tabellenblättern, wenn eine sqlite datei o.ä. geladen wird.
- Farbige Hervorhebung einzelner Spalten und klar erkennbare Überschriftenzeilen.

## Mehrere Datenquellen
- Unterstützung für mehrere Tabellenquellen gleichzeitig (z. B. mehrere SQLite-Datenbanken, CSV-Dateien oder Excel-Exporte).
- Tab- oder Puffer-basierter Workflow, um nahtlos zwischen Quellen zu wechseln.
- Lazy Loading und Streaming großer Dateien, um Speicher zu sparen.

## Navigation & Interaktion
- Tastenkürzel für effizientes Navigieren, Editieren, Filtern und Sortieren.
- Such- und Filterfunktionen mit optionaler Regex-Unterstützung.
- Kontextmenüs (via Command-Palette) für häufige Aktionen wie Spaltentyp ändern, Spalten hinzufügen/löschen.
- Inline-Validierung von Eingaben (z. B. Datentyp, Pflichtfelder).

## Darstellung & Layout
- Anpassbare Farbthemen, abgestimmt auf das aktive Neovim Color Scheme.
- Visuelle Marker für aktuelle Zeile/Spalte, Primärschlüssel, Fremdschlüssel.
- Fixierbare Kopfzeilen und optionale Fußzeilen mit Summen oder Statistiken.
- Unterstützung für kombinierte Text- und Zahlenformate (z. B. Datum, Währung) mit formatierter Anzeige.

## Erweiterbarkeit & Modularität
- Klare API für das Registrieren neuer Datenquellen (z. B. REST, Parquet) oder Layout-Module.
- Plugin-Architektur, die Adapter für Parser, Renderer, Aktionen und Themes trennt.
- Ereignishooks (Autocommands) für Integrationen mit anderen Plugins (z. B. Telescope, DAP, LSP).

## Konfiguration & Defaults
- Umfassbare, aber optionale Konfiguration mit sinnvollen Defaultwerten.
- Setup-Funktion mit Lua-Tabellen und Beispieldatei für Nutzer:innen.
- Presets für unterschiedliche Workflows (z. B. Datenanalyse, CSV-Editing, SQL-Administration).
- Dokumentierte Keymaps, Commands und Lua-APIs.

## Qualität & Testing
- Unit- und Integrationstests für Parser, Renderer und speicherndes Verhalten.
- Benchmark- und Regressionstests für große Datensätze.
- CI-Pipeline mit statischer Analyse (stylua, luacheck) und Kompatibilitätsprüfungen für unterschiedliche Neovim-Versionen.

## UX-Extras
- Undo-/Redo-Stack pro Tabelle mit Persistenzoptionen.
- Änderungsverfolgung (Diff-Ansicht gegenüber Originaldatei oder komplexeren Revisionen).
- Exportfunktionen in verschiedene Formate (CSV, TSV, JSON, SQL-Skripte).
- Statusline-Integration mit Info zu Cursorposition, Filterstatus, Sortierung, Änderungen.
