# 유키 스프라이트시트 QA 주석

이 문서는 유키(Yuki) 스프라이트시트의 파일 분류, 츠키 기반 재작업 의도, 애니메이션 연결 방식, 검수 결과를 정리한 한글 설명 주석입니다.
Godot 씬 파일은 파싱 안정성을 위해 데이터만 유지하고, 작업 의도와 주의사항은 이 문서에 기록합니다.

## 1. 최종 런타임 후보

- 런타임 시트: `project-a/assets/characters/spritesheets/yuki_spritesheet.png`
- Godot 씬: `project-a/scenes/characters/yuki.tscn`
- 최종 원본 보관본: `Docs/ArtSource/characters/spritesheets/yuki/yuki_spritesheet_tsuki_pose_4x12_transparent.png`
- 크로마키 원본: `Docs/ArtSource/characters/spritesheets/yuki/yuki_spritesheet_tsuki_pose_4x12_chromakey_source.png`
- 알파 제거 중간본: `Docs/ArtSource/characters/spritesheets/yuki/yuki_spritesheet_tsuki_pose_4x12_alpha_source.png`
- 검수 미리보기: `Docs/ArtSource/characters/spritesheets/yuki/yuki_spritesheet_tsuki_pose_4x12_preview.png`

최종 후보는 츠키 스프라이트시트와 같은 4열 x 12행, 총 48프레임 구조입니다.
런타임 셀 크기는 츠키와 동일한 181x181이며, Godot `AtlasTexture`도 이 규격에 맞춰 다시 연결했습니다.

## 2. 재작업 방향

이번 버전은 이전 4x8 후보의 유키 정체성을 유지하면서, 츠키 스프라이트시트의 프레임 수와 씬 연결 규격에 맞추는 것을 목표로 했습니다.

- 긴 웨이브 갈색 머리를 유지하고, 포니테일처럼 보이는 실루엣은 피했습니다.
- 파란 소매/재킷, 흰색 한쪽 레그웨어, 카타나, 파란 의상 포인트를 유지했습니다.
- 초록 크로마키 배경을 제거한 뒤 각 셀 안쪽에 5px 안전 여백을 두어 프레임 경계 잘림을 줄였습니다.
- 생성 원본의 행 간격이 완전히 균일하지 않아, 셀 안에 섞인 작은 발끝/머리 조각은 컴포넌트 정리로 제거했습니다.

## 3. 이전 후보 분류

아래 파일들은 최종 후보가 아니라 생성 실험 또는 비교용 보관본입니다.

- `yuki_spritesheet_4x8_chromakey_source.png`: 첫 유키 후보의 4x8 크로마키 원본입니다.
- `yuki_spritesheet_4x8_transparent.png`: 첫 유키 후보를 투명화한 4x8 보관본입니다.
- `yuki_spritesheet_4x8_preview.png`: 첫 유키 후보 미리보기입니다.
- `yuki_spritesheet_chromakey_source.png`: 초기 4x12 생성 실험본입니다.
- `yuki_spritesheet_transparent.png`: 초기 4x12 실험본을 투명화한 파일입니다.
- `yuki_spritesheet_transparent_4x12_198x165.png`: 다른 셀 크기로 정리했던 4x12 실험본입니다.
- `yuki_spritesheet_tsuki_pose_4x12_black_source.png`: 츠키 포즈 기반으로 먼저 만들었던 중간 후보입니다.

## 4. 애니메이션 매핑 주석

`project-a/scenes/characters/yuki.tscn`의 `AnimatedSprite2D`에는 아래 애니메이션을 연결했습니다.

- `Idle`: 0-3번, 첫 행 4프레임만 사용합니다. 이전처럼 이동 준비 프레임을 섞지 않아 제자리 대기감이 납니다.
- `Walk`: 4-11번, 2-3행 8프레임을 느린 속도로 재생합니다.
- `Run`: 8-11번, 3행 4프레임을 빠르게 재생합니다.
- `Attack`: 12-27번, 4-7행 16프레임을 공격 콤보로 연결합니다.
- `Special`: 24-31번, 7-8행의 이펙트/특수 자세 후보를 사용합니다.
- `Hit`: 31-33번, 피격 반응에서 다운 전환으로 이어지는 3프레임입니다.
- `Dead`: 32-43번, 다운/사망 연출용 12프레임입니다.
- `Crouch`: 44-47번, 마지막 행의 낮은 자세/복귀 후보 4프레임입니다.

## 5. 검수 결과 주석

### 개선된 구간

`Idle`은 첫 행의 정지 프레임만 사용하도록 변경했습니다.
이전 연결은 보행 준비 프레임이 포함되어 제자리 대기처럼 보이지 않았지만, 새 연결은 발 위치 변화가 작아 대기 모션으로 사용하기 쉽습니다.

`Walk`와 `Run`은 같은 프레임을 속도만 다르게 쓰던 이전 연결에서 분리했습니다.
`Walk`는 8프레임으로 천천히 이어지고, `Run`은 동세가 큰 4프레임만 빠르게 사용합니다.

`Hit`은 바로 누운 프레임으로 튀지 않도록, 서 있는 반응 프레임에서 다운 전환 프레임으로 이어지게 조정했습니다.

### 주의가 필요한 구간

`Attack`과 `Special`은 검기 이펙트가 넓어서 셀 안의 사용 면적이 큽니다.
현재 시트에서는 5px 안전 여백 안에 들어오도록 정리했지만, 최종 전투 연출에서는 츠키 `FiveSlash`처럼 캐릭터 본체와 VFX를 분리하는 편이 더 안정적입니다.

수치 검수 결과:

- `Idle`: 폭 86-96px, 높이 147px, 최소 여백 5px입니다.
- `Walk`: 폭 91-127px, 높이 166-171px, 최소 여백 5px입니다.
- `Run`: 폭 106-127px, 높이 166-171px, 최소 여백 5px입니다.
- `Hit`: 폭 79-124px, 높이 147-169px, 최소 여백 5px입니다.
- 전체 프레임에서 2px 미만으로 경계에 닿는 위험 프레임은 없습니다.

## 6. QA 산출물 분류

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

## 7. 다음 작업 권장사항

1. 현재 4x12 시트를 유키 2차 런타임 후보로 사용합니다.
2. 실제 전투 화면에서 `Walk`, `Run`, `Hit`을 재생 확인한 뒤, 발 접지감이 부족한 프레임만 수작업 보정합니다.
3. 공격 이펙트가 카메라/충돌 판정과 겹치면 캐릭터 본체와 VFX 시트를 분리합니다.
4. 최종 확정 전에는 Godot에서 `Idle`, `Walk`, `Run`, `Hit`, `Dead`를 같은 배율로 반복 재생해 크기 튐을 다시 확인합니다.
