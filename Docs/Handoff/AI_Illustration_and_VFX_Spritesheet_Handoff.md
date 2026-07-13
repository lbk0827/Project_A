# AI 일러스트 및 VFX 스프라이트시트 제작 인수인계서

## 1. 목적

이 문서는 Project A에서 다른 에이전트가 캐릭터 카드 일러스트와 전투 VFX
스프라이트시트를 동일한 품질 기준으로 제작하고 Godot에 연결할 수 있도록
실제 Moon Slash 작업 절차를 정리한 인수인계서다.

핵심은 이미지를 한 번에 잘 생성하는 것이 아니라 다음 순서를 지키는 것이다.

1. 게임에서 필요한 장면과 프레임 역할을 먼저 정의한다.
2. 기존 캐릭터와 아트의 변하지 않아야 할 특징을 고정한다.
3. 생성 결과를 프로젝트 규격에 맞게 후처리한다.
4. 게임 판정 타이밍과 시각 프레임을 코드로 연결한다.
5. 정적 검사와 실제 엔진 검사를 모두 수행한다.

## 2. 공통 품질 원칙

### 게임에서 읽히는 형태를 우선한다

- 카드 일러스트는 작은 카드 크기에서도 얼굴, 무기, 주 효과가 구분되어야 한다.
- VFX는 몬스터 실루엣을 완전히 가리지 않으면서 타격 방향이 읽혀야 한다.
- 세부 묘사보다 실루엣, 명암 대비, 색상 계층을 먼저 확정한다.
- 캐릭터 본체, 카드 아트, 전투 VFX는 가능하면 별도 리소스로 관리한다.

### 생성 전에 불변 조건을 적는다

캐릭터 작업에서는 다음 항목을 프롬프트의 `Constraints`에 반복해서 넣는다.

- 머리색과 머리 모양
- 눈 색상
- 의상 색상과 주요 장식
- 무기 종류와 개수
- 캐릭터의 체형과 인상
- 카드 또는 프레임 내부에서 잘리면 안 되는 부위

Moon Slash 카드의 츠키는 다음 특징을 고정했다.

- 은백색 장발과 높은 포니테일
- 붉은 눈
- 흰색, 검은색, 금색 중심의 동양풍 전투 의상
- 옥색 머리 장식
- 일본도 한 자루와 칼집
- 보름달과 보라색 월광 참격

### 이미지 역할을 명시한다

참고 이미지를 사용할 때는 각 이미지의 역할을 구분한다.

- `identity reference`: 캐릭터 외형만 참고
- `pose reference`: 자세와 동세만 참고
- `style reference`: 색감과 렌더링 방식만 참고
- `edit target`: 원본을 유지하면서 일부만 변경

역할을 섞으면 캐릭터의 얼굴이나 의상이 포즈 참고 이미지 쪽으로 변형되기 쉽다.

## 3. 카드 일러스트 제작 절차

### 3.1 게임 UI 규격 조사

이미지 생성 전에 기존 카드가 로드되는 경로와 화면 비율을 확인한다.

- 카드 아트 경로 규칙:
  `assets/card/cardart_full/<character>_<card_id>.png`
- 츠키 Moon Slash:
  `assets/card/cardart_full/tsuki_moon_slash.png`
- 카드 UI:
  `scenes/ui/cards/CardViewLarge.tscn`
- 로더:
  `scripts/ui/card_preview_large.gd`

기존 카드가 세로형이므로 인물과 핵심 효과를 세로 구도에 맞춰 배치한다.

### 3.2 프롬프트 구성 순서

프롬프트는 아래 순서로 작성한다.

1. `Use case`: stylized-concept
2. `Asset type`: vertical game card illustration
3. `Input images`: 외형/포즈 참고 이미지의 역할
4. `Primary request`: 캐릭터와 행동
5. `Scene/backdrop`: 달, 밤, 전투 배경
6. `Composition/framing`: 전신 또는 상체, 무기 방향, 여백
7. `Lighting/mood`: 월광, 보라색 검광, 필살기 분위기
8. `Constraints`: 외형 고정, 텍스트·로고·워터마크 금지

