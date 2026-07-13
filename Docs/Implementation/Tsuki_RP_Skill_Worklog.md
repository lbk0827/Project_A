# 츠키 전용 RP 스킬 구현 기록

## 개요

기존 EP 표기를 RP(Rage Point)로 전환하고, 츠키의 전용 분노 스킬
`달빛 베기(MOON SLASH)`를 데이터 테이블 기반으로 구현했다.

프로토타입에서 바로 테스트할 수 있도록 시작 RP는 3으로 설정했다.
출시 설정에서는 `character_rp_settings` 테이블의 `starting_rp`를 0으로
변경하면 된다.

## 데이터 테이블

- `CharacterRPSkills.xlsx`
  - `character_rp_settings`: 최대/시작 RP와 획득 규칙
  - `character_rp_skills`: 비용, 피해 배율, 타격 수, 대상, 애니메이션,
    VFX 및 컷인 시간
- 생성 데이터
  - `character_rp_settings.json`
  - `character_rp_skills.json`

현재 설정은 다음과 같다.

| 항목 | 값 |
| --- | ---: |
| 최대 RP | 7 |
| 프로토타입 시작 RP | 3 |
| 적 처치 | +1 |
| 행동 포인트 1 소비 | +0.25 |
| End Turn | +0.5 |
| Moon Slash 비용 | 3 |
| 1타 피해 배율 | 공격력 100% |
| 타격 수 | 5 |
| 대상 | 모든 적 |

RP 스킬은 적 행동 카운트를 감소시키지 않는다. 각 타격에는 일반 공격력
강화와 독립적인 치명타 판정이 적용된다.

## 전투 로직

- 적 처치, 카드의 실제 행동 포인트 소비, End Turn 입력에 RP 획득을 연결했다.
- RP는 최대치를 초과하지 않으며 소수 단위 획득을 지원한다.
- RP 초상화 선택 중에는 일반 카드와 End Turn 입력을 잠근다.
- 모든 생존 몬스터에 AIM 표시를 노출한다.
- 강조된 몬스터 중 하나를 클릭하면 전체 공격을 확정한다.
- RP 확정 입력은 UI 소비 여부의 영향을 덜 받도록 우선 입력 단계에서 처리한다.
- 몬스터 클릭 판정 반경을 RP 선택 중 150px로 확장했다.

## 카드 및 UI

- EP 표기를 `RP / RAGE`로 변경했다.
- RP 게이지 옆에 츠키 초상화 버튼을 추가했다.
- 선택 시 초상화 버튼을 취소 버튼으로 전환한다.
- 임시 텍스트 패널 대신 기존 `CardViewLarge` UI를 사용한다.
- RP 카드의 비용, 이름, 피해 배율과 타격 수는 RP 테이블에서 구성한다.
- 카드 타입 표시는 `분노 스킬`이며 영문 키워드는 별도로 표시하지 않는다.
- 전용 카드 아트는 `tsuki_moon_slash.png`를 사용한다.

## 컷인과 Moon Slash 연출

1. 츠키 전용 Moon Slash 일러스트가 화면 왼쪽에서 진입한다.
2. 테이블의 `cutin_hold_seconds`만큼 정지한다.
3. 컷인이 위로 퇴장한다.
4. 츠키가 몬스터 방향으로 달려 화면 중앙에 정지한다.
5. `MoonSlash` 캐릭터 애니메이션을 재생한다.
6. 모든 생존 몬스터에 달 VFX를 생성한다.
7. 다섯 참격과 피해를 순서대로 적용한다.
8. 달 조각을 분할·파괴한 뒤 츠키가 원래 위치로 복귀한다.

컷인 이미지는 원본 비율에 맞춘 축소 배율을 직접 계산해 중앙에 배치한다.
따라서 화면 비율이 달라져도 일러스트가 잘리지 않고 전체가 표시된다.

### Moon Slash 하이브리드 스프라이트시트

- `moon_slash_sheet.png`는 4×4, 총 16프레임으로 구성한다.
- 0~3프레임은 달 생성, 4~8프레임은 5연베기 누적, 9~15프레임은
  균열 확산과 달 파괴를 담당한다.
- 검은 배경은 Godot의 가산 합성으로 제거해 청백색 달과 보라색 검광의
  빛 번짐을 유지한다.
- 실제 5타 피해 판정 시점에 4~8프레임을 각각 연결한다.
- 기존 절차형 VFX는 순간 참격 섬광과 보조 파편으로 남겨 타격감을 보강한다.
- 시트는 1252×1252이며 각 프레임은 313×313이다.

## 리소스 및 코드 분류

### 데이터 및 검증

- `project-a/tables/excel/CharacterRPSkills.xlsx`
- `project-a/data/generated/character_rp_settings.json`
- `project-a/data/generated/character_rp_skills.json`
- `project-a/tools/table_exporter/validate_rp_tables.py`
- `project-a/tools/table_exporter/validate_rp_runtime_assets.py`

### 전투 및 UI

- `project-a/scripts/core/ingame.gd`
- `project-a/scripts/ui/battle_ui.gd`
- `project-a/scripts/ui/card_preview_large.gd`
- `project-a/scenes/ui/battle_ui.tscn`

### 캐릭터 및 VFX

- `project-a/scenes/player/heroine.tscn`
- `project-a/scripts/player/heroine_controller.gd`
- `project-a/scripts/vfx/moon_slash_vfx.gd`
- `project-a/scenes/vfx/fx_tsuki_moon_slash.tscn`
- `project-a/assets/vfx/moon_slash_moon.png`
- `project-a/assets/vfx/moon_slash_sheet.png`
- `project-a/assets/card/cardart_full/tsuki_moon_slash.png`

## 검증 결과

- RP 설정 1행과 RP 스킬 1행 테이블 검증 통과
- 런타임 리소스, MoonSlash 애니메이션, 카드 아트 및 VFX 텍스처 검증 통과
- `git diff --check` 통과
- Godot 디버그 실행에서 RP 카드 선택과 컷인 표시를 확인하고, 피드백에 따라
  입력 판정과 컷인 이미지 맞춤 방식을 수정했다.
