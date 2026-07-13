#!/usr/bin/env python3
"""Create CharacterCards.xlsx with normalized card and effect authoring tables.

- character_cards: one row per card, with identity, presentation, and keywords.
- card_effect_rows: one row per authored effect, grouped by card_key + trigger.
- card_effects: keyword glossary parsed from Docs/Card_Effects_Glossary.md.

Damage percents are based on attack_power; shield percents are based on
defense_power.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

import openpyxl


# character, id, display_name, cost, card_type, motion_animation, text_template, copies, keywords
CHARACTER_CARDS = [
    ("tsuki", "long_sword_slash", "장검 베기", 1, "attack", "Attack", "피해 {0}%.", 2, []),
    ("tsuki", "high_speed_slash", "고속 베기", 2, "attack", "Attack", "피해 {0}%.", 1, []),
    ("tsuki", "let_flow", "흘려 보내기", 1, "skill", "Idle", "실드 {0}%.", 1, []),
    (
        "tsuki",
        "suppress_ready",
        "제압 준비",
        0,
        "skill",
        "Idle",
        "자신의 공격 카드 드로우 {0}. {2}턴간 자신의 공격 카드 피해량 {1}% 증가.",
        1,
        [],
    ),
    (
        "tsuki",
        "steal_slash",
        "훔쳐베기",
        2,
        "attack",
        "Attack",
        "모든 적 피해 {0}%. 영감: 비용 {1} 감소.",
        1,
        ["영감"],
    ),
    (
        "tsuki",
        "feint_strike",
        "눈속임 일격",
        1,
        "attack",
        "Attack",
        "[보존] 피해 {0}%. 핸드의 무작위 자신의 카드 {1}장의 영감 효과를 활성화.",
        1,
        ["보존"],
    ),
    (
        "tsuki",
        "freezing_blade",
        "빙점 칼날",
        1,
        "enhance",
        "Idle",
        "[유일] 자신의 영감 효과가 활성화된 카드 사용 시 모든 적에게 피해 {0}%.",
        1,
        ["유일"],
    ),
    (
        "tsuki",
        "iceberg_cleave",
        "빙산 가르기",
        1,
        "attack",
        "Attack",
        "모든 적 피해 {0}%. 영감: 타격 {1}회 추가, 피해량 {2}% 감소.",
        1,
        ["영감"],
    ),
]


def card_key(character: str, card_id: str) -> str:
    return f"{character}/{card_id}"


def effect_row(
    row_id: str,
    character: str,
    card_id: str,
    trigger: str,
    effect_type: str,
    *,
    target: str | None = None,
    card_type: str | None = None,
    buff: str | None = None,
    percent: int | None = None,
    amount: int | None = None,
    duration_turns: int | None = None,
    scope: str | None = None,
    child_effect_type: str | None = None,
    child_target: str | None = None,
    child_percent: int | None = None,
    text_arg_index: int | None = None,
) -> dict[str, Any]:
    return {
        "id": row_id,
        "card_key": card_key(character, card_id),
        "character": character,
        "card_id": card_id,
        "trigger": trigger,
        "effect_type": effect_type,
        "target": target,
        "card_type": card_type,
        "buff": buff,
        "percent": percent,
        "amount": amount,
        "duration_turns": duration_turns,
        "scope": scope,
        "child_effect_type": child_effect_type,
        "child_target": child_target,
        "child_percent": child_percent,
        "text_arg_index": text_arg_index,
    }


CARD_EFFECT_ROWS = [
    effect_row("tsuki_long_sword_slash_damage", "tsuki", "long_sword_slash", "on_play", "damage", target="enemy", percent=100, text_arg_index=0),
    effect_row("tsuki_high_speed_slash_damage", "tsuki", "high_speed_slash", "on_play", "damage", target="enemy", percent=220, text_arg_index=0),
    effect_row("tsuki_let_flow_shield", "tsuki", "let_flow", "on_play", "shield", target="self", percent=100, text_arg_index=0),
    effect_row("tsuki_suppress_ready_draw", "tsuki", "suppress_ready", "on_play", "draw", card_type="attack", amount=1, text_arg_index=0),
    effect_row(
        "tsuki_suppress_ready_attack_buff",
        "tsuki",
        "suppress_ready",
        "on_play",
        "buff",
        buff="attack_damage_up",
        percent=40,
        duration_turns=1,
        scope="own_attack",
        text_arg_index=1,
    ),
    effect_row("tsuki_suppress_ready_buff_turns_text", "tsuki", "suppress_ready", "text_only", "value", amount=1, text_arg_index=2),
    effect_row("tsuki_steal_slash_damage", "tsuki", "steal_slash", "on_play", "damage", target="all_enemies", percent=220, text_arg_index=0),
    effect_row("tsuki_steal_slash_inspiration_cost", "tsuki", "steal_slash", "on_inspiration", "cost_delta", amount=-1, text_arg_index=1),
    effect_row("tsuki_feint_strike_damage", "tsuki", "feint_strike", "on_play", "damage", target="enemy", percent=180, text_arg_index=0),
    effect_row(
        "tsuki_feint_strike_activate_inspiration",
        "tsuki",
        "feint_strike",
        "on_play",
        "activate_inspiration",
        target="random_own_in_hand",
        amount=1,
        text_arg_index=1,
    ),
    effect_row(
        "tsuki_freezing_blade_passive_damage",
        "tsuki",
        "freezing_blade",
        "on_play_inspired_card",
        "damage",
        target="all_enemies",
        percent=120,
        text_arg_index=0,
    ),
    effect_row("tsuki_iceberg_cleave_damage", "tsuki", "iceberg_cleave", "on_play", "damage", target="all_enemies", percent=180, text_arg_index=0),
    effect_row("tsuki_iceberg_cleave_extra_hit", "tsuki", "iceberg_cleave", "on_inspiration", "add_hit", amount=1, text_arg_index=1),
    effect_row("tsuki_iceberg_cleave_damage_delta", "tsuki", "iceberg_cleave", "on_inspiration", "damage_delta", percent=-20, text_arg_index=2),
]

CARD_FIELDS = [
    "card_key",
    "character",
    "id",
    "display_name",
    "cost",
    "card_type",
    "motion_animation",
    "text_template",
    "copies",
    "keywords[]",
]
CARD_TYPES = [
    None,
    "key,string",
    "string",
    "string",
    "string",
    "int",
    "string",
    "string",
    "string",
    "int",
    "string",
]
CARD_WIDTHS = {
    "B": 24,
    "C": 12,
    "D": 20,
    "E": 18,
    "F": 8,
    "G": 12,
    "H": 18,
    "I": 72,
    "J": 8,
    "K": 18,
}

EFFECT_FIELDS = [
    "id",
    "card_key",
    "character",
    "card_id",
    "trigger",
    "effect_type",
    "target",
    "card_type",
    "buff",
    "percent",
    "amount",
    "duration_turns",
    "scope",
    "child_effect_type",
    "child_target",
    "child_percent",
    "text_arg_index",
]
EFFECT_TYPES = [
    None,
    "key,string",
    "string",
    "string",
    "string",
    "string",
    "string",
    "string,null",
    "string,null",
    "string,null",
    "int,null",
    "int,null",
    "int,null",
    "string,null",
    "string,null",
    "string,null",
    "int,null",
    "int,null",
]
EFFECT_WIDTHS = {
    "B": 34,
    "C": 24,
    "D": 12,
    "E": 22,
    "F": 22,
    "G": 24,
    "H": 16,
    "I": 22,
    "J": 12,
    "K": 12,
    "L": 18,
    "M": 18,
    "N": 22,
    "O": 20,
    "P": 18,
    "Q": 16,
}

GLOSSARY_SECTIONS = {
    "카드 사용 관련": "카드사용",
    "이로운 효과 관련": "이로운",
    "해로운 효과 관련": "해로운",
    # Temporary compatibility with currently mojibaked glossary headers.
    "移대뱶 ?ъ슜 愿??": "카드사용",
    "?대줈???④낵 愿??": "이로운",
    "紐ъ뒪???④낵 愿??": "해로운",
}


def build_character_cards(sheet) -> None:
    sheet.append([None])
    sheet.append(["#data", *CARD_FIELDS])
    sheet.append(CARD_TYPES)
    sheet.append([None, *["data"] * len(CARD_FIELDS)])
    for character, card_id, name, cost, card_type, motion_animation, text, copies, keywords in CHARACTER_CARDS:
        sheet.append([
            None,
            card_key(character, card_id),
            character,
            card_id,
            name,
            cost,
            card_type,
            motion_animation,
            text,
            copies,
            ",".join(keywords),
        ])
    for column, width in CARD_WIDTHS.items():
        sheet.column_dimensions[column].width = width
    sheet.freeze_panes = "A5"


def build_card_effect_rows(sheet) -> None:
    sheet.append([None])
    sheet.append(["#data", *EFFECT_FIELDS])
    sheet.append(EFFECT_TYPES)
    sheet.append([None, *["data"] * len(EFFECT_FIELDS)])
    for row in CARD_EFFECT_ROWS:
        sheet.append([None, *[row[field] for field in EFFECT_FIELDS]])
    for column, width in EFFECT_WIDTHS.items():
        sheet.column_dimensions[column].width = width
    sheet.freeze_panes = "A5"


def parse_glossary(glossary_path: Path) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    category = ""
    for line in glossary_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        header = re.match(r"^##\s+(.*)$", stripped)
        if header:
            category = GLOSSARY_SECTIONS.get(header.group(1).strip(), "")
            continue
        if not category or not stripped.startswith("|"):
            continue
        cells = [cell.strip() for cell in stripped.strip("|").split("|")]
        if len(cells) < 2:
            continue
        keyword, description = cells[0], cells[1]
        if keyword in ("키워드", "?ㅼ썙??", "") or set(keyword) <= {"-", " "}:
            continue
        rows.append((category, keyword, description))
    return rows


def build_card_effects(sheet, glossary_path: Path) -> None:
    sheet.append([None])
    sheet.append(["#data", "keyword", "category", "description"])
    sheet.append([None, "key,string", "string", "string"])
    sheet.append([None, "data", "data", "data"])
    for category, keyword, description in parse_glossary(glossary_path):
        sheet.append([None, keyword, category, description])
    sheet.column_dimensions["B"].width = 16
    sheet.column_dimensions["C"].width = 12
    sheet.column_dimensions["D"].width = 90
    sheet.freeze_panes = "A5"


def main() -> None:
    project_root = Path(__file__).resolve().parents[2]
    repo_root = project_root.parents[0]
    glossary_path = repo_root / "Docs" / "Card_Effects_Glossary.md"
    output_dir = project_root / "tables" / "excel"
    output_dir.mkdir(parents=True, exist_ok=True)

    workbook = openpyxl.Workbook()
    build_character_cards(workbook.active)
    workbook.active.title = "character_cards"
    build_card_effect_rows(workbook.create_sheet("card_effect_rows"))
    build_card_effects(workbook.create_sheet("card_effects"), glossary_path)

    workbook.save(output_dir / "CharacterCards.xlsx")


if __name__ == "__main__":
    main()
