# Work History - 2026-07-13

Branch: `Dev/M1-Prototype`

## Summary

오늘은 전투 루트 선택 UI와 전투 HUD의 시인성 개선, 츠키 초상화 및 몬스터 HP 바 정리, 그리고 기획자/디자이너가 수정하기 어려운 하드코딩 구조 완화 작업을 진행했다.

핵심 방향은 다음과 같다.

- BattleMap Overlay가 빈 씬처럼 보이지 않도록 실제 노드 구조를 씬에 배치한다.
- MiniMap과 NEXT ROUTE UI는 프로젝트의 노드 아이콘을 중심으로 통일한다.
- 츠키 초상화와 HP HUD는 루트 선택 중에도 항상 노출한다.
- 루트 선택 시 캐릭터가 즉시 이동하는 어색함을 줄이기 위해 화면 전환 연출을 추가한다.
- 코드에서 직접 UI를 생성하던 고정 HUD를 씬 노드로 옮겨 기획자/디자이너가 에디터에서 위치와 크기를 조정할 수 있게 한다.
- 맵 루트 노드 배열을 스크립트 상수에서 리소스로 분리한다.

## Committed Changes

### `f566122 feat(map): refine route overlay`

BattleMap Overlay의 MiniMap과 NEXT ROUTE UI를 개선했다.

- MiniMap에서 노드 타입이 아이콘으로 보이도록 정리했다.
- NEXT ROUTE UI에서 불필요하게 섞여 있던 장식 형태를 줄이고, 노드 아이콘과 설명 중심으로 구성했다.
- X, ? 같은 임시 표기성 요소를 제거했다.
- 노드 선택 영역이 더 명확하게 읽히도록 아이콘 중심의 카드 형태로 정리했다.

### `6a0f1a1 feat(ui): add route selection transition`

NEXT ROUTE 선택 후 이동이 갑자기 보이는 문제를 줄이기 위해 화면 전환 연출을 추가했다.

- 좌에서 우로 지나가는 검은 화면 전환을 추가했다.
- 단순 사각형이 쓸고 지나가는 느낌을 줄이기 위해 사선형 wipe와 soft band를 사용했다.
- 전환 중에는 루트 상태 변경과 전투 진입이 자연스럽게 이어지도록 처리했다.

### `6d0dbef feat(ui): add Tsuki portrait asset`

츠키 HP HUD에 사용할 초상화 에셋을 추가하고 반영했다.

- 츠키 전투 HUD용 초상화 이미지를 추가했다.
- 기존 초상화 영역에 얼굴 대신 머리카락 위주로 보이던 문제를 개선했다.
- 루트 선택 화면에서도 츠키 초상화와 HP 게이지가 계속 보이도록 정리했다.

### `0e5922d feat(ui): refine enemy hp bar`

몬스터 HP 바 표시를 카오스 제로 나이트메어 참고 이미지에 가깝게 정리했다.

- 몬스터 HP 수치는 현재 HP만 표시하도록 변경했다.
- HP 수치를 게이지 상단에 걸치도록 배치했다.
- HP 수치가 게이지보다 위 레이어에 보이도록 z-index를 재확인했다.
- 몬스터 intent badge와 HP bar의 시인성을 개선했다.

## In-Progress Changes

아래 항목은 아직 커밋 전 작업이다.

### BattleMap Overlay 씬 노드화

Files:

- `project-a/scenes/ui/battle_map_overlay.tscn`
- `project-a/scripts/ui/battle_map_overlay.gd`

변경 내용:

- 기존에는 `BattleMapOverlay.tscn`이 거의 빈 `CanvasLayer`였고, 실제 UI는 `battle_map_overlay.gd`에서 `Control.new()`, `Panel.new()` 등으로 생성했다.
- 씬에 `UIRoot`, `Scrim`, `MiniMapPanel`, `ChoicePanel`, `ExpandedMap` 노드 구조를 추가했다.
- 스크립트는 `_build_ui()`로 전체 UI를 생성하지 않고, `_bind_ui()`에서 씬 노드를 찾아 스타일과 런타임 동작을 연결하도록 변경했다.
- MiniMap 렌더링 뷰는 `MiniMapViewHost`, `ExpandedMapViewHost` 하위에 생성되도록 정리했다.

디자이너 편집 가능해진 부분:

- MiniMap 패널 위치와 크기
- NEXT ROUTE 패널 위치와 크기
- Expanded Map 패널 위치와 크기
- 제목, 버튼, 상태 라벨, 뷰 호스트 배치

아직 코드에 남은 부분:

- NEXT ROUTE의 선택 버튼 목록은 선택 가능한 노드 수에 따라 런타임에 생성된다.
- 노드 아이콘 atlas region 매핑은 아직 코드에 있다.

### BattleUI 주요 HUD 씬화

Files:

- `project-a/scenes/ui/battle_ui.tscn`
- `project-a/scripts/ui/battle_ui.gd`

변경 내용:

- 츠키 초상화/HP 패널을 씬 노드로 추가했다.
- EP 게이지, 중앙 에너지 숫자, 손패 카운터, 턴 칩을 씬 노드로 추가했다.
- `_build_player_panel()`, `_build_energy_gauge()`, `_build_energy_orb()`, `_build_hand_counter()`, `_build_turn_chip()`은 새 노드를 만들지 않고 씬 노드를 바인딩하도록 변경했다.
- 플레이어 HP fill 폭은 고정 `256px` 대신 실제 HP bar 노드 크기 기준으로 계산하도록 변경했다.

