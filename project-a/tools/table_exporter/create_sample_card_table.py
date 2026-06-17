#!/usr/bin/env python3
"""Create the starter card table workbook used by the exporter example."""

from __future__ import annotations

import json
from pathlib import Path

import openpyxl


def main() -> None:
    project_root = Path(__file__).resolve().parents[2]
    output_dir = project_root / "tables" / "excel"
    output_dir.mkdir(parents=True, exist_ok=True)

    workbook = openpyxl.Workbook()
    sheet = workbook.active
    sheet.title = "cards"

    rows = [
        [None, None, None, None, None, None, None, None],
        ["#data", "id", "display_name", "cost", "text", "card_type", "requires_target", "effects"],
        [None, "key,string", "string", "int", "string", "string", "bool", "json"],
        [None, "data", "data", "data", "data", "data", "data", "data"],
        [
            None,
            "slash",
            "Slash",
            1,
            "Deal 6 damage.",
            "attack",
            True,
            json.dumps([{"type": "damage", "amount": 6, "target": "enemy"}], ensure_ascii=False),
        ],
        [
            None,
            "guard",
            "Guard",
            1,
            "Gain 7 block.",
            "skill",
            False,
            json.dumps([{"type": "block", "amount": 7, "target": "self"}], ensure_ascii=False),
        ],
        [
            None,
            "focus",
            "Focus",
            0,
            "Draw 1 card. Gain 1 energy.",
            "skill",
            False,
            json.dumps(
                [{"type": "draw", "amount": 1}, {"type": "energy", "amount": 1}],
                ensure_ascii=False,
            ),
        ],
        [
            None,
            "heavy_slash",
            "Heavy Slash",
            2,
            "Deal 12 damage.",
            "attack",
            True,
            json.dumps([{"type": "damage", "amount": 12, "target": "enemy"}], ensure_ascii=False),
        ],
    ]

    for row in rows:
        sheet.append(row)

    widths = {
        "B": 18,
        "C": 18,
        "D": 10,
        "E": 34,
        "F": 14,
        "G": 18,
        "H": 62,
    }
    for column, width in widths.items():
        sheet.column_dimensions[column].width = width

    sheet.freeze_panes = "A5"
    workbook.save(output_dir / "CardTable.xlsx")


if __name__ == "__main__":
    main()
