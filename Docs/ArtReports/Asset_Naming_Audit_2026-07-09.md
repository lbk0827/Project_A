# Asset Naming Audit 2026-07-09

This audit lists runtime image assets that still do not follow the naming policy in
`Docs/Policies/File_And_Asset_Naming_Policy.md`.

## Summary

| Area | Runtime images | Status |
| --- | ---: | --- |
| Card art | 8 | Done: `tsuki_<card_id>.png` |
| Card frame | 1 | Done: `card_frame_dummy.png` |
| Character spritesheets | 2 | Referenced runtime files renamed; unused candidates archived |
| Monster spritesheets | 8 | Done: `<monster_id>_spritesheet.png` |
| Stage | 1 | Done: `stage_1.png` |
| UI | 3 | Core files renamed; unused candidate archived |
| VFX | 1 | Referenced file renamed; unused candidate archived |

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
| `project-a/assets/card/cardframe/card_frame_dummy.png` | Policy compliant |

## Archived Runtime Candidates

| Original path | Archive path | Reference notes |
| --- | --- | --- |
| `project-a/assets/characters/spritesheets/HeroineSheet.png` | `Docs/ArtArchive/2026-07-09_unused_runtime_candidates/project-a/assets/characters/spritesheets/HeroineSheet.png` | No direct runtime reference found |
| `project-a/assets/characters/spritesheets/HeroineSheet_TsukiNew_chromakey.png` | `Docs/ArtArchive/2026-07-09_unused_runtime_candidates/project-a/assets/characters/spritesheets/HeroineSheet_TsukiNew_chromakey.png` | No direct runtime reference found |
| `project-a/assets/characters/spritesheets/HeroineSheet_CardMagician_chromakey.png` | `Docs/ArtArchive/2026-07-09_unused_runtime_candidates/project-a/assets/characters/spritesheets/HeroineSheet_CardMagician_chromakey.png` | No direct runtime reference found |
| `project-a/assets/ui/UIStatusIcon.png` | `Docs/ArtArchive/2026-07-09_unused_runtime_candidates/project-a/assets/ui/UIStatusIcon.png` | No direct runtime reference found |
| `project-a/assets/vfx/FX_Slash.png` | `Docs/ArtArchive/2026-07-09_unused_runtime_candidates/project-a/assets/vfx/FX_Slash.png` | No direct runtime reference found |

## Suggested Next Migration Batch

Runtime image naming is now policy-compliant for the audited set.

Possible follow-up: normalize folder casing such as `project-a/assets/monster/spriteSheet`.
