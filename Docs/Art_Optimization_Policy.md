# 아트 리소스 최적화 정책

## 목표

아트 품질은 유지하되, 카드와 몬스터 수가 늘어나도 빌드 용량과 메모리 사용량이 예측 가능하도록 관리합니다.

## 기본 원칙

- 게임에서 실제로 쓰는 이미지만 `project-a/assets` 아래에 둡니다.
- 참고 이미지, 생성 후보, 원본, 프리뷰, 비교용 파일은 Godot 프로젝트 밖에 둡니다.
- 런타임 에셋은 역할별 폴더에만 둡니다.
- 같은 목적의 이미지를 두 폴더에 중복 보관하지 않습니다.
- import 설정은 파일별 임의 설정이 아니라 폴더/용도별 preset으로 맞춥니다.

## 폴더 역할

| 폴더 | 역할 | 빌드 포함 |
| --- | --- | --- |
| `project-a/assets/card/cardart_full` | 게임에서 쓰는 카드 풀오버레이 | 포함 |
| `project-a/assets/monster/spriteSheet` | 게임에서 쓰는 몬스터 스프라이트시트 | 포함 |
| `project-a/assets/characters/spritesheets` | 게임에서 쓰는 캐릭터 스프라이트시트 | 포함 |
| `project-a/assets/ui` | 게임에서 쓰는 UI atlas와 배경 | 포함 |
| `project-a/assets/stage` | 게임에서 쓰는 배경/스테이지 | 포함 |
| `project-a/assets/reference` | 임시 참고용만 허용 | 가능하면 제외/이동 |
| `project-a/assets/card/cardart` | 레거시 카드아트 | 신규 사용 금지 |

작업 원본 권장 위치:

```text
Docs/ArtSource/
Docs/ArtReference/
```

장기적으로는 Godot 프로젝트 루트인 `project-a` 밖에 두는 편이 가장 안전합니다.

현재 작업/참고용 대용량 파일은 `Docs/ArtSource`로 이동했습니다. 신규 후보 이미지도 최종 적용 전까지는 이 위치를 기본 보관소로 사용합니다.

## 카드 풀오버레이 정책

- 사용 폴더: `project-a/assets/card/cardart_full`
- 기준 해상도: 세로형 `1024x1536` 전후
- 카드 UI 확대 품질은 이미지 업스케일이 아니라 UI 레이아웃 해상도 확대로 해결합니다.
- 카드가 수십 장으로 늘어나도 우선 이 해상도를 유지하고, 빌드 용량이 문제가 될 때 압축 품질을 조정합니다.
- 작은 `cardart` fallback은 사용하지 않습니다.

권장 import 방향:

- `mipmaps/generate=false`
- `process/size_limit=0` 또는 최대 `1536`
- 대표 카드로 압축 A/B 테스트 후 `compress/mode` 확정

## 몬스터 스프라이트시트 정책

- 사용 폴더: `project-a/assets/monster/spriteSheet`
- 실제 전투 화면 표시 크기를 기준으로 최대 해상도를 정합니다.
- 현재 960px급 시트는 유지 가능하지만, 신규 몬스터는 표시 크기 대비 과도한 여백과 프레임 낭비를 피합니다.
- 프레임 수가 늘어나는 애니메이션은 카드 풀아트보다 용량 증가가 빠르므로 먼저 최적화 대상이 됩니다.

권장 import 방향:

- 2D 픽셀아트가 아니면 linear filtering 유지
- `mipmaps/generate=false`
- 몬스터가 카메라 줌/확대 연출을 받지 않으면 `process/size_limit=1024` 후보
- 보스처럼 크게 보이는 몬스터만 예외적으로 더 큰 상한 허용

## UI atlas 정책

- 사용 폴더: `project-a/assets/ui`
- 텍스트가 포함된 UI 이미지는 압축 손상이 눈에 잘 띕니다.
- 아이콘/프레임/atlas는 선명도가 우선입니다.
- 미사용 atlas는 프로젝트 밖으로 이동하거나 삭제합니다.

권장 import 방향:

- atlas는 손실 압축보다 무손실 또는 고품질 압축 우선
- 실제 표시 크기보다 과도하게 큰 atlas는 source 단계에서 정리

## Reference 정책

`assets/reference`는 빌드 리소스와 섞이기 쉽기 때문에 최소한만 둡니다.

허용:

- 현재 작업 중인 비교용 소수 파일
- 가까운 시일 내 직접 적용할 후보

비권장:

- 최종 적용이 끝난 후보 이미지
- AI 생성 원본 묶음
- 큰 preview/full 이미지
- 예전 버전 백업

최종 적용이 끝난 이미지는 `cardart_full`, `monster/spriteSheet`, `ui` 등 런타임 폴더에만 남깁니다.

## 작업 순서

1. 런타임 참조 여부를 먼저 확인합니다.
2. 미사용 대용량 이미지는 삭제하지 말고 작업 보관 위치로 이동합니다.
3. 대표 샘플로 압축 설정을 비교합니다.
4. 품질 기준을 정한 뒤 폴더별로 import 설정을 일괄 적용합니다.
5. 변경 후 Godot 콘솔 실행 파일로 재임포트합니다.

```powershell
D:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --import --path D:\Project_Sceret\project-a
```

## 당장 적용할 기준

- 카드 풀오버레이는 `cardart_full` 단일 경로를 유지합니다.
- 레거시 `cardart` 폴더는 신규 참조를 만들지 않습니다.
- 새 후보 이미지를 적용한 뒤에는 `reference`에 중복 원본을 남기지 않습니다.
- 몬스터/캐릭터 신규 시트는 1024px급을 기본 상한으로 보고, 보스/대형 연출만 예외 처리합니다.

## A/B 테스트 1차 기준

테스트 위치:

```text
Docs/ArtOptimizationAB/
```

대표 샘플:

- 카드: `assets/card/cardart_full/high_speed_slash.png`
- 몬스터: `assets/monster/spriteSheet/MonsterCrownAcolyte.png`
- UI: `assets/ui/UISheet.png`

1차 결과:

| 분류 | 1차 권장 후보 | 이유 |
| --- | --- | --- |
| 카드 풀오버레이 | WebP q95 | 원본 대비 약 18.5% 크기, 육안 품질 양호 |
| 몬스터 시트 | WebP q95 또는 q90 | q95는 안정적, q90도 품질 대비 절감 폭이 좋음 |
| UI atlas | WebP q95 또는 lossless | 작은 라인/프레임 손상 방지를 위해 보수적으로 적용 |

운영 기준:

- 카드/몬스터 신규 에셋은 먼저 WebP q95 후보를 만들고 원본과 비교합니다.
- q95에서 차이가 거의 없으면 q90을 추가로 비교합니다.
- UI atlas는 q90 이하를 바로 적용하지 않고, 실제 게임 화면에서 버튼/라인/텍스트 주변을 확인합니다.
- 원본 PNG는 작업 원본 보관 위치에 두고, Godot 런타임 폴더에는 최종 사용본만 둡니다.
