#!/usr/bin/env python3
"""Create CharacterCards.xlsx: Tsuki's card set and the effect keyword table.

- character_cards: one row per card.
- card_effects: keyword glossary parsed from Docs/Card_Effects_Glossary.md.

Damage percents are based on attack_power; shield percents are based on
defense_power.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

import openpyxl


def _effects(*items) -> str:
    return json.dumps(list(items), ensure_ascii=False)


# character, id, display_name, cost, card_type, motion_animation, text, copies, keywords, effects, inspiration
CHARACTER_CARDS = [
    (
        "tsuki",
        "long_sword_slash",
        "장검 베기",
        1,
        "attack",
        "Attack",
        "피해 100%.",
        2,
        [],
        _effects({"type": "damage", "percent": 100, "target": "enemy"}),
        None,
    ),
    (
        "tsuki",
        "high_speed_slash",
        "고속 베기",
        2,
        "attack",
        "Attack",
        "피해 220%.",
        1,
        [],
        _effects({"type": "damage", "percent": 220, "target": "enemy"}),
        None,
    ),
    (
        "tsuki",
        "let_flow",
        "흘려 보내기",
        1,
        "skill",
        "Idle",
        "실드 100%.",
        1,
        [],
        _effects({"type": "shield", "percent": 100, "target": "self"}),
        None,
    ),
    (
        "tsuki",
        "suppress_ready",
        "제압 준비",
        0,
        "skill",
        "Idle",
        "자신의 공격 카드 드로우 1. 1턴간 자신의 공격 카드 피해량 40% 증가.",
        1,
        [],
        _effects(
            {"type": "draw", "card_type": "attack", "amount": 1},
            {
                "type": "buff",
                "buff": "attack_damage_up",
                "percent": 40,
                "duration_turns": 1,
                "scope": "own_attack",
            },
        ),
        None,
    ),
    (
        "tsuki",
        "steal_slash",
        "훔쳐베기",
        2,
        "attack",
        "Attack",
        "모든 적 피해 220%. 영감: 비용 1 감소.",
        1,
        ["영감"],
        _effects({"type": "damage", "percent": 220, "target": "all_enemies"}),
        _effects({"type": "cost_delta", "amount": -1}),
    ),
    (
        "tsuki",
        "feint_strike",
        "눈속임 일격",
        1,
        "attack",
        "Attack",
        "[보존] 피해 180%. 핸드의 무작위 자신의 카드 1장의 영감 효과를 활성화.",
        1,
        ["보존"],
        _effects(
            {"type": "damage", "percent": 180, "target": "enemy"},
            {
                "type": "activate_inspiration",
                "target": "random_own_in_hand",
                "amount": 1,
            },
        ),
        None,
    ),
    (
        "tsuki",
        "freezing_blade",
        "빙점 칼날",
        1,
        "enhance",
        "Idle",
        "[유일] 자신의 영감 효과가 활성화된 카드 사용 시 모든 적에게 피해 120%.",
        1,
        ["유일"],
        _effects(
            {
                "type": "passive",
                "trigger": "on_play_inspired_card",
                "effect": {
                    "type": "damage",
                    "percent": 120,
                    "target": "all_enemies",
                },
            }
        ),
        None,
    ),
    (
        "tsuki",
        "iceberg_cleave",
        "빙산 가르기",
        1,
        "attack",
        "Attack",
        "모든 적 피해 180%. 영감: 타격 1회 추가, 피해량 20% 감소.",
        1,
        ["영감"],
        _effects({"type": "damage", "percent": 180, "target": "all_enemies"}),
        _effects(
            {"type": "add_hit", "amount": 1},
            {"type": "damage_delta", "percent": -20},
        ),
    ),
]

CARD_FIELDS = [
    "character",
    "id",
    "display_name",
    "cost",
    "card_type",
    "motion_animation",
    "text",
    "copies",
    "keywords[]",
    "effects",
    "inspiration",
]
CARD_TYPES = [
    None,
    "string",
    "key,string",
    "string",
    "int",
    "string",
    "string",
    "string",
    "int",
    "string",
    "json",
    "json,null",
]
CARD_WIDTHS = {
    "B": 12,
    "C": 20,
    "D": 18,
    "E": 8,
    "F": 12,
    "G": 18,
    "H": 46,
    "I": 8,
    "J": 16,
    "K": 52,
    "L": 40,
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
    for character, card_id, name, cost, card_type, motion_animation, text, copies, keywords, effects, inspiration in CHARACTER_CARDS:
        sheet.append(
            [
                None,
                character,
                card_id,
                name,
                cost,
                card_type,
                motion_animation,
                text,
                copies,
                ",".join(keywords),
                effects,
                inspiration,
            ]
        )
    for column, width in CARD_WIDTHS.items():
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
    build_card_effects(workbook.create_sheet("card_effects"), glossary_path)

    workbook.save(output_dir / "CharacterCards.xlsx")


if __name__ == "__main__":
    main()
