# Table Exporter

Small Excel-to-JSON exporter for project data tables.

The layout follows the team's `TABLE SCRIPT` convention in a reduced form:

| Row | Column A | Column B+ |
| --- | --- | --- |
| 1 | optional | optional notes |
| 2 | `#data` | field names |
| 3 | empty | type/options |
| 4 | empty | `data` to export |
| 5+ | optional `skip` | row values |

Example:

| | A | B | C | D |
| --- | --- | --- | --- | --- |
| 2 | `#data` | `Id` | `CardKey` | `Percent` |
| 3 | | `key,string` | `string` | `int,null` |
| 4 | | `data` | `data` | `data` |
| 5 | | `TsukiSlashDamage` | `Tsuki/Slash` | `100` |

Supported types:

- `string`
- `int`
- `float`
- `bool`
- `json`
- arrays via `FieldName[]` or `type[]`, for example `Tags[]` + `string`

Supported options:

- `key`: marks the unique row key. Required for now.
- `null`: allows an empty or `null` cell to export as JSON `null`.

## GUI Usage

For a simple folder-picker GUI on macOS, double-click:

```text
tools/table_exporter/launch_table_exporter.command
```

Or run directly:

```powershell
python tools/table_exporter/table_exporter_gui.py
```

The GUI uses these defaults:

- Excel folder: `tables/excel`
- JSON output folder: `data/generated`
- Clean old JSON files before export: on

## Command Line Usage

Usage from `project-a`:

```powershell
python tools/table_exporter/table_exporter.py --input-dir tables/excel --output-dir data/generated --clean
```

Validate generated Tsuki card data and runtime card art:

```powershell
python tools/table_exporter/validate_card_assets.py
```

On Windows, you can also run:

```powershell
tools/table_exporter/export_tables.bat
```

Notes:

- `CharacterCards.xlsx` is the active card authoring workbook; the old base `CardTable.xlsx` has been retired.
- `CharacterCards` owns card identity, presentation, keyword tags, and text templates.
- `CardEffectRows` owns authored card behavior. Add a row for each effect and use `CardKey` (`Character/Id`) plus `Trigger` (`OnPlay`, `OnInspiration`, `OnDiscard`, etc.) instead of adding keyword-specific columns.
- Balance-facing workbooks should prefer explicit primitive columns over `json` cells so designers can filter, sort, and tune each value directly.
- Use `TextTemplate` placeholders such as `{0}` with `CardEffectRows.TextArgIndex` so description numbers come from tunable columns.
- `CharacterRPSkills.xlsx` owns character RP accumulation settings and RP skill definitions.
- Formula cells are read from Excel's saved cached values. Open and save the workbook in Excel after changing formulas.
- Sheets are exported only when cell `A2` is `#data`.
- Output file names use the sheet name, for example sheet `CharacterCards` exports to `CharacterCards.json`.