Moon Slash 카드에서 사용한 핵심 프롬프트 논리는 다음과 같다.

```text
Use case: stylized-concept
Asset type: vertical action-RPG ultimate skill card illustration
Subject: Tsuki, a silver-white-haired swordswoman with a high ponytail,
red eyes, jade hair ornament, and elegant white-black-gold outfit
Primary request: a wide grounded iai stance with one katana and scabbard,
performing five moonlight slashes
Scene/backdrop: an enormous full moon and violet-blue energy trails
Composition/framing: full body visible, face readable, sword silhouette clear,
strong vertical card composition
Constraints: preserve Tsuki identity and outfit; exactly one katana and one
scabbard; no text, UI, logo, watermark, or cropped limbs
```

### 3.3 결과 선택 기준

- 얼굴이 기존 캐릭터와 같은 인물로 읽히는가?
- 한 손의 검과 다른 손의 칼집이 자연스러운가?
- 손가락과 무기 구조에 큰 오류가 없는가?
- 작은 카드 크기에서 달과 참격이 구분되는가?
- 이름과 설명이 올라갈 영역을 지나치게 복잡하게 만들지 않았는가?
- 화면 밖으로 머리카락, 발, 검 끝이 부자연스럽게 잘리지 않았는가?

### 3.4 Godot 연결

카드 데이터의 `character`와 `id`가 파일명과 일치해야 한다.

```text
character = tsuki
id = moon_slash
file = tsuki_moon_slash.png
```

컷인에서 일러스트 전체를 보이게 하려면 `COVERED` 자동 크롭에 의존하지
않고 원본 비율을 직접 계산한다.

```gdscript
var area: Vector2 = frame.size - Vector2(12, 12)
var source := Vector2(texture.get_width(), texture.get_height())
var fit_scale: float = min(area.x / source.x, area.y / source.y)
portrait.size = source * fit_scale
portrait.position = (frame.size - portrait.size) * 0.5
portrait.stretch_mode = TextureRect.STRETCH_SCALE
```

## 4. VFX 스프라이트시트 제작 절차

## 4.1 먼저 타임라인을 설계한다

프롬프트를 작성하기 전에 게임 판정과 필요한 프레임을 표로 만든다.

Moon Slash는 4×4, 총 16프레임으로 구성했다.

| 프레임 | 역할 | 게임 이벤트 |
| --- | --- | --- |
| 0~3 | 달 생성 | VFX `reveal()` |
| 4 | 첫 번째 참격 | 1타 피해 |
| 5 | 두 번째 참격 | 2타 피해 |
| 6 | 세 번째 참격 | 3타 피해 |
| 7 | 네 번째 참격 | 4타 피해 |
| 8 | 다섯 번째 참격과 완전 균열 | 5타 피해 |
| 9~15 | 조각 분리와 소멸 | `shatter()` |

게임 판정이 5타라면 시트에도 정확히 다섯 개의 명확한 누적 단계가 있어야
한다. 보기 좋은 애니메이션을 먼저 만든 뒤 판정을 억지로 맞추지 않는다.

### 4.2 배경 방식 선택

VFX에는 부드러운 광원, 입자, 반투명 검광이 많다. 이 경우 크로마키 제거는
가장자리 색 번짐을 손상시킬 수 있다. Moon Slash에서는 다음 방식을 사용했다.

- 균일한 순수 검은 배경으로 생성
- Godot `CanvasItemMaterial`의 가산 합성 사용
- 검은 픽셀은 사라지고 청백색·보라색 빛만 누적

불투명한 아이콘이나 캐릭터처럼 경계가 명확한 리소스는 크로마키와 알파
제거가 적합하지만, 빛·연기·마법 VFX에는 검은 배경과 가산 합성이 더 안정적이다.

### 4.3 실제 프롬프트 구조

