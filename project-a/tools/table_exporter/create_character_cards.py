#!/usr/bin/env python3
"""Create CharacterCards.xlsx with normalized card and effect authoring tables."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

import openpyxl


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
    "D": 22,
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
    "stance",
    "effect_type",
    "target",
    "card_type",
    "buff",
    "percent",
    "amount",
    "duration_turns",
    "scope",
    "condition",
    "text_arg_index",
]
EFFECT_TYPES = [
    None,
    "key,string",
    "string",
    "string",
    "string",
    "string",
    "string,null",
    "string",
    "string,null",
    "string,null",
    "string,null",
    "int,null",
    "int,null",
    "int,null",
    "string,null",
    "string,null",
    "int,null",
]
EFFECT_WIDTHS = {
    "B": 38,
    "C": 24,
    "D": 12,
    "E": 22,
    "F": 18,
    "G": 12,
    "H": 22,
    "I": 16,
    "J": 18,
    "K": 20,
    "L": 12,
    "M": 12,
    "N": 18,
    "O": 18,
    "P": 26,
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


def card_key(character: str, card_id: str) -> str:
    return f"{character}/{card_id}"


def load_generated(project_root: Path, file_name: str) -> list[dict[str, Any]]:
    path = project_root / "data" / "generated" / file_name
    return json.loads(path.read_text(encoding="utf-8"))


def build_character_cards(sheet, cards: list[dict[str, Any]]) -> None:
    sheet.append([None])
    sheet.append(["#data", *CARD_FIELDS])
    sheet.append(CARD_TYPES)
    sheet.append([None, *["data"] * len(CARD_FIELDS)])
    for card in cards:
        character = str(card.get("character", ""))
        card_id = str(card.get("id", ""))
        sheet.append([
            None,
            card.get("card_key", card_key(character, card_id)),
            character,
            card_id,
            card.get("display_name", ""),
            card.get("cost", 0),
            card.get("card_type", "skill"),
            card.get("motion_animation", "Idle"),
            card.get("text_template", card.get("text", "")),
            card.get("copies", 1),
            ",".join(card.get("keywords", [])),
        ])
    for column, width in CARD_WIDTHS.items():
        sheet.column_dimensions[column].width = width
    sheet.freeze_panes = "A5"


def build_card_effect_rows(sheet, effect_rows: list[dict[str, Any]]) -> None:
    sheet.append([None])
    sheet.append(["#data", *EFFECT_FIELDS])
    sheet.append(EFFECT_TYPES)
    sheet.append([None, *["data"] * len(EFFECT_FIELDS)])
    for row in effect_rows:
        sheet.append([None, *[row.get(field) for field in EFFECT_FIELDS]])
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
    build_character_cards(workbook.active, load_generated(project_root, "character_cards.json"))
    workbook.active.title = "character_cards"
    build_card_effect_rows(
        workbook.create_sheet("card_effect_rows"),
        load_generated(project_root, "card_effect_rows.json"),
    )
    build_card_effects(workbook.create_sheet("card_effects"), glossary_path)

    workbook.save(output_dir / "CharacterCards.xlsx")


if __name__ == "__main__":
    main()
