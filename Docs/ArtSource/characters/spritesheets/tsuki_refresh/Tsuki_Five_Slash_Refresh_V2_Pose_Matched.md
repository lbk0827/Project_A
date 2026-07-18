# Tsuki Five Slash Refresh V2 Pose Matched

- Status: ?? ??? ??. ?? ?/????? ???.
- Source: Codex generated preview `call_QHZtW1xR59IfNud8xirO7ENQ.png`.
- Purpose: ?? ?? 5?? ??/??? ??? ??? ??? ??? ??.
- Chromakey: `tsuki_five_slash_refresh_v2_pose_matched_chromakey.png`.
- Transparent: `tsuki_five_slash_refresh_v2_pose_matched_transparent.png`.
- Canvas: 1024x1536; generated layout: 4x6, nominal cell 256x256.
- Alpha validation: corner alpha values [0, 0, 0, 0]; nontransparent pixels 206159.
- Keyed pixels: full 1364703, partial edge 7205.

Notes:
- V2 prompt weighted the existing runtime five-slash sheet as the pose master.
- Runtime 적용 테스트용으로 4x6, 320x320 셀 규격에 맞춰 재패킹했습니다.
- 실제 게임 재생 QA에서 프레임별 츠키 크기 차이가 크게 보여 적용을 보류했습니다.
- `project-a/assets/characters/spritesheets/tsuki_five_slash_spritesheet.png`는 기존 런타임 버전으로 롤백했습니다.

## Runtime QA Result

- Sheet size: 1280x1920
- Layout: 4 columns x 6 rows
- Cell size: 320x320
- Edge risk frames: none
- Minimum horizontal margin: 12px
- Minimum vertical margin: 10px
- Result: rejected for runtime use because the character scale changes too much between frames.

츠키 본체 스프라이트 후보와 5연격 후보 모두 아직 런타임 적용은 보류합니다. 다음 개선 시에는 단순 셀 맞춤보다 프레임별 캐릭터 기준 높이, 발 위치, 중심축을 먼저 통일해야 합니다.
