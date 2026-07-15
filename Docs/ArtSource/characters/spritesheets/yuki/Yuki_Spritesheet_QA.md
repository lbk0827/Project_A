# 유키 스프라이트시트 QA 주석

이 문서는 유키(Yuki) 스프라이트시트의 파일 분류, 안정본 채택 사유, 애니메이션 연결 방식, 검수 결과를 정리한 한글 설명 주석입니다.
Godot 씬 파일은 파싱 안정성을 위해 데이터만 유지하고, 작업 의도와 주의사항은 이 문서에 기록합니다.

## 1. 최종 런타임 후보

- 런타임 시트: `project-a/assets/characters/spritesheets/yuki_spritesheet.png`
- Godot 씬: `project-a/scenes/characters/yuki.tscn`
- 최종 원본 보관본: `Docs/ArtSource/characters/spritesheets/yuki/yuki_spritesheet_stable_4x9_transparent.png`
- 검은 배경 원본: `Docs/ArtSource/characters/spritesheets/yuki/yuki_spritesheet_stable_4x9_black_source.png`
- 검수 미리보기: `Docs/ArtSource/characters/spritesheets/yuki/yuki_spritesheet_stable_4x9_preview.png`

최종 후보는 첨부 안정본을 개별 프레임 검출 방식으로 정리한 4열 x 9행, 총 36프레임 구조입니다.
런타임 셀 크기는 기존 플레이어 캐릭터와 맞추기 위해 181x181을 유지했습니다.

## 2. 안정본 채택 사유

이전 4x12 후보는 츠키 구조와 프레임 수를 맞추는 장점이 있었지만, 일부 프레임의 행 간격과 공격 이펙트가 불안정했습니다.
이번 안정본은 프레임 수는 줄어들지만 캐릭터 본체가 크고 선명하며, 각 프레임이 독립적으로 잘려 있어 런타임 안정성이 더 높습니다.

- 긴 웨이브 갈색 머리와 파란 의상 정체성이 가장 안정적으로 유지됩니다.
- 각 프레임을 원본 격자로 단순 분할하지 않고, 캐릭터 덩어리 36개를 개별 검출해 181x181 셀에 다시 중앙 배치했습니다.
- 원본의 검은 배경은 제거하되, 캐릭터 외곽선이 과하게 지워지지 않도록 밝기 기준으로 보수적으로 투명화했습니다.
- 전체 프레임에서 2px 미만으로 경계에 닿는 위험 프레임은 없습니다.

## 3. 애니메이션 매핑 주석

`project-a/scenes/characters/yuki.tscn`의 `AnimatedSprite2D`에는 아래 애니메이션을 연결했습니다.

- `Idle`: 0-3번, 첫 행 4프레임입니다.
- `Walk`: 4-10번, 2-3행 일부를 느린 이동 모션으로 사용합니다.
- `Run`: 16-23번, 5-6행 8프레임을 빠르게 재생합니다.
- `Attack`: 8-15번, 검을 뽑고 베는 8프레임입니다.
- `Special`: 24-27번, 하단 이펙트 공격 후보 4프레임입니다.
- `Hit`: 28-31번, 피격/반응용 4프레임입니다.
- `Dead`: 32-35번, 서 있는 전환 프레임 2개와 누운 프레임 2개를 사용합니다.
- `Crouch`: 30-31번, 낮은 자세 후보 2프레임입니다.

## 4. 검수 결과 주석

수치 검수 결과:

- 런타임 시트 크기: 724x1629
- 프레임 규격: 4열 x 9행, 181x181 셀
- 총 프레임 수: 36
- 전체 프레임 최소 여백: 3px
- `edge_risk_frames`: 없음

주요 애니메이션 크기:

- `Idle`: 폭 143-146px, 높이 175px입니다.
- `Walk`: 폭 137-165px, 높이 171-175px입니다.
- `Run`: 폭 105-153px, 높이 175px입니다.
- `Attack`: 폭 133-175px, 높이 159-175px입니다.
- `Hit`: 폭 128-165px, 높이 171-175px입니다.
- `Dead/Down`: 폭 125-175px, 높이 79-175px입니다.

`Dead/Down`의 누운 프레임은 자세 특성상 높이가 낮지만, 폭은 175px로 셀 안에서 충분히 크게 유지됩니다.
따라서 특정 프레임이 과하게 작아지는 문제는 없는 것으로 판단했습니다.

## 5. QA 산출물 분류

`Docs/ArtSource/characters/spritesheets/yuki/qa/` 폴더에는 검수용 자료를 저장했습니다.

- `yuki_frame_bbox_report.txt`: 프레임별 알파 바운딩 박스 수치 리포트입니다.
- `yuki_bbox_preview.png`: 각 프레임의 실제 점유 영역을 노란 박스로 표시한 미리보기입니다.
- `yuki_animation_strip_preview.png`: `Idle`, `Walk`, `Run`, `Hit`, `Down` 주요 프레임을 한 장에서 비교하는 미리보기입니다.
- `idle.gif`: 대기 모션 검수용 GIF입니다.
- `walk.gif`: 걷기 모션 검수용 GIF입니다.
- `run.gif`: 뛰기 모션 검수용 GIF입니다.
- `attack.gif`: 공격 모션 검수용 GIF입니다.
- `hit.gif`: 피격 모션 검수용 GIF입니다.
- `special.gif`: 특수 자세 검수용 GIF입니다.
- `down.gif`: 다운/사망 후보 검수용 GIF입니다.
- `crouch.gif`: 낮은 자세 후보 검수용 GIF입니다.

## 6. 다음 작업 권장사항

1. 현재 4x9 안정본을 유키 런타임 스프라이트시트로 사용합니다.
2. 전투 화면에서 `Walk`, `Run`, `Attack`, `Hit`, `Dead`를 같은 배율로 반복 재생해 최종 감각만 확인합니다.
3. 공격 이펙트가 더 필요하면 캐릭터 본체는 이 시트로 유지하고, 별도 VFX 시트를 추가하는 방식이 안전합니다.
