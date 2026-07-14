# Monster AI Data Table Design

이 문서는 몬스터별 행동 AI를 코드가 아니라 데이터테이블로 관리하기 위한 기준안입니다.

## 설계 방향

몬스터 AI는 Behavior Tree로 시작하지 않고, 공개 행동 예고형 전투에 맞춘 데이터 드리븐 구조로 관리합니다.

- `MonsterTable`은 몬스터의 공통 템플릿을 정의합니다.
- `MonsterStatsTable`은 HP, 공격, 방어 수치를 정의합니다.
- `MonsterActionTable`은 실제 행동 효과를 정의합니다.
- `MonsterPatternTable`은 행동 순서와 행동 카운트를 정의합니다.
- `EncounterTable`은 전투에 등장한 개별 몬스터의 시작 상태를 정의합니다.
- `MonsterRuleTable`은 HP 조건 등 특수 전환 규칙을 정의합니다.

중요한 원칙은 몬스터 종류 데이터와 전투 중 개체 상태를 분리하는 것입니다. 같은 `mire_imp`라도 인카운터에 따라 어떤 개체는 공격 예정, 어떤 개체는 방어 예정으로 시작할 수 있어야 합니다.

## 컬럼명 규칙

현재 프로젝트의 테이블, JSON, GDScript는 대부분 `snake_case`를 사용합니다. 예: `monster_id`, `pattern_id`, `start_step_id`.

엑셀에서 `PatternID`, `StepID`처럼 PascalCase 계열 컬럼명을 쓰는 것은 사람이 보기에는 좋지만, 현재 자동 내보내기 도구와 런타임 코드의 키 이름을 전면 수정해야 합니다. 따라서 지금 단계에서는 다음 기준을 권장합니다.

- 런타임/export 컬럼명은 `snake_case` 유지
- 기획 문서나 엑셀 설명 컬럼에서만 `PatternID`, `StepID` 같은 표시명을 병기
- 전면 리팩토링은 몬스터 AI 시스템이 실제로 안정화된 뒤, 별도 마이그레이션 작업으로 진행

전면 리팩토링을 지금 하지 않는 이유는 다음과 같습니다.

- 기존 JSON 키와 GDScript 접근 코드가 모두 영향을 받습니다.
- 테이블 exporter, 생성 스크립트, 리소스 변환 코드까지 함께 바뀝니다.
- 시각적 선호 대비 기능적 이득은 작고, 회귀 위험은 큽니다.

## 1. MonsterTable

몬스터의 기본 정보를 정의합니다.

| 컬럼명 | 역할 |
|---|---|
| `monster_id` | 몬스터 고유 ID입니다. 예: `mire_imp` |
| `display_name` | 화면에 표시할 이름입니다. |
| `stats_id` | `MonsterStatsTable`의 `stats_id`와 연결됩니다. |
| `default_pattern_id` | 별도 지정이 없을 때 사용할 기본 행동 패턴입니다. |
| `scene_path` | Godot 몬스터 씬 경로입니다. |
| `hp_bar_offset_x` | HP바 표시 위치 X 보정값입니다. |
| `hp_bar_offset_y` | HP바 표시 위치 Y 보정값입니다. |
| `intent_offset_x` | 행동 예고 아이콘 위치 X 보정값입니다. |
| `intent_offset_y` | 행동 예고 아이콘 위치 Y 보정값입니다. |

## 2. MonsterStatsTable

몬스터의 전투 수치를 정의합니다.

| 컬럼명 | 역할 |
|---|---|
| `stats_id` | 스탯 고유 ID입니다. |
| `max_hp` | 최대 HP입니다. |
| `attack` | 공격 행동의 기준 수치입니다. |
| `defense` | 방어 행동의 기준 수치입니다. |

`attack_power`, `defense_power` 대신 `attack`, `defense`를 사용합니다. `speed`, `reward_gold`, `reward_exp`는 현재 몬스터 행동 시스템 범위에서는 제외합니다.

## 3. MonsterActionTable

몬스터가 실행할 수 있는 행동을 정의합니다. 행동은 `휘두르기`, `방어`, `사기`, `얼음 칼날`, `얼음 갑옷` 같은 단위입니다.

| 컬럼명 | 역할 |
|---|---|
| `action_id` | 행동 고유 ID입니다. |
| `display_name` | 화면에 표시할 행동 이름입니다. |
| `action_type` | 행동 분류입니다. 예: `attack`, `defense`, `buff`, `debuff`, `special` |
| `target_type` | 행동 대상입니다. 예: `player`, `self`, `all_enemies` |
| `power_type` | 수치 해석 방식입니다. 예: `attack_percent`, `defense_percent`, `flat`, `max_hp_percent` |
| `power_value` | 실제 수치입니다. |
| `icon_label` | UI 아이콘 라벨입니다. 예: `ATK`, `DEF`, `BUF` |
| `description` | 기획자용 설명 및 UI 툴팁 후보 문구입니다. |
| `vfx_id` | 행동 실행 연출 ID입니다. 없으면 비워둡니다. |
| `sfx_id` | 행동 사운드 ID입니다. 없으면 비워둡니다. |

## 4. MonsterPatternTable

몬스터 행동 순서와 행동 카운트를 정의합니다.

