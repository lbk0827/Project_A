# Sonic Boom VFX 구현 계획

## 목표

캐릭터가 일반 공격 시 몬스터 앞까지 걸어가듯 이동하는 현재 연출을, 순간 돌진과 소닉 붐 충격파가 함께 보이는 연출로 교체한다.

기본 흐름은 다음과 같다.

1. 캐릭터가 제자리에서 소닉 붐을 일으키며 몬스터 앞으로 순간 이동한다.
2. 기존 공격 애니메이션과 타격 판정을 재생한다.
3. 공격 후 다시 소닉 붐을 일으키며 원래 위치로 복귀한다.

레퍼런스 영상은 `Docs/RefClip/SonicBoom.mp4`를 사용한다. 외부 캐릭터의 디자인은 가져오지 않고, 이동 타이밍과 충격파 구조만 참고한다.

## 현재 프로젝트 연결 지점

관련 런타임 파일:

- `project-a/scripts/core/ingame.gd`
  - `_move_player_to_attack_position()`
  - `_return_player_home()`
- `project-a/scripts/player/heroine_controller.gd`
  - `approach_time`, `return_time`, `play_run_animation()`, `play_card_animation()`
- `project-a/scripts/monster/monster_actor.gd`
  - 기본 몬스터 공격에는 소닉 붐을 적용하지 않는다.
  - 특별한 몬스터가 필요할 때만 별도 연출로 확장한다.
- 기존 VFX 선례
  - `project-a/scripts/vfx/moon_slash_vfx.gd`
  - `project-a/scenes/vfx/fx_tsuki_moon_slash.tscn`
  - `project-a/scripts/vfx/one_shot_vfx.gd`

현재 이동은 `global_position` 트윈으로 처리된다. 소닉 붐은 이 트윈 앞뒤에 VFX를 생성하고, 이동 시간을 짧게 조정하는 방식으로 붙이는 것이 가장 안전하다.

## 권장 구현 방식

스프라이트시트 단독보다 하이브리드 VFX를 권장한다.

- 스프라이트시트: 순간 잔상, 공기 원뿔, 압축 링, 먼지 폭발 같은 핵심 실루엣
- 코드 드로잉: 캐릭터 출발점과 도착점을 잇는 속도선, 방향별 스케일/회전, 화면 흔들림
- 전투 코드: 이동 위치, 공격 판정, 복귀 타이밍

이 방식은 Moon Slash 구현 방식과 맞고, 공격 판정과 시각 연출이 어긋날 위험이 낮다.

## VFX 타임라인

일반 공격 1회 기준 권장 타임라인:

| 시간 | 역할 | 처리 |
| ---: | --- | --- |
| 0.00s | 출발 예비 섬광 | 캐릭터 위치에 압축 링 생성 |
| 0.03s | 캐릭터 잔상 시작 | 캐릭터 색을 짧게 밝히고 속도선 생성 |
| 0.04~0.12s | 순간 돌진 | `global_position`을 빠르게 도착점까지 이동 |
| 0.08~0.16s | 도착 충격파 | 몬스터 앞에 원형/원뿔형 소닉 붐 생성 |
| 0.16s~ | 공격 애니메이션 | 기존 `Attack` 또는 카드별 모션 재생 |
| 공격 종료 후 | 복귀 예비 섬광 | 현재 위치에 압축 링 생성 |
| 0.04~0.12s | 순간 복귀 | 원래 위치까지 빠르게 이동 |
| 복귀 완료 | 착지 잔상 정리 | 원래 facing 복원, Idle 전환 |

기존 `approach_time`/`return_time` 기본값 0.35s/0.3s는 소닉 붐용으로는 길다. 일반 공격의 순간 이동감은 0.10~0.16s 정도가 적절하다.

## 스프라이트시트 제작안

스프라이트로 만들 경우 다음 구성을 권장한다.

파일:

- 원본 보관: `Docs/ArtSource/vfx/sonic_boom/fx_sonic_boom_sheet_source.png`
- 런타임: `project-a/assets/vfx/fx_sonic_boom_sheet.png`
- 장면: `project-a/scenes/vfx/fx_sonic_boom.tscn`
- 제어 코드: `project-a/scripts/vfx/sonic_boom_vfx.gd`

시트 사양:

| 항목 | 값 |
| --- | --- |
| 구성 | 4 columns x 3 rows |
| 총 프레임 | 12 |
| 셀 크기 | 256x256 이상 권장 |
| 배경 | 순수 검은색 |
| 합성 | Godot `CanvasItemMaterial` 가산 합성 |
| 방향 | 기본 오른쪽 진행, 코드에서 `scale.x` 또는 회전으로 반전 |

프레임 역할:

| 프레임 | 역할 |
| ---: | --- |
| 0 | 작은 압축 링 |
| 1 | 링 확장, 중심 백색 섬광 |
| 2 | 전방 공기 원뿔 시작 |
| 3 | 캐릭터 잔상/속도선 최대 |
| 4 | 후방 먼지와 찢긴 공기선 |
| 5 | 도착 지점 충격파 시작 |
| 6 | 충격파 최대 확장 |
| 7 | 충격파 가장자리 파편화 |
| 8 | 잔광 감소 |
| 9 | 먼지/입자 흩어짐 |
| 10 | 속도선 소멸 |
| 11 | 완전 소멸 |

프롬프트 핵심 문구:

