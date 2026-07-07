# 아트 리소스 전수조사

작성일: 2026-07-07

## 요약

현재 `project-a/assets` 안의 이미지 파일은 47개이며, 원본 파일 합계는 약 34.66MiB입니다.

대용량 작업/참고용 파일 32개는 `Docs/ArtSource` 아래로 이동했습니다. 이동 전 기준으로는 63개, 약 58.2MiB였습니다.

런타임 사용 여부는 다음 기준으로 분류했습니다.

- `scenes`, `scripts`, `data`에서 직접 `res://assets/...`로 참조되는 이미지
- `CardView`가 카드 ID로 동적 로드하는 `assets/card/cardart_full/*.png`

## 폴더별 현황

| 분류 | 파일 수 | 런타임 후보 | 원본 합계 |
| --- | ---: | ---: | ---: |
| `card/cardart_full` | 8 | 8 | 19.72MiB |
| `monster` | 8 | 8 | 8.05MiB |
| `ui` | 4 | 3 | 4.44MiB |
| `characters` | 1 | 1 | 1.33MiB |
| `stage` | 1 | 1 | 0.40MiB |
| `card/cardart` | 14 | 0 | 0.32MiB |
| `reference` | 8 | 0 | 0.23MiB |
| `card/cardframe` | 1 | 1 | 0.14MiB |
| `vfx` | 2 | 1 | 0.04MiB |

## 큰 런타임 후보

| 파일 | 해상도 | 원본 크기 | 비고 |
| --- | ---: | ---: | --- |
| `assets/card/cardart_full/suppress_ready.png` | 1024x1535 | 2.65MiB | 카드 풀오버레이 |
| `assets/card/cardart_full/steal_slash.png` | 1024x1536 | 2.61MiB | 카드 풀오버레이 |
| `assets/card/cardart_full/high_speed_slash.png` | 1023x1537 | 2.58MiB | 카드 풀오버레이 |
| `assets/card/cardart_full/iceberg_cleave.png` | 1023x1537 | 2.55MiB | 카드 풀오버레이 |
| `assets/card/cardart_full/freezing_blade.png` | 1023x1537 | 2.45MiB | 카드 풀오버레이 |
| `assets/card/cardart_full/long_sword_slash.png` | 1024x1536 | 2.35MiB | 카드 풀오버레이 |
| `assets/card/cardart_full/let_flow.png` | 1023x1537 | 2.34MiB | 카드 풀오버레이 |
| `assets/card/cardart_full/feint_strike.png` | 1023x1537 | 2.18MiB | 카드 풀오버레이 |
| `assets/ui/BG_Title.png` | 1774x887 | 2.18MiB | 타이틀 배경 |
| `assets/monster/spriteSheet/MonsterCrownAcolyte.png` | 960x1280 | 1.56MiB | 몬스터 시트 |
| `assets/characters/spritesheets/HeroineSheet.png` | 724x2172 | 1.33MiB | 플레이어 시트 |
| `assets/monster/spriteSheet/MonsterAbyssalCrownGuardian.png` | 960x1280 | 1.26MiB | 몬스터 시트 |
| `assets/monster/spriteSheet/MonsterGraveboundCrawler.png` | 960x960 | 1.21MiB | 몬스터 시트 |
| `assets/ui/UISheet.png` | 1944x1564 | 1.13MiB | UI atlas |
| `assets/ui/UIMap.png` | 1420x1065 | 1.04MiB | 맵 UI atlas |

## 이동한 큰 비런타임 후보

현재 코드와 씬에서 직접 참조되지 않던 큰 이미지입니다. 작업용/참고용으로 보고 `Docs/ArtSource`로 이동했습니다.

| 파일 | 해상도 | 원본 크기 | 권장 조치 |
| --- | ---: | ---: | --- |
| `Docs/ArtSource/characters/spritesheets/HeroineSheet_retouched_preview.png` | 1448x2172 | 2.44MiB | 이동 완료 |
| `Docs/ArtSource/reference/제압 준비_tsuki.png` | 1024x1535 | 2.37MiB | 이동 완료 |
| `Docs/ArtSource/reference/빙산 가르기_tsuki.png` | 1023x1537 | 2.28MiB | 이동 완료 |
| `Docs/ArtSource/reference/빙점 칼날_tsuki.png` | 1023x1537 | 2.18MiB | 이동 완료 |
| `Docs/ArtSource/characters/spritesheets/original-11_title_heroine_full.png` | 724x2172 | 1.74MiB | 이동 완료 |
| `Docs/ArtSource/characters/spritesheets/original-11_reference_costume_full.png` | 724x2172 | 1.73MiB | 이동 완료 |
| `Docs/ArtSource/characters/spritesheets/original-11_reference_costume_preview.png` | 1536x1536 | 1.71MiB | 이동 완료 |
| `Docs/ArtSource/ui/UISkilllIcon.png` | 910x1288 | 1.61MiB | 이동 완료 |
| `Docs/ArtSource/characters/spritesheets/original-11_blue_jacket_swordswoman_full.png` | 724x2172 | 1.38MiB | 이동 완료 |
| `Docs/ArtSource/characters/spritesheets/HeroineSheet_retouched.png` | 724x2172 | 1.33MiB | 이동 완료 |

## 현재 import 설정 경향

대부분의 이미지 import 파일이 다음처럼 품질 우선/무제한 설정입니다.

- `compress/mode=0`
- `compress/lossy_quality=0.7`
- `mipmaps/generate=false`
- `process/size_limit=0`

즉 아직 카테고리별 최적화 정책이 적용되어 있지 않습니다. 카드와 몬스터 수가 늘어나기 전에 import 정책을 고정하는 것이 좋습니다.

## 우선순위

1. `cardart_full`, `monster/spriteSheet`, `ui atlas` 각각의 import preset을 정합니다.
2. 대표 카드 1장, 몬스터 1장, UI atlas 1개로 압축 품질 A/B 테스트를 합니다.
3. 품질 기준이 정해지면 같은 폴더의 `.import` 설정을 일괄 적용합니다.
4. 카드 UI는 2배 기준 레이아웃으로 바꾸되, 카드 아트 해상도는 현재 `1024x1536`급을 유지합니다.
5. `card/cardart` 레거시 폴더와 남은 소형 reference 파일의 정리 여부를 별도 결정합니다.
