# File And Asset Naming Policy

Last updated: 2026-07-09

## Goals

- Keep only runtime-ready files inside `project-a`.
- Keep source, reference, candidate, and archived files under `Docs`.
- Make file names searchable, stable, and easy to connect to data IDs.
- Avoid ambiguous names before the project grows.

## Runtime Vs Non-Runtime Files

`project-a/assets` is for files the game actually loads.

Allowed:

- Final runtime art.
- Godot `.import` files paired with final runtime art.
- Assets referenced by scenes, scripts, resources, or data tables.

Not allowed:

- Art generation candidates.
- Source PSD/large originals/reference renders.
- Old versions and before/after comparison images.
- A/B optimization samples and reports.
- Temporary screenshots or work-in-progress previews.

Non-runtime files belong under `Docs`:

```text
Docs/
  Policies/
  ArtSource/
  ArtReference/
  ArtArchive/
  ArtReports/
```

Use these meanings:

| State | Location | Meaning |
| --- | --- | --- |
| `active` | `project-a/assets` | Loaded by the game. |
| `source` | `Docs/ArtSource` | Editable originals or useful working files. |
| `reference` | `Docs/ArtReference` | Visual references and generation candidates. |
| `archive` | `Docs/ArtArchive/YYYY-MM-DD_reason` | Not used now, but kept temporarily. |
| `delete` | Removed after review | Duplicate, broken, or easily regenerated. |

## Naming Style

Runtime file names use lowercase `snake_case`.

Use:

```text
tsuki_long_sword_slash.png
mire_imp_spritesheet.png
ui_status_icon.png
fx_heroine_slash.png
```

Avoid:

```text
Final.png
new_card.png
CardArt2.png
빙점 칼날.png
tsuki_spritesheet.png
```

Rules:

- Use English IDs in file names.
- Keep Korean display names in data tables and UI text only.
- Do not use spaces.
- Do not use `new`, `final`, `final2`, `test`, or `before` in runtime file names.
- Use `v001`, `v002` only for source/archive files, not final runtime files.

## Card Art

Runtime card art lives here:

```text
project-a/assets/card/cardart_full/
```

Card art names include the owner character key:

```text
<character_id>_<card_id>.png
```

Examples:

```text
tsuki_long_sword_slash.png
tsuki_high_speed_slash.png
tsuki_freezing_blade.png
```

The `<card_id>` part should match the card data ID. The `<character_id>` part should match the card data character key.

This prevents collisions when multiple characters have cards with similar names.

## Character Art

Runtime character spritesheets live here:

```text
project-a/assets/characters/spritesheets/
```

Use:

```text
tsuki_spritesheet.png
tsuki_spritesheet_chromakey.png
card_magician_spritesheet.png
```

## Monster Art

Runtime monster spritesheets live here:

```text
project-a/assets/monster/spritesheets/
```

Use:

```text
mire_imp_spritesheet.png
gravebound_crawler_spritesheet.png
abyssal_crown_guardian_spritesheet.png
```

## UI, Stage, And VFX

Use role-first names:

```text
ui_sheet.png
ui_status_icon.png
bg_title.png
stage_1.png
fx_slash.png
fx_heroine_slash.png
```

## Cleanup Workflow

1. Confirm whether a file is referenced by scripts, scenes, resources, or generated data.
2. If it is used, keep it in `project-a/assets` and rename it only with references updated.
3. If it is not used but may matter later, move it to `Docs/ArtArchive/YYYY-MM-DD_reason`.
4. If it is a source or reference file, move it to `Docs/ArtSource` or `Docs/ArtReference`.
5. Delete only after archive review.

## Godot Import Files

- Keep `.import` files for active runtime assets.
- When moving files out of `project-a/assets`, move or remove the paired `.import` file too.
- After renaming runtime assets, run Godot import once so `.godot/imported` is refreshed.
