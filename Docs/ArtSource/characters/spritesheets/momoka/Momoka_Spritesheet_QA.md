# 모모카 스프라이트시트 QA

## 기준 원본

- 외형 및 생성 기준: `momoka_spritesheet_chromakey_source.png`
- 기존 투명 시트: `momoka_spritesheet_transparent_4x8_181x181.png`
- Attack 연결 프레임 원본: `momoka_attack_bridges_chromakey_source.png`
- Attack 연결 프레임 투명본: `momoka_attack_bridges_transparent.png`
- Run 동작 원본: `momoka_run_alternating_chromakey_source.png`
- Run 동작 투명본: `momoka_run_alternating_transparent.png`
- Run 자세 참고: `tsuki_run_pose_reference.png`
- 최종 투명 시트: `momoka_spritesheet_extended_attack_4x9_181x181.png`
- 런타임 시트: `project-a/assets/characters/spritesheets/momoka_spritesheet.png`
- 캐릭터 씬: `project-a/scenes/characters/momoka.tscn`
- 재생성 도구: `build_momoka_extended_attack.py`

## 작업 원칙

- 기존 모모카의 얼굴, 포니테일, 체형, 교복, 색상과 선화를 기준으로 유지했다.
- 기존 Idle, Hit, Dead 프레임은 원본 투명 시트의 픽셀을 그대로 사용했다.
- 기존 Attack 핵심 자세 4장도 수정하거나 다시 그리지 않고 그대로 사용했다.
- 크로마키 원본의 외형을 기준으로 Attack 연결 자세 4장만 추가했다.
- 발차기 궤적, 무기형 이펙트와 추가 VFX는 사용하지 않았다.

## 런타임 규격

- 배열: 4열 x 9행
- 전체 프레임: 36
- 셀 크기: 181x181
- 시트 크기: 724x1629
- 배경: 투명 RGBA

## 애니메이션 배치

- `Idle`: 0-3, 5 FPS, 반복
- `Attack`: 4-11, 13.333 FPS, 반복 안 함
- `Run`: 12-19, 13 FPS, 반복
- `Hit`: 20-27, 5 FPS, 반복 안 함
- `Dead`: 28-35, 7 FPS, 반복 안 함

## Attack 구성

1. 프레임 4: 준비 및 무릎 접기 - 추가 연결 프레임
2. 프레임 5: 기존 하이킥 - 원본 유지
3. 프레임 6: 하이킥 이후 회전 - 추가 연결 프레임
4. 프레임 7: 기존 회전 및 다리 접기 - 원본 유지
5. 프레임 8: 기존 사이드킥 - 원본 유지
6. 프레임 9: 사이드킥 회수 - 추가 연결 프레임
7. 프레임 10: 기본 자세 복귀 - 추가 연결 프레임
8. 프레임 11: 기존 가드 - 원본 유지

## QA 결과

- Attack 프레임 높이: 173-174px
- Attack 최소 좌우 여백: 16px
- Attack 최소 상하 여백: 3px
- Attack 잘림 위험: 없음
- 기존 Dead 프레임 일부는 원본과 동일하게 좌우 여백이 2px지만 실제 픽셀 잘림은 없다.
- 세부 수치: `qa/momoka_frame_bbox_report.txt`
- 재생 확인: `qa/attack.gif`

## Run 재작업

- 프레임 12-15: 왼발 접지, 하강, 밀기, 오른발 전진 단계
- 프레임 16-19: 오른발 접지, 하강, 밀기, 왼발 전진 단계
- 얼굴, 가슴, 무릎과 발끝은 전 프레임에서 화면 오른쪽을 향한다.
- 포니테일은 진행 반대편인 화면 왼쪽으로 흐른다.
- 접지한 발이 몸 아래를 지나 뒤로 밀리도록 구성해 뒤로 달리는 인상을 줄였다.
- Run 프레임은 모두 높이 174px이며 셀 경계 잘림이 없다.
- 재생 확인: `qa/run.gif`

## 참고

- 모모카는 무기 없이 발차기를 주력으로 사용하는 캐릭터다.
- 새 시트는 기존 `181x181` 셀 규격을 유지한다.
- `momoka.tscn`에 별도로 구성된 `PowerKick` 및 Attack 설정은 유지하고 Run 프레임만 연결했다.
- 재생성 도구는 시트와 QA 파일만 갱신하며 씬의 수동 애니메이션 설정은 덮어쓰지 않는다.
