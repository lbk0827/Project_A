# Momoka Spritesheet QA

## Files

- Runtime candidate: `project-a/assets/characters/spritesheets/momoka_spritesheet.png`
- Character scene: `project-a/scenes/characters/momoka.tscn`
- Source chroma-key sheet: `Docs/ArtSource/characters/spritesheets/momoka/momoka_spritesheet_chromakey_source.png`
- Transparent working sheet: `Docs/ArtSource/characters/spritesheets/momoka/momoka_spritesheet_transparent_4x8_181x181.png`
- Preview: `Docs/ArtSource/characters/spritesheets/momoka/momoka_spritesheet_preview.png`
- QA folder: `Docs/ArtSource/characters/spritesheets/momoka/qa/`

## Runtime Format

- Layout: 4 columns x 8 rows
- Frame count: 32
- Cell size: 181x181
- Sheet size: 724x1448
- Background: transparent RGBA
- Source method: chroma-key generation, component detection, per-frame relayout

The generated source did not produce a true Tsuki-style 4x12 sheet. It produced 32 usable character components. The final runtime candidate keeps those 32 frames instead of inventing empty or duplicate rows.

## Suggested Animation Mapping

- `Idle`: frames 0-3
- `Attack`: frames 4-7
- `Run`: frames 8-15
- `Hit`: frames 16-23
- `Dead`: frames 24-31

Suggested speeds:

- `Idle`: 5 FPS, loop
- `Attack`: 14 FPS, no loop
- `Run`: 12 FPS, loop
- `Hit`: 5 FPS, no loop
- `Dead`: 7 FPS, no loop

## QA Result

See `qa/momoka_frame_bbox_report.txt` for numeric details.

- Edge risk frames: none
- Width range: 58-176px
- Height range: 55-174px
- Average height: 140.6px

The lower average height is expected because the last rows contain kneeling and down/dead frames. Standing, attack, run, and hit frames remain close to the Tsuki/Yuki runtime scale.

## Notes

- The character has no weapon and uses kick-based martial arts attacks.
- Attack frames intentionally avoid slash trails and VFX.
- Some tiny dark edge remnants are preserved where removing more pixels could damage black hair, blazer edges, or skirt outlines.
- `momoka.tscn` uses the frame mapping above in an `AnimatedSprite2D`.
