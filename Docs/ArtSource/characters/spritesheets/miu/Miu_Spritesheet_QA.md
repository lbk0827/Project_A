# Miu Spritesheet QA

## Files

- Runtime candidate: `project-a/assets/characters/spritesheets/miu_spritesheet.png`
- Character scene: `project-a/scenes/characters/miu.tscn`
- Source chroma-key sheet: `Docs/ArtSource/characters/spritesheets/miu/miu_spritesheet_chromakey_source.png`
- Transparent working sheet: `Docs/ArtSource/characters/spritesheets/miu/miu_spritesheet_transparent_4x7_181x181.png`
- Preview: `Docs/ArtSource/characters/spritesheets/miu/miu_spritesheet_preview.png`
- QA folder: `Docs/ArtSource/characters/spritesheets/miu/qa/`

## Runtime Format

- Layout: 4 columns x 7 rows
- Frame count: 28
- Cell size: 181x181
- Sheet size: 724x1267
- Background: transparent RGBA
- Source method: chroma-key generation, component detection, per-frame relayout

The generated source produced 28 stable full-body character components. The final sheet keeps the stable frames rather than inventing extra duplicate frames.

## Animation Mapping

- `Idle`: frames 0-3
- `Attack`: frames 4-11
- `Run`: frames 12-19
- `Hit`: frames 20-23
- `Dead`: frames 24-27

Suggested speeds:

- `Idle`: 5 FPS, loop
- `Attack`: 14 FPS, no loop
- `Run`: 12 FPS, loop
- `Hit`: 5 FPS, no loop
- `Dead`: 7 FPS, no loop

## Attack Behavior Note

Miu is a handgun character. Her `Attack` animation is a stationary draw, aim, fire, recoil, and recovery sequence. Runtime attack logic should not move Miu toward the monster before this animation.

`miu.tscn` uses `heroine_controller.gd` with `move_to_attack_position = false` and `attack_fx_enabled = false`. `ingame.gd` checks this flag before the player attack approach/return dash, so Miu can fire from her current position without spawning the default slash VFX.

## QA Result

See `qa/miu_frame_bbox_report.txt` for numeric details.

- Edge risk frames: none
- Width range: 51-176px
- Height range: 62-174px
- Average height: 155.0px

Down/dead frames are naturally shorter, but every frame fits inside its 181x181 cell.
