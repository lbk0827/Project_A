# Monster Action Preview UI

Date: 2026-07-13

## Goal

몬스터를 클릭했을 때 전투 화면 좌측에 행동 예고 UI를 열고, 선택된 몬스터가 화면에서 명확히 표시되도록 했다. UI 바깥 영역을 클릭하면 패널과 선택 표시가 함께 닫힌다.

## User Flow

1. 전투 중 살아있는 몬스터를 클릭한다.
2. 좌측 행동 예고 패널이 열린다.
3. 선택된 몬스터 발밑에 링이 표시되고, 스프라이트가 짧게 하이라이트된다.
4. 다른 몬스터를 클릭하면 선택 대상과 패널 내용이 바뀐다.
5. 패널 바깥 영역이나 닫기 버튼을 누르면 패널과 선택 표시가 닫힌다.

## Implementation

### `scripts/core/ingame.gd`

- `selected_info_enemy`로 현재 행동 예고 대상 몬스터를 추적한다.
- `_select_monster_info()`, `_clear_selected_monster_info()`, `_refresh_selected_monster_info()`로 패널 표시와 몬스터 선택 표시를 동기화한다.
- 전투 종료, 패배, 몬스터 사망, RP 스킬 선택 진입 시 열린 행동 예고 UI를 닫는다.
- 적 행동 카운트가 줄거나 다음 intent로 넘어간 뒤 열린 패널 내용을 갱신한다.
- 클릭 판정은 기준점 반경뿐 아니라 몬스터 스프라이트의 화면 Rect도 사용한다.
- `AnimatedSprite2D`는 `get_rect()`가 없어 현재 프레임 텍스처 크기로 Rect를 직접 계산한다.

### `scripts/monster/monster_actor.gd`

- `set_selected(value: bool)` API를 추가했다.
- 선택 시 런타임으로 `SelectionRing`을 생성해 몬스터 발밑에 타원형 링을 표시한다.
- 선택 해제, 사망, 전투 리셋 시 링과 틴트를 원복한다.
- 몬스터별 조정을 위해 `selection_ring_offset`, `selection_ring_size`를 export했다.

### `scripts/ui/battle_ui.gd`

- 좌측 행동 예고 패널을 전투 HUD 안에서 런타임 생성한다.
- `show_monster_info()`가 몬스터 이름, 행동 카운트, intent 목록, 다음 행동 표시, 피해/방어 수치를 표시한다.
- `is_monster_info_point_inside()`로 패널 내부 클릭은 바깥 클릭 닫힘 처리에서 제외한다.
- 닫기 버튼은 `monster_info_close_requested` 신호로 전투 컨트롤러에 선택 해제를 요청한다.
- `UIRoot`의 `mouse_filter`를 `IGNORE`로 설정해 전체 화면 UI 루트가 월드 클릭을 막지 않도록 했다.

## Notes

- 행동 피해량은 `monster.stats.attack_power * intent.amount / 100`으로 계산해 표시한다.
- 방어 intent는 flat 방어량으로 표시한다.
- 기존 `.import` 변경은 이 기능 구현 범위가 아니므로 커밋 대상에서 제외한다.

## Validation

- `git diff --check` 통과.
- 이 환경에서는 Godot 실행 파일을 찾지 못해 에디터/headless 실행 검증은 하지 못했다.
