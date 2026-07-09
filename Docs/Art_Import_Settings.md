# 아트 Import 적용 기준

Godot 런타임에서 사용하는 이미지의 1차 import 기준입니다. 원본 PNG는 작업 품질을 유지하되, Godot import 산출물과 빌드 크기는 역할별로 줄이는 방향입니다.

## 적용값

| 분류 | 대상 | compress/mode | lossy_quality | mipmaps |
| --- | --- | ---: | ---: | --- |
| 카드 풀오버레이 | `project-a/assets/card/cardart_full/*.png` | 1 | 0.95 | on |
| 몬스터 스프라이트시트 | `project-a/assets/monster/spriteSheet/*.png` | 1 | 0.95 | off |
| 캐릭터 스프라이트시트 | `project-a/assets/characters/spritesheets/*.png` | 1 | 0.95 | off |
| 배경성 이미지 | `bg_title.png`, `ui_map.png`, `stage/*.png` | 1 | 0.95 | on |
| UI atlas/icon | `ui_sheet.png`, `UIStatusIcon.png` | 0 | 0.7 | off |

`compress/mode=1`은 Godot의 lossy texture import를 사용합니다. UI atlas와 아이콘은 작은 선, 프레임, 글자 주변 아티팩트가 잘 보일 수 있어 lossless로 유지합니다.

## 1차 확인 결과

Godot reimport 후 `.ctex` 샘플 크기:

| 샘플 | 이전 | 적용 후 |
| --- | ---: | ---: |
| `high_speed_slash.ctex` | 약 2.03 MB | 약 786 KB |
| `MonsterCrownAcolyte.ctex` | 약 1.32 MB | 약 589 KB |
| `ui_sheet.ctex` | 약 569 KB | 약 569 KB |

전체 `.ctex` 합계는 약 60.56 MB에서 약 45.15 MB로 감소했습니다.

## 운영 기준

- 새 카드 아트는 먼저 `cardart_full`에 넣고 같은 import 기준을 적용합니다.
- 새 몬스터/캐릭터 시트는 기본적으로 q95로 시작하고, 실제 전투 화면에서 차이가 없을 때만 q90 후보를 비교합니다.
- UI atlas는 파일 크기보다 선명도와 테두리 품질을 우선합니다.
- 확대 화면에서 흐림이 보이면 먼저 UI 렌더 크기와 texture filter를 확인하고, 그 다음 import 품질을 조정합니다.
