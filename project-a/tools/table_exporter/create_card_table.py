#!/usr/bin/env python3
"""Rebuild CardTable.xlsx from the current (Korean) cards.json.

The workbook is the authoring source the exporter reads, but it had drifted out
of sync with cards.json (English sample vs Korean data). This regenerates the
workbook from cards.json so a round-trip export reproduces cards.json exactly.
"""

from __future__ import annotations

import json
from pathlib import Path

import openpyxl

FIELDS = ["id", "display_name", "cost", "text", "card_type", "requires_target", "effects"]
TYPES = ["key,string", "string", "int", "string", "string", "bool", "json"]
WIDTHS = {"B": 18, "C": 18, "D": 8, "E": 40, "F": 12, "G": 16, "H": 62}


def main() -> None:
	project_root = Path(__file__).resolve().parents[2]
	cards_path = project_root / "data" / "generated" / "cards.json"
	output_dir = project_root / "tables" / "excel"
	output_dir.mkdir(parents=True, exist_ok=True)

	cards = json.loads(cards_path.read_text(encoding="utf-8"))

	workbook = openpyxl.Workbook()
	sheet = workbook.active
	sheet.title = "cards"

	sheet.append([None])
	sheet.append(["#data", *FIELDS])
	sheet.append([None, *TYPES])
	sheet.append([None, *["data"] * len(FIELDS)])

	for card in cards:
		sheet.append([
			None,
			card["id"],
			card["display_name"],
			card["cost"],
			card["text"],
			card["card_type"],
			card["requires_target"],
			json.dumps(card["effects"], ensure_ascii=False),
		])

	for column, width in WIDTHS.items():
		sheet.column_dimensions[column].width = width
	sheet.freeze_panes = "A5"

	workbook.save(output_dir / "CardTable.xlsx")


if __name__ == "__main__":
	main()
