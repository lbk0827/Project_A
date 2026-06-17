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
| 2 | `#data` | `id` | `cost` | `effects` |
| 3 | | `key,string` | `int` | `json` |
| 4 | | `data` | `data` | `data` |
| 5 | | `slash` | `1` | `[{"type":"damage","amount":6}]` |

Supported types:

- `string`
- `int`
- `float`
- `bool`
- `json`
- arrays via `field_name[]` or `type[]`, for example `tags[]` + `string`

Supported options:

- `key`: marks the unique row key. Required for now.
- `null`: allows an empty or `null` cell to export as JSON `null`.

Usage from `project-a`:

```powershell
python tools/table_exporter/table_exporter.py --input-dir tables/excel --output-dir data/generated --clean
```

On Windows, you can also run:

```powershell
tools/table_exporter/export_tables.bat
```

Notes:

- Formula cells are read from Excel's saved cached values. Open and save the workbook in Excel after changing formulas.
- Sheets are exported only when cell `A2` is `#data`.
- Output file names use the sheet name, for example sheet `cards` exports to `cards.json`.
