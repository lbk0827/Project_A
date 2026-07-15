# Yuki V7 Tsuki Run 작업 노트

## 작업 목적

Yuki의 `Run` 프레임에서 오른발/왼발 교차가 명확하지 않아, Tsuki의 `Run` 프레임 포즈를 기준으로 Yuki 외형을 적용했습니다.

## 적용 방식

- Tsuki `Run` 프레임 16-21을 포즈 기준으로 사용했습니다.
- Yuki의 헤어, 의상, 색상, 무기 방향성은 유지했습니다.
- 생성된 6프레임 Run 스트립을 `181x181` 셀에 맞춘 뒤, Yuki 시트의 16-21번 프레임에만 합성했습니다.
- `Idle`, `Walk`, `Attack`, `Hit`, `Dead` 프레임은 건드리지 않았습니다.

## 교체된 프레임

- `Run`: 16, 17, 18, 19, 20, 21

## 산출물

- `tsuki_run_yuki_identity_reference.png`
  - 위쪽은 Tsuki Run 포즈 기준, 아래쪽은 Yuki 외형 기준으로 만든 생성 레퍼런스입니다.
- `yuki_run_v7_tsuki_pose_chromakey_source.png`
  - Tsuki Run 포즈에 Yuki 외형을 적용한 크로마키 원본입니다.
- `yuki_spritesheet_v7_tsuki_run_724x2172.png`
  - Run 프레임을 합성한 최종 시트입니다.
- `yuki_v7_tsuki_run_check.png`
  - Tsuki Run과 적용된 Yuki Run을 나란히 비교한 검수 이미지입니다.

## 검수 메모

- 이전 Yuki Run보다 발 교차가 훨씬 명확합니다.
- Tsuki의 6프레임 Run 리듬을 따르므로, 씬의 `Run` 매핑 16-21과 직접 호환됩니다.
- 이미지 생성 기반이라 세부 픽셀은 완전한 수작업 품질은 아니지만, 문제였던 "같은 발만 내딛는 느낌"은 줄었습니다.