| 컬럼명 | 역할 |
|---|---|
| `pattern_step_id` | 패턴 단계 행의 고유 ID입니다. JSON export용 key입니다. 예: `mire_imp_basic_start` |
| `pattern_id` | 행동 패턴 고유 ID입니다. |
| `step_id` | 패턴 안의 단계 ID입니다. |
| `step_order` | 사람이 읽기 쉬운 정렬 순서입니다. |
| `action_id` | 이 단계에서 예고하고 실행할 행동입니다. |
| `action_count` | 행동이 발동되기까지 필요한 행동 포인트입니다. |
| `next_step_id` | 행동 후 이동할 다음 단계입니다. |
| `condition_id` | 이 단계 진입 조건입니다. 없으면 비워둡니다. |
| `weight` | 랜덤 선택형 분기에서 사용할 가중치입니다. 고정 패턴이면 `0` 또는 `1`을 사용합니다. |
| `note` | 기획 메모입니다. 런타임에서 사용하지 않아도 됩니다. |

예를 들어 `mire_imp_basic`은 `start -> after_swing -> start`처럼 반복될 수 있습니다. 인카운터에서 `start_step_id`를 `start`로 주면 공격 예정, `after_swing`으로 주면 방어 예정으로 시작합니다.

## 5. EncounterTable

전투에 어떤 몬스터가 몇 마리 등장하고, 각 개체가 어떤 행동 상태로 시작하는지 정의합니다.

나중에 전투 노드는 `monster_id` 대신 `encounter_id`를 들고, 전투 시작 시 `EncounterTable`을 조회해 적 슬롯을 생성합니다.

| 컬럼명 | 역할 |
|---|---|
| `encounter_slot_id` | 인카운터 슬롯 행의 고유 ID입니다. JSON export용 key입니다. 예: `enc_mire_imp_4_enemy_1` |
| `encounter_id` | 인카운터 고유 ID입니다. |
| `slot_id` | 전투 안의 개체 슬롯 ID입니다. 예: `enemy_1` |
| `monster_id` | 등장할 몬스터 ID입니다. |
| `pattern_id` | 이 개체가 사용할 행동 패턴입니다. |
| `start_step_id` | 첫 행동 단계입니다. |
| `action_count_override` | 시작 행동 카운트를 강제로 바꿀 때 사용합니다. 기본값은 `null`입니다. |
| `hp_multiplier` | HP 배율입니다. 기본값은 `1.0`입니다. |
| `attack_multiplier` | 공격 배율입니다. 기본값은 `1.0`입니다. |
| `defense_multiplier` | 방어 배율입니다. 기본값은 `1.0`입니다. |
| `position_x` | 전투 배치 X 좌표입니다. |
| `position_y` | 전투 배치 Y 좌표입니다. |

## 6. MonsterRuleTable

HP 조건, 특정 행동 이후, 실드 파괴 같은 조건부 행동 전환 규칙을 정의합니다.

| 컬럼명 | 역할 |
|---|---|
| `rule_id` | 규칙 고유 ID입니다. |
| `monster_id` | 적용 몬스터 ID입니다. |
| `pattern_id` | 특정 패턴에만 적용할 경우 사용합니다. 전체 적용이면 비워둡니다. |
| `trigger_type` | 조건 타입입니다. 예: `hp_below`, `after_action`, `shield_broken`, `turn_start` |
| `trigger_value` | 조건값입니다. 예: HP 50%면 `50` |
| `once` | 한 번만 발동할지 여부입니다. |
| `priority` | 여러 규칙이 동시에 만족될 때 높은 우선순위를 먼저 처리합니다. |
| `set_pattern_id` | 조건 만족 시 변경할 패턴입니다. 없으면 비워둡니다. |
| `set_step_id` | 조건 만족 시 이동할 단계입니다. |
| `action_count_override` | 전환 후 행동 카운트 강제값입니다. 기본값은 `null`입니다. |
| `note` | 기획 메모입니다. |

## 전투 노드 연결 방식

기존 방식:

```text
BattleNode
  -> monster_id
```

확장 후 권장 방식:

```text
BattleNode
  -> encounter_id
  -> EncounterTable
  -> MonsterTable
  -> MonsterStatsTable
  -> MonsterPatternTable
  -> MonsterActionTable
  -> MonsterRuleTable
```

이 구조에서는 같은 몬스터가 여러 마리 등장해도 각 개체가 다른 시작 행동과 카운트를 가질 수 있습니다.

예:

| encounter_id | slot_id | monster_id | pattern_id | start_step_id |
|---|---|---|---|---|
| `enc_mire_imp_4` | `enemy_1` | `mire_imp` | `mire_imp_basic` | `start` |
| `enc_mire_imp_4` | `enemy_2` | `mire_imp` | `mire_imp_basic` | `start` |
| `enc_mire_imp_4` | `enemy_3` | `mire_imp` | `mire_imp_basic` | `after_swing` |
| `enc_mire_imp_4` | `enemy_4` | `mire_imp` | `mire_imp_basic` | `after_swing` |

결과적으로 1, 2번 마이어 임프는 공격 예정, 3, 4번 마이어 임프는 방어 예정으로 전투를 시작할 수 있습니다.
