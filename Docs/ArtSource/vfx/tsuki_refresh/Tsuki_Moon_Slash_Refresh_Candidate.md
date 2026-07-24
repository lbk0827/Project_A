# Tsuki Moon Slash Refresh Candidate

- Status: ?? ??? ??. ?? ?/????? ???.
- Source: Codex generated preview `call_EhX37r2KcB8NYcOzBRGpNFXQ.png`.
- Structure target: existing `fx_tsuki_moon_slash.tscn` compatible 4x4 sprite sheet concept.
- Frame intent: 0-3 reveal, 4-8 slash accumulation, 9-15 shatter/disperse.
- Chromakey sheet: `tsuki_moon_slash_refresh_sheet_chromakey.png`.
- Transparent sheet: `tsuki_moon_slash_refresh_sheet_transparent.png`.
- Moon chromakey candidate: `tsuki_moon_slash_refresh_moon_chromakey.png`.
- Moon transparent candidate: `tsuki_moon_slash_refresh_moon_transparent.png`.
- Canvas: 1254x1254; nominal cell: 313x313.
- Alpha validation: corner alpha values [0, 0, 0, 0]; nontransparent pixels 628888.
- Keyed pixels: full 942125, partial edge 15621.

Notes:
- Visual quality is tuned to the Tsuki refresh candidate rather than the current runtime Tsuki.
- Before applying to runtime, compare frame scale and additive blend appearance in Godot.