```text
Use case: stylized-concept
Asset type: 2D game sonic boom dash VFX sprite sheet for Godot
Primary request: exactly 4 columns by 3 rows, 12 equal square cells,
row-major animation order; sharp white-cyan air compression rings, speed lines,
impact cone, dust burst, and fading luminous particles
Scene/backdrop: perfectly uniform pure black background for additive blending
Composition: effect centered in every cell, consistent scale, no frame crosses cell boundaries
Constraints: no character, no scenery, no text, no numbers, no UI, no logo,
no watermark, no grid lines, no gutters
```

## 코드 구조 제안

### 1. 공용 대시 VFX 스크립트 추가

`sonic_boom_vfx.gd`는 `Node2D` 기반으로 만든다.

필요 기능:

- `play_burst(direction: Vector2, travel_distance: float, is_arrival: bool = false)`
- 방향에 따라 `rotation` 또는 `scale.x` 설정
- 이동 거리 기준으로 속도선 길이 조정
- 재생 완료 후 `queue_free()`

### 2. `ingame.gd`에 공용 이동 함수 추가

플레이어의 공격 접근/복귀 이동을 소닉 붐 대시로 바꾸는 헬퍼를 둔다.

예상 형태:

```gdscript
func _dash_actor_with_sonic_boom(actor: Node2D, target_position: Vector2, requested_duration: float):
    var start_position := actor.global_position
    var direction := target_position - start_position
    _spawn_sonic_boom(start_position, direction, direction.length(), false)
    var tween := create_tween()
    tween.tween_property(actor, "global_position", target_position, requested_duration)
    await tween.finished
    _spawn_sonic_boom(target_position, direction, direction.length(), true)
```

그 뒤 `_move_player_to_attack_position()`과 `_return_player_home()`의 기존 트윈을 이 헬퍼로 교체한다.

### 3. 공격 판정은 기존 흐름 유지

소닉 붐은 이동 연출일 뿐이다. 아래 흐름은 유지한다.

- 이동 완료 후 `_play_heroine_attack()`
- `attack_impact_delay` 후 피해 적용
- `attack_recover_delay` 후 복귀
- 복귀 완료 후 Idle

## 단계별 작업 계획

1. `SonicBoom.mp4`를 프레임으로 추출해 출발 링, 이동 잔상, 도착 충격파의 기준 프레임을 6~8장 고른다.
2. 위 기준 프레임을 바탕으로 12프레임 VFX 시트 프롬프트를 작성한다.
3. 생성된 시트를 `4x3` 그리드로 정확히 나누어지게 후처리한다.
4. `fx_sonic_boom.tscn`과 `sonic_boom_vfx.gd`를 만든다.
5. `ingame.gd`에 공용 소닉 붐 대시 헬퍼를 추가한다.
6. 플레이어 일반 공격의 접근/복귀에 먼저 적용한다.
7. 타격 타이밍이 밀리지 않는지 확인한다.
8. 화면 흔들림, 잔상 투명도, 이동 시간을 실제 전투 화면에서 튜닝한다.
9. 최종 프롬프트, 프레임 매핑, 후처리 수치를 문서에 남긴다.

## 검증 체크리스트

- 캐릭터가 이동 중 걸어가는 느낌 없이 순간 돌진처럼 보이는가?
- 출발점과 도착점 양쪽에 소닉 붐이 보이는가?
- 도착 VFX가 몬스터 본체와 HP/의도 UI를 과하게 가리지 않는가?
- 피해 숫자와 공격 타격 프레임이 기존보다 늦거나 빠르게 어긋나지 않는가?
- 여러 몬스터 배치에서 도착 위치가 어색하지 않은가?
- 복귀 후 캐릭터 facing이 정상적으로 몬스터를 바라보는가?
- 특수 몬스터에 별도 적용할 경우 방향 반전이 자연스러운가?
- Godot import 후 `.import` 파일이 생성되고 장면 로드가 깨지지 않는가?

## 리스크와 대응

| 리스크 | 대응 |
| --- | --- |
| 스프라이트시트 프레임마다 중심이 흔들림 | 생성 프롬프트에 `same centered effect`, `consistent scale`을 반복하고 후처리에서 셀 중심 검수 |
| 검은 사각형 배경이 보임 | 순수 검은 배경 + `CanvasItemMaterial` 가산 합성 사용 |
| 이동이 너무 빨라 캐릭터 위치를 놓침 | 0.10~0.16s 범위에서 조정하고, 출발/도착 충격파를 더 크게 보여줌 |
| VFX가 공격 이펙트와 겹쳐 지저분함 | 소닉 붐은 이동 직후 0.12s 안에 사라지게 하고 공격 VFX는 기존 타격 타이밍에 유지 |
| 특수 몬스터 공격에 별도 적용 시 크기 불일치 | `travel_distance`와 actor 종류에 따라 scale multiplier를 분리 |

## 1차 구현 범위

1차는 플레이어 일반 공격에만 적용한다. 우선 별도 PNG 스프라이트시트 없이
절차형 드로잉 VFX로 구현하고, 이후 아트 리소스가 확정되면 같은
`fx_sonic_boom.tscn` 안에서 스프라이트시트 기반 표현으로 교체한다.

- `project-a/scenes/vfx/fx_sonic_boom.tscn`
- `project-a/scripts/vfx/sonic_boom_vfx.gd`
- `project-a/scripts/core/ingame.gd`

몬스터 공격에는 기본 적용하지 않는다. 단, 향후 소닉 붐을 콘셉트로 삼는 특수 몬스터가 생기면 해당 몬스터 전용 이동 연출로 별도 연결한다.
