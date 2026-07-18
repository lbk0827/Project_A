# Miu Spritesheet QA

## Files

- Runtime candidate: `project-a/assets/characters/spritesheets/miu_spritesheet.png`
- Character scene: `project-a/scenes/characters/miu.tscn`
- Source chroma-key sheet: `Docs/ArtSource/characters/spritesheets/miu/miu_spritesheet_chromakey_source.png`
- Transparent working sheet: `Docs/ArtSource/characters/spritesheets/miu/miu_spritesheet_transparent_4x7_181x181.png`
- Reworked runtime sheet: `Docs/ArtSource/characters/spritesheets/miu/miu_spritesheet_reworked_4x9_181x181.png`
- Preview: `Docs/ArtSource/characters/spritesheets/miu/miu_spritesheet_preview.png`
- QA folder: `Docs/ArtSource/characters/spritesheets/miu/qa/`

## Runtime Format

- Layout: 4 columns x 9 rows
- Frame count: 36
- Cell size: 181x181
- Sheet size: 724x1629
- Background: transparent RGBA
- Source method: 기존 투명 스프라이트를 기준으로 한 프레임 재배치 및 보간

이번 버전은 캐릭터 정체성이 크게 변하지 않도록 원본 미우 스프라이트의 픽셀을 최대한 유지했습니다. 다만 `Idle`, `Attack`, `Hit`는 실제 재생 시 끊겨 보이던 구간이라 프레임 수와 자세 흐름을 재구성했습니다.

## Animation Mapping

- `Idle`: frames 0-5
- `Attack`: frames 6-17
- `Run`: frames 18-25
- `Hit`: frames 26-31
- `Dead`: frames 32-35

Suggested speeds:

- `Idle`: 5 FPS, loop
- `Attack`: 12 FPS, no loop
- `Run`: 12 FPS, loop
- `Hit`: 8 FPS, no loop
- `Dead`: 7 FPS, no loop

## Rework Notes

- `Idle`: 츠키처럼 제자리에서 서 있는 느낌을 유지하도록 원본 대기 프레임을 바닥 기준으로 고정하고, 작은 호흡 변화만 넣었습니다.
- `Attack`: 권총 캐릭터 정체성을 유지하면서 준비, 조준, 발사, 반동, 회수 흐름이 이어지도록 12프레임으로 늘렸습니다.
- `Run`: 이번 요청 범위에서는 기존 달리기 프레임을 유지했습니다. 이후 완전한 교차 다리 달리기를 만들려면 별도 원화 보강이 필요합니다.
- `Hit`: 넘어지거나 이동하지 않고 제자리에서 맞는 느낌만 나도록 몸 위치를 고정한 흔들림 프레임으로 변경했습니다.
- `Dead`: 원본 다운 프레임을 유지했습니다.

## Attack Behavior Note

Miu is a handgun character. Her `Attack` animation is a stationary draw, aim, fire, recoil, and recovery sequence. Runtime attack logic should not move Miu toward the monster before this animation.

`miu.tscn` uses `heroine_controller.gd` with `move_to_attack_position = false` and `attack_fx_enabled = false`. `ingame.gd` checks this flag before the player attack approach/return dash, so Miu can fire from her current position without spawning the default slash VFX.

## QA Result

See `qa/miu_frame_bbox_report.txt` for numeric details.

- Edge risk frames: 32, 33, 34, 35
- Width range: 51-176px
- Height range: 62-164px
- Average height: 147.6px

Edge risk frames are inherited dead poses from the original source. The newly reworked `Idle`, `Attack`, and `Hit` frames fit inside their 181x181 cells without edge contact.
