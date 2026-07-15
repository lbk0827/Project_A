# Yuki V2 스프라이트 작업 노트

## 작업 목적

기존 Yuki 스프라이트는 Tsuki 기반 색상 변형처럼 보이는 인상이 강했습니다. 이번 버전은 프레임 구조와 애니메이션 매핑은 유지하면서, 캐릭터 실루엣을 Yuki 고유 방향으로 개선하는 것을 목표로 했습니다.

## 반영 내용

- 포니테일처럼 읽히던 머리 실루엣을 느슨한 웨이비 롱헤어로 변경했습니다.
- Tsuki 계열 의상처럼 보이던 뒤쪽 망토/긴 뒷자락 느낌을 줄였습니다.
- 파란색과 흰색 중심의 Yuki 의상 방향성은 유지했습니다.
- Godot 씬의 기존 AtlasTexture 좌표가 깨지지 않도록 최종 스프라이트 크기를 `724x1629`로 유지했습니다.
- 기존 `4x9`, `181x181` 셀 구조를 유지했습니다.

## 산출물

- `yuki_spritesheet_v2_chromakey_source.png`
  - 이미지 편집 결과의 크로마키 원본입니다.
  - 녹색 배경 제거 전 원본 보관용입니다.
- `yuki_spritesheet_v2_transparent_724x1629.png`
  - 배경 제거와 크기 보정을 완료한 최종 투명 PNG입니다.
  - 프로젝트 실제 적용본과 동일한 이미지입니다.
- `project-a/assets/characters/spritesheets/yuki_spritesheet.png`
  - 게임에서 실제로 참조하는 적용본입니다.

## 적용 방식

`project-a/scenes/characters/yuki.tscn`은 기존처럼 `res://assets/characters/spritesheets/yuki_spritesheet.png`를 참조합니다. 따라서 씬의 AtlasTexture, SpriteFrames, 애니메이션 이름은 변경하지 않았습니다.

현재 Yuki 씬에서 사용하는 애니메이션은 다음 6종입니다.

- `Idle`
- `Walk`
- `Run`
- `Attack`
- `Hit`
- `Dead`

## 주의 사항

- 크로마키 제거 기반 후처리를 사용했기 때문에 머리카락처럼 복잡한 가장자리에는 미세한 색 잔여가 있을 수 있습니다.
- 향후 품질을 더 올릴 경우, 동일한 `4x9`, `181x181`, `724x1629` 구조를 유지한 상태에서 가장자리 정리를 추가로 진행하는 것이 안전합니다.
- 기존 씬 좌표와 애니메이션 매핑을 유지하려면 프로젝트 적용본의 캔버스 크기를 변경하지 않아야 합니다.
