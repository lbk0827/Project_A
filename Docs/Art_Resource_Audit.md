# 아트 리소스 감사

2026-07-07 기준으로 Godot 프로젝트 안에 남아 있는 이미지 리소스와 작업 원본 보관 위치를 정리했습니다.

## 현재 요약

`project-a/assets` 안의 이미지 파일:

| 항목 | 수치 |
| --- | ---: |
| 이미지 수 | 25 |
| 원본 파일 합계 | 약 34.11 MiB |
| Godot `.ctex` 합계 | 약 45.15 MiB |

초기 조사 시점의 `project-a/assets` 이미지는 약 58.2 MiB였고, 작업 원본/후보 이미지를 프로젝트 밖으로 이동한 뒤 약 34.11 MiB까지 줄었습니다.

## 폴더별 현황

| 폴더 | 이미지 수 | 원본 합계 | 상태 |
| --- | ---: | ---: | --- |
| `card/cardart_full` | 8 | 약 19.86 MiB | 런타임 카드 풀오버레이 |
| `monster` | 8 | 약 8.05 MiB | 런타임 몬스터 스프라이트시트 |
| `ui` | 4 | 약 4.44 MiB | 배경, UI atlas, 아이콘 |
| `characters` | 1 | 약 1.33 MiB | 런타임 캐릭터 스프라이트시트 |
| `stage` | 1 | 약 0.40 MiB | 런타임 스테이지 배경 |
| `card/cardframe` | 1 | 약 0.14 MiB | `CardFrame_*.tres` 참조 남음 |
| `vfx` | 2 | 약 0.04 MiB | 런타임 VFX |

## 프로젝트 밖으로 이동한 항목

다음 항목은 런타임 참조가 없어 `Docs/ArtSource` 아래로 이동했습니다.

| 기존 위치 | 새 위치 | 이유 |
| --- | --- | --- |
| `project-a/assets/characters/spritesheets/original-*` | `Docs/ArtSource/characters/spritesheets` | 작업 원본/후보 |
| `project-a/assets/characters/spritesheets/HeroineSheet_retouched*` | `Docs/ArtSource/characters/spritesheets` | 작업 원본/미사용 후보 |
| `project-a/assets/reference/*_tsuki.png` | `Docs/ArtSource/reference` | 참고용 원본 |
| `project-a/assets/ui/UISkilllIcon.png` | `Docs/ArtSource/ui` | 미사용 후보 |
| `project-a/assets/card/cardart/*` | `Docs/ArtSource/card/cardart_legacy` | 레거시 카드 아트 |
| `project-a/assets/reference/*.webp` | `Docs/ArtSource/reference/webp_candidates` | 참고용 후보 |

## Import 적용 상태

자세한 적용값은 [Art_Import_Settings.md](./Art_Import_Settings.md)에 정리했습니다.

핵심 기준:

- 카드 풀오버레이: lossy q95, mipmap on
- 몬스터/캐릭터 스프라이트시트: lossy q95, mipmap off
- 배경성 이미지: lossy q95, mipmap on
- UI atlas/icon: lossless 유지

## 다음 후보

- `CardFrame_*.tres`가 더 이상 실제로 쓰이지 않는지 추적한 뒤 `card/cardframe/CardDummy.png` 제거 여부 결정
- 카드 확대 화면에서 q95와 q90을 추가 비교
- 새 몬스터 추가 시 q95를 기본값으로 쓰고, 전투 화면에서 차이가 없을 때 q90 후보 비교
