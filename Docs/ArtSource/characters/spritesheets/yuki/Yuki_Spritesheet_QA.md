# 유키 스프라이트시트 QA 주석

이 문서는 유키(Yuki) 1차 스프라이트시트 후보의 파일 분류, 애니메이션 연결 방식, 검수 결과를 정리한 한글 설명 주석입니다.
Godot 씬 파일은 파싱 안정성을 위해 데이터만 유지하고, 작업 의도와 주의사항은 이 문서에 기록합니다.

## 1. 최종 런타임 후보

- 런타임 시트: `project-a/assets/characters/spritesheets/yuki_spritesheet.png`
- Godot 씬: `project-a/scenes/characters/yuki.tscn`
- 최종 원본 보관본: `Docs/ArtSource/characters/spritesheets/yuki/yuki_spritesheet_4x8_transparent.png`
- 크로마키 원본: `Docs/ArtSource/characters/spritesheets/yuki/yuki_spritesheet_4x8_chromakey_source.png`
- 검수 미리보기: `Docs/ArtSource/characters/spritesheets/yuki/yuki_spritesheet_4x8_preview.png`

최종 후보는 4열 x 8행, 총 32프레임입니다.
셀 크기는 221x221이며, 초록 크로마키 배경을 제거한 RGBA 투명 PNG입니다.

## 2. 생성 실험본 분류

아래 파일들은 최종 후보가 아니라 생성 실험 또는 비교용 보관본입니다.

- `yuki_spritesheet_chromakey_source.png`: 4x12 생성을 처음 시도한 크로마키 원본입니다.
- `yuki_spritesheet_transparent.png`: 4x12 원본을 투명화한 실험본입니다.
- `yuki_spritesheet_preview.png`: 4x12 실험본 미리보기입니다.
- `yuki_spritesheet_transparent_4x12_198x165.png`: 4x12 시트를 198x165 셀 기준으로 정리한 실험본입니다.
- `yuki_spritesheet_preview_4x12_198x165.png`: 4x12 정리본 미리보기입니다.

4x12 실험본은 프레임 수는 많지만 일부 셀 경계와 행 간격이 불안정했습니다.
따라서 런타임 후보에서는 제외하고, 4x8 버전을 최종 1차 후보로 채택했습니다.

## 3. 애니메이션 매핑 주석

`project-a/scenes/characters/yuki.tscn`의 `AnimatedSprite2D`에는 아래 애니메이션을 연결했습니다.

- `Idle`: 1행 4프레임, 기본 대기 모션입니다.
- `Walk`: 2-3행 8프레임, 이동 모션을 느린 속도로 재생합니다.
- `Run`: 2-3행 8프레임, `Walk`와 같은 프레임을 빠른 속도로 재생합니다.
- `Attack`: 4-6행 12프레임, 카타나 공격 콤보입니다.
- `Special`: 7행 4프레임, 특수 자세와 이펙트 후보입니다.
- `Hit`: 7행 3-4번째 프레임, 피격/반응용 임시 연결입니다.
- `Crouch`: 8행 1-3번째 프레임, 낮은 자세 후보입니다.
- `Dead`: 8행 4프레임, 다운/사망 연출 후보입니다.

## 4. 검수 결과 주석

### 안정적인 구간

`Idle`, `Walk`, `Run`은 1차 런타임 후보로 바로 사용하기 좋습니다.
프레임별 캐릭터 크기 차이가 크지 않고, 머리카락과 발끝이 셀 밖으로 잘리는 문제도 두드러지지 않습니다.

수치 검수 결과:

- `Idle`: 높이 190px로 4프레임이 동일하고, 최소 여백은 13px입니다.
- `Walk/Run`: 높이 178-189px 범위이며, 최소 여백은 16px입니다.

### 주의가 필요한 구간

`Attack`, `Special`, `Dead/Down`은 프로토타입 연결은 가능하지만 최종 아트로는 추가 보정이 필요합니다.

- `Attack`: 검기 이펙트가 넓어서 일부 프레임이 221px 셀 가장자리에 닿습니다.
- `Special`: 에너지 이펙트 때문에 한 프레임이 셀 높이를 거의 전부 사용합니다.
- `Dead/Down`: 누운 자세가 가로로 넓어 일부 프레임이 좌우 셀 경계에 닿습니다.

이 문제는 게임에서 크게 보이지 않을 수 있지만, 최종 품질을 위해서는 츠키 `FiveSlash`처럼 캐릭터 본체와 VFX를 분리하는 방향이 좋습니다.

## 5. QA 산출물 분류

`Docs/ArtSource/characters/spritesheets/yuki/qa/` 폴더에는 검수용 자료를 저장했습니다.

- `yuki_frame_bbox_report.txt`: 프레임별 알파 바운딩 박스 수치 리포트입니다.
- `yuki_bbox_preview.png`: 각 프레임의 실제 점유 영역을 노란 박스로 표시한 미리보기입니다.
- `idle.gif`: 대기 모션 검수용 GIF입니다.
- `run.gif`: 이동 모션 검수용 GIF입니다.
- `attack.gif`: 공격 모션 검수용 GIF입니다.
- `special.gif`: 특수 자세 검수용 GIF입니다.
- `down.gif`: 다운/사망 후보 검수용 GIF입니다.

## 6. 다음 작업 권장사항

1. 현재 4x8 시트를 유키 1차 런타임 후보로 사용합니다.
2. 플레이어블 캐릭터로 확정되면 `Attack` 행의 검기 이펙트를 별도 VFX 시트로 분리합니다.
3. 긴 검기와 누운 자세까지 유지해야 한다면 공격/다운 전용 셀 크기를 221x221보다 크게 다시 생성합니다.
4. 이후 재생성 시에는 1-3행의 얼굴, 머리 길이, 의상, 이동 실루엣을 유키 정체성 기준으로 삼습니다.