```text
Use case: stylized-concept
Asset type: 2D game VFX sprite sheet for Godot
Input image: icy blue-white moon texture and cyan rim glow reference
Primary request: exactly 4 columns by 4 rows, 16 equal square cells,
row-major animation order; the same centered moon at identical scale and
position in every cell
Frames 1-3: moon materializes from a cyan ring
Frames 4-8: exactly five katana slash cuts accumulate one at a time
Frames 9-12: cracks intensify and pieces begin separating
Frames 13-16: moon bursts into fragments and luminous dust, fading outward
Scene/backdrop: perfectly uniform pure black background for additive blending
Composition: consistent padding; no effect crosses cell boundaries
Constraints: exactly 4x4; no grid lines, gutters, character, scenery, text,
numbers, UI, logo, checkerboard, or watermark
```

특히 다음 문구가 품질에 중요하다.

- `same scale and position in every cell`
- `exactly 4 columns by 4 rows`
- `row-major animation order`
- `no effect crosses a cell boundary`
- `no grid lines and no gutters`
- `exactly five distinct slash stages`

### 4.4 후처리

생성 모델의 결과 크기가 그리드로 나누어떨어지지 않을 수 있다.

Moon Slash 원본은 1254×1254였고, 가장자리를 1px씩 잘라 1252×1252로
만들었다. 4로 정확히 나누어 셀 크기 313×313을 확보했다.

확인 항목:

- 전체 너비와 높이가 열/행 개수로 나누어떨어지는가?
- 각 셀의 중심이 같은가?
- 효과가 인접 셀로 넘어가지 않는가?
- 첫 프레임과 마지막 프레임의 배경이 실제 검은색에 가까운가?
- 잘라내기 후 달이나 파편이 손상되지 않았는가?

후처리는 원본을 보관한 상태에서 프로젝트용 사본에 수행한다.

## 5. Godot 하이브리드 VFX 연결

### 5.1 Sprite2D 설정

Moon Slash는 `AnimatedSprite2D` 대신 단일 `Sprite2D`의 `frame`을 게임
판정 코드에서 직접 변경한다.

```text
texture = moon_slash_sheet.png
hframes = 4
vframes = 4
material.blend_mode = ADD
```

장면 위치:

- `scenes/vfx/fx_tsuki_moon_slash.tscn`
- `scripts/vfx/moon_slash_vfx.gd`

### 5.2 판정과 프레임 동기화

프레임을 일정 FPS로만 재생하면 프레임 드롭이나 연출 시간 수정 시 피해와
시각 효과가 어긋날 수 있다. 실제 타격 함수가 해당 프레임을 지정하게 한다.

```gdscript
func apply_slash(hit_index: int):
    active_slash = clamp(hit_index, 0, 4)
    sprite_sheet.frame = 4 + active_slash
```

달 생성과 파괴처럼 판정이 없는 구간만 시간 기반으로 순차 재생한다.

```gdscript
_animate_sheet_frames(0, 3, reveal_time)
_animate_sheet_frames(9, 15, shatter_time)
```

### 5.3 하이브리드 효과

스프라이트시트 하나에 모든 효과를 넣지 않는다.

- 스프라이트시트: 달의 형태, 누적 균열, 조각 분리
- 코드 드로잉: 타격 순간의 날카로운 백색 섬광
- 절차형 조각: 시트 위에 추가되는 짧은 보조 파편
- 게임 코드: 피해, 치명타, 버프 및 타격 간격

이 구조는 핵심 연출을 미술 리소스가 담당하면서도 타격감과 게임 판정을
코드에서 자유롭게 조정할 수 있게 한다.

## 6. 검증 절차

### 이미지 검사

- 카드 아트가 세로형인가?
- 시트가 정사각형이고 그리드 수로 정확히 나누어지는가?
- 셀 해상도가 최소 256px 이상인가?
- 검은 배경 가산 합성에서 사각형 테두리가 보이지 않는가?
- 모든 프레임의 중심과 크기가 안정적인가?

### Godot 검사

- 신규 PNG의 `.import` 파일이 생성되었는가?
- 장면의 리소스 경로가 존재하는가?
- `hframes`, `vframes`와 실제 그리드가 일치하는가?
- 첫 타격부터 다섯 번째 타격까지 프레임이 한 단계씩 증가하는가?
- 파괴 구간이 끝난 뒤 VFX 노드가 제거되는가?
- 여러 몬스터에게 동시에 생성해도 프레임과 판정이 독립적인가?

### 명령 기반 검사

