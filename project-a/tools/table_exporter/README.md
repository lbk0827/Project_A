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
| 2 | `#data` | `id` | `card_key` | `percent` |
| 3 | | `key,string` | `string` | `int,null` |
| 4 | | `data` | `data` | `data` |
| 5 | | `tsuki_slash_damage` | `tsuki/slash` | `100` |

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
- `character_cards` owns card identity, presentation, keyword tags, and text templates.
- `card_effect_rows` owns authored card behavior. Add a row for each effect and use `card_key` (`character/id`) plus `trigger` (`on_play`, `on_inspiration`, `on_discard`, etc.) instead of adding keyword-specific columns.
- Balance-facing workbooks should prefer explicit primitive columns over `json` cells so designers can filter, sort, and tune each value directly.
- Use `text_template` placeholders such as `{0}` with `card_effect_rows.text_arg_index` so description numbers come from tunable columns.
- `CharacterRPSkills.xlsx` owns character RP accumulation settings and RP skill definitions.
- Formula cells are read from Excel's saved cached values. Open and save the workbook in Excel after changing formulas.
- Sheets are exported only when cell `A2` is `#data`.
- Output file names use the sheet name, for example sheet `character_cards` exports to `character_cards.json`.
