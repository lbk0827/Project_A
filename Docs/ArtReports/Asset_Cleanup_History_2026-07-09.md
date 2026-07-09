# Asset Cleanup History 2026-07-09

This document records the file cleanup and naming convention work completed on
2026-07-09.

## Purpose

- Keep runtime-ready files in `project-a/assets`.
- Move unused, source, reference, and archive candidates under `Docs`.
- Standardize runtime image names to lowercase `snake_case`.
- Make card art ownership explicit with character-prefixed names such as
  `tsuki_<card_id>.png`.
- Keep Godot resource references and `.import` files synchronized after renames.

## Policy Documents

| Document | Purpose |
| --- | --- |
| `Docs/Policies/File_And_Asset_Naming_Policy.md` | Runtime vs non-runtime rules, naming style, cleanup workflow |
| `Docs/ArtReports/Asset_Naming_Audit_2026-07-09.md` | Audited runtime image list and final naming state |
| `Docs/Art_Resource_Audit.md` | Resource location and active/archive summary |
| `Docs/Art_Import_Settings.md` | Texture import settings by asset category |

## Completed Work

| Area | Result |
| --- | --- |
| Card art | Renamed Tsuki card art to `tsuki_<card_id>.png` and updated generated card data references |
| Card data | Added character ownership to card data so file names can be generated predictably |
| Card frame | Renamed `CardDummy.png` to `card_frame_dummy.png` and updated `CardFrame_*.tres` references |
| Character spritesheets | Renamed active sheets to `tsuki_spritesheet.png` and `card_magician_spritesheet.png` |
| Monster spritesheets | Renamed monster files to `<monster_id>_spritesheet.png` |
| Monster folder | Normalized `project-a/assets/monster/spriteSheet` to `project-a/assets/monster/spritesheets` |
| Stage/UI/VFX | Renamed active files such as `stage_1.png`, `bg_title.png`, `ui_map.png`, `ui_sheet.png`, and `fx_heroine_slash.png` |
| Unused runtime candidates | Moved unreferenced candidates to `Docs/ArtArchive/2026-07-09_unused_runtime_candidates` |
| Non-runtime import files | Moved stale `Docs/ArtSource/**/*.import` files to `Docs/ArtArchive/2026-07-09_docs_import_files` |

## Commit History

| Commit | Summary |
| --- | --- |
| `48cd495` | `chore(assets): standardize runtime asset names` |
| `a9901e2` | `chore(assets): rename monster spritesheets` |
| `bfa1ac8` | `chore(assets): rename character spritesheets` |
| `30c9b25` | `chore(assets): archive unused runtime images` |
| `802bc16` | `chore(assets): normalize monster spritesheet folder` |

## Validation

- Ran Godot headless import after runtime asset renames.
- Confirmed old runtime references such as `CardDummy.png`, `spriteSheet`,
  `UIStatusIcon.png`, and `FX_Slash.png` no longer remain under `project-a`.
- Confirmed active runtime image files under `project-a/assets` follow the naming
  policy.
- Confirmed active `.import` files point to existing source files.

Known local note: Godot reported an editor settings save warning for
`C:/Users/DG-2507-PC-061/AppData/Roaming/Godot/editor_settings-4.6.tres`, but
asset imports completed successfully.

## Current Runtime Image Set

Active runtime images now remain in these groups:

- `project-a/assets/card/cardart_full/tsuki_*.png`
- `project-a/assets/card/cardframe/card_frame_dummy.png`
- `project-a/assets/characters/spritesheets/*.png`
- `project-a/assets/monster/spritesheets/*.png`
- `project-a/assets/stage/stage_1.png`
- `project-a/assets/ui/bg_title.png`
- `project-a/assets/ui/ui_map.png`
- `project-a/assets/ui/ui_sheet.png`
- `project-a/assets/vfx/fx_heroine_slash.png`

## Follow-Up Candidates

- Decide whether the existing untracked `tmp/` folder should be ignored,
  archived, or removed.
- Add an automated asset naming check to the project workflow if the asset set
  starts growing quickly.