```powershell
python tools/table_exporter/validate_rp_runtime_assets.py
godot --headless --path project-a --editor --quit-after 2
git diff --check
```

현재 프로젝트의 실제 Godot 버전은 4.6.3이다. 가능한 경우 사용자가 실행하는
버전과 동일한 실행 파일로 헤드리스 검사를 수행한다.

## 7. 다른 에이전트용 작업 순서

1. 기존 카드, 캐릭터 초상화, VFX와 데이터 경로를 조사한다.
2. 변경하면 안 되는 캐릭터 특징을 목록으로 작성한다.
3. 게임 판정 기준으로 스프라이트시트 프레임 표를 만든다.
4. 카드 일러스트와 VFX 시트는 별도 프롬프트와 별도 파일로 생성한다.
5. 생성 결과를 직접 보고 손, 무기, 프레임 정렬과 잘림을 검사한다.
6. 프로젝트용 파일을 규칙에 맞는 이름으로 복사한다.
7. 시트 크기를 그리드로 정확히 나누어지도록 후처리한다.
8. Godot import 후 프레임과 합성 모드를 설정한다.
9. 실제 게임 이벤트가 타격 프레임을 직접 선택하도록 연결한다.
10. 이미지 검사, 정적 검사, Godot 파싱 검사를 수행한다.
11. 실제 전투에서 크기, 위치, 타격감과 여러 적 동시 재생을 확인한다.
12. 사용한 프롬프트, 프레임 매핑, 후처리 수치와 파일 경로를 문서에 남긴다.

## 8. 실패 패턴과 대응

### 캐릭터 외형이 달라진다

- 포즈 참고 이미지와 외형 참고 이미지의 역할을 분리한다.
- 외형 참고 이미지를 하나의 정체성 기준으로 고정한다.
- 머리, 눈, 의상, 장식, 무기 개수를 Constraints에 다시 적는다.

### 카드에서 인물이 잘린다

- `full body visible`, `generous padding`, `no cropped limbs`를 명시한다.
- 컷인에서는 `KEEP_ASPECT_COVERED` 대신 직접 맞춤 배율을 계산한다.

### 시트 프레임마다 달 크기가 변한다

- `same centered moon`, `identical scale`, `fixed camera`를 함께 명시한다.
- 결과가 심하게 흔들리면 생성된 시트를 억지로 사용하지 말고 다시 생성한다.

### 스프라이트시트의 칸 수가 틀린다

- 칸 수, 행·열, 총 프레임을 프롬프트 여러 위치에서 일관되게 반복한다.
- 숫자 라벨을 요청하지 않는다. 라벨이 VFX에 섞일 수 있다.

### 검은 사각형이 보인다

- `CanvasItemMaterial`의 `blend_mode = ADD` 여부를 확인한다.
- 배경이 순수 검은색이 아니라 회색 그라데이션이면 재생성하거나 레벨을 보정한다.
- 일반 알파 합성과 가산 합성을 중복 적용하지 않는다.

### 피해와 참격이 어긋난다

- 전체 시트를 독립 FPS로 재생하지 않는다.
- 타격 처리 함수가 해당 누적 프레임을 직접 지정하도록 한다.
- 테이블의 `hit_count`와 시트의 타격 단계 수가 같은지 검증한다.

## 9. 이번 작업의 최종 리소스

- 카드 일러스트:
  `project-a/assets/card/cardart_full/tsuki_moon_slash.png`
- VFX 스프라이트시트:
  `project-a/assets/vfx/moon_slash_sheet.png`
- 보조 달 텍스처:
  `project-a/assets/vfx/moon_slash_moon.png`
- VFX 장면:
  `project-a/scenes/vfx/fx_tsuki_moon_slash.tscn`
- VFX 제어 코드:
  `project-a/scripts/vfx/moon_slash_vfx.gd`
- RP 구현 기록:
  `Docs/Implementation/Tsuki_RP_Skill_Worklog.md`

향후 다른 캐릭터의 RP 스킬을 만들 때 이 문서를 기본 제작 절차로 사용하고,
해당 캐릭터의 외형 불변 조건과 스킬별 프레임 표만 별도로 추가하면 된다.
