# Asset Naming Audit 2026-07-09

This audit lists runtime image assets that still do not follow the naming policy in
`Docs/Policies/File_And_Asset_Naming_Policy.md`.

## Summary

| Area | Runtime images | Status |
| --- | ---: | --- |
| Card art | 8 | Done: `tsuki_<card_id>.png` |
| Card frame | 1 | Rename candidate |
| Character spritesheets | 5 | Referenced runtime files renamed; archive candidates remain |
| Monster spritesheets | 8 | Done: `<monster_id>_spritesheet.png` |
| Stage | 1 | Done: `stage_1.png` |
| UI | 4 | Core files renamed, one possible unused file |
| VFX | 2 | Main referenced file renamed, one possible unused file |

## Completed

| Current path | Status |
| --- | --- |
| `project-a/assets/card/cardart_full/tsuki_feint_strike.png` | Policy compliant |
| `project-a/assets/card/cardart_full/tsuki_freezing_blade.png` | Policy compliant |
| `project-a/assets/card/cardart_full/tsuki_high_speed_slash.png` | Policy compliant |
| `project-a/assets/card/cardart_full/tsuki_iceberg_cleave.png` | Policy compliant |
| `project-a/assets/card/cardart_full/tsuki_let_flow.png` | Policy compliant |
| `project-a/assets/card/cardart_full/tsuki_long_sword_slash.png` | Policy compliant |
| `project-a/assets/card/cardart_full/tsuki_steal_slash.png` | Policy compliant |
| `project-a/assets/card/cardart_full/tsuki_suppress_ready.png` | Policy compliant |
| `project-a/assets/stage/stage_1.png` | Policy compliant |
| `project-a/assets/ui/bg_title.png` | Policy compliant |
| `project-a/assets/ui/ui_map.png` | Policy compliant |
| `project-a/assets/ui/ui_sheet.png` | Policy compliant |
| `project-a/assets/vfx/fx_heroine_slash.png` | Policy compliant |
| `project-a/assets/monster/spriteSheet/abyssal_crown_guardian_spritesheet.png` | Policy compliant |
| `project-a/assets/monster/spriteSheet/bog_stalker_spritesheet.png` | Policy compliant |
| `project-a/assets/monster/spriteSheet/bone_crawler_spritesheet.png` | Policy compliant |
| `project-a/assets/monster/spriteSheet/crown_acolyte_spritesheet.png` | Policy compliant |
| `project-a/assets/monster/spriteSheet/frost_revenant_spritesheet.png` | Policy compliant |
| `project-a/assets/monster/spriteSheet/gravebound_crawler_spritesheet.png` | Policy compliant |
| `project-a/assets/monster/spriteSheet/mire_imp_spritesheet.png` | Policy compliant |
| `project-a/assets/monster/spriteSheet/monster_dummy_spritesheet.png` | Policy compliant |
| `project-a/assets/characters/spritesheets/tsuki_spritesheet.png` | Policy compliant |
| `project-a/assets/characters/spritesheets/card_magician_spritesheet.png` | Policy compliant |

## Recommended Runtime Renames

| Current path | Recommended path | Reference notes |
| --- | --- | --- |
| `project-a/assets/card/cardframe/CardDummy.png` | `project-a/assets/card/cardframe/card_frame_dummy.png` | Referenced by `CardFrame_*.tres` |
| `project-a/assets/characters/spritesheets/HeroineSheet_TsukiNew_chromakey.png` | `Docs/ArtSource/characters/spritesheets/tsuki_spritesheet_chromakey_source.png` | No direct runtime reference found |
| `project-a/assets/characters/spritesheets/HeroineSheet_CardMagician_chromakey.png` | `Docs/ArtSource/characters/spritesheets/card_magician_spritesheet_chromakey_source.png` | No direct runtime reference found |
| `project-a/assets/characters/spritesheets/HeroineSheet.png` | `Docs/ArtArchive/2026-07-09_asset_naming_candidates/characters/HeroineSheet.png` | No direct runtime reference found |
| `project-a/assets/ui/UIStatusIcon.png` | `project-a/assets/ui/ui_status_icon.png` or archive | No direct runtime reference found |
| `project-a/assets/vfx/FX_Slash.png` | `project-a/assets/vfx/fx_slash.png` or archive | No direct runtime reference found |

## Suggested Next Migration Batch

Next, archive or rename likely unused runtime files after one more reference pass:

Leave possible unused files for a separate archive pass:

- `HeroineSheet.png`
- `HeroineSheet_TsukiNew_chromakey.png`
- `HeroineSheet_CardMagician_chromakey.png`
- `UIStatusIcon.png`
- `FX_Slash.png`