디자이너 편집 가능해진 부분:

- 츠키 HUD 패널 위치와 크기
- 초상화 프레임과 초상화 영역
- HP 바 위치와 크기
- EP 게이지 위치와 크기
- 중앙 에너지 숫자 위치와 크기
- 손패 카운터 위치와 크기
- 턴 칩 위치와 크기

아직 코드에 남은 부분:

- EP segment는 최대치에 따라 동적으로 생성된다.
- Toast, turn banner, monster info popup은 아직 런타임 생성 방식이다.
- HandRail은 커스텀 드로잉 컨트롤이라 코드 생성 상태로 남아 있다.

### Map Route Data 리소스화

Files:

- `project-a/scripts/map/map_route_data.gd`
- `project-a/scripts/data/map_route_node_data.gd`
- `project-a/scripts/data/map_route_resource.gd`
- `project-a/data/map/DefaultRoute.tres`

변경 내용:

- 기존 `MapRouteData.MAP_NODES` 하드코딩 배열을 제거했다.
- `MapRouteNodeData` 리소스를 추가해 노드별 `id`, `type`, `label`, `monster_id`, `position`, `next_ids`를 인스펙터에서 편집할 수 있게 했다.
- `MapRouteResource` 리소스를 추가해 전체 노드 목록을 보관하게 했다.
- `DefaultRoute.tres`에 현재 프로토타입 루트 데이터를 옮겼다.
- 기존 호출부는 `MapRouteData.get_nodes()`, `get_node()`, `get_next_nodes()` API를 그대로 사용할 수 있게 유지했다.

디자이너/기획자 편집 가능해진 부분:

- 노드 위치
- 노드 타입
- 노드 라벨
- 연결되는 다음 노드
- 전투 노드의 몬스터 id

## Hardcoding Audit Result

오늘 확인한 주요 하드코딩 영역은 다음과 같다.

1. `project-a/scripts/ui/battle_map_overlay.gd`
   - 기존에는 Overlay UI 대부분이 코드 생성이었다.
   - 오늘 1차로 씬 노드화 완료.

2. `project-a/scripts/ui/battle_ui.gd`
   - 전투 HUD 중 플레이어 패널, EP 게이지, 카운터류가 코드 생성이었다.
   - 오늘 주요 고정 HUD를 씬 노드화했다.

3. `project-a/scripts/map/map_route_data.gd`
   - 루트 노드 배열이 코드 상수였다.
   - 오늘 `DefaultRoute.tres` 리소스로 분리했다.

4. `project-a/scripts/ui/enemy_status_bar.gd`
   - 몬스터 HP 바와 intent badge가 여전히 코드 생성이다.
   - 다음 우선순위 작업으로 씬화 후보.

5. `project-a/scripts/map/map_screen.gd`
   - Map screen UI가 `@tool` 스크립트에서 생성된다.
   - BattleMap Overlay와 데이터 구조가 안정화된 뒤 분리하는 것이 좋다.

6. `project-a/scripts/core/ingame.gd`
   - 카드 드로우 수, 손패 크기, 전투 연출 시간, 배경/몬스터 데이터 매핑 등 게임 설정값이 코드 상수로 남아 있다.
   - 향후 `BattleSettings`, `EncounterTable`, `RouteTransitionSettings` 같은 리소스로 분리 가능하다.

## Current Verification

실행한 검증:

- `git diff --check`

결과:

- 공백/패치 레벨 오류 없음.

제약:

- 현재 작업 환경에서 `godot` / `godot4` 실행 파일이 PATH에 없어 Godot 에디터 파서 검증은 실행하지 못했다.

## Current Working Tree Notes

현재 변경 파일 중 아래 두 파일은 오늘 작업 중 직접 수정하지 않은 기존 변경으로 남겨두었다.

- `project-a/assets/stage/stage_1.png.import`
- `project-a/assets/ui/bg_title.png.import`

오늘 새로 작업한 주요 파일:

- `project-a/scenes/ui/battle_map_overlay.tscn`
- `project-a/scripts/ui/battle_map_overlay.gd`
- `project-a/scenes/ui/battle_ui.tscn`
- `project-a/scripts/ui/battle_ui.gd`
- `project-a/scripts/map/map_route_data.gd`
- `project-a/scripts/data/map_route_node_data.gd`
- `project-a/scripts/data/map_route_resource.gd`
- `project-a/data/map/DefaultRoute.tres`

## Next Recommended Tasks

1. Godot 에디터에서 `BattleUI.tscn`, `BattleMapOverlay.tscn`, `DefaultRoute.tres`를 열어 파서와 인스펙터 편집 상태를 확인한다.
2. `EnemyStatusBar`를 씬으로 분리한다.
3. Toast, turn banner, monster info popup 중 자주 조정될 UI부터 씬화한다.
4. `ingame.gd`의 전투 수치와 전환 연출 수치를 리소스로 분리한다.
5. `map_screen.gd`의 `@tool` 코드 생성 UI를 씬 기반 구조로 점진 전환한다.
