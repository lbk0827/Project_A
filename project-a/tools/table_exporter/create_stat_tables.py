#!/usr/bin/env python3
"""Create the combatant stat table workbook (player growth + monster stats).

Follows the same #data layout the exporter expects. The player growth sheet is
a reference progression table (level -> stats) for a future character screen;
combat reads the current tier. Monster stats mirror the same schema so both
sides share crit fields. Crit values are stored as fractions/multipliers
(crit_rate 0.03 = 3%, crit_damage 1.25 = +25%).
"""

from __future__ import annotations

from pathlib import Path

import openpyxl


# level, attack_power, defense_power, max_hp
PLAYER_GROWTH = [
	(1, 160, 45, 90),
	(10, 195, 58, 131),
	(20, 249, 77, 180),
	(30, 304, 97, 229),
	(40, 358, 116, 278),
	(50, 413, 136, 327),
	(60, 467, 155, 376),
]
PLAYER_CRIT_RATE = 0.03
PLAYER_CRIT_DAMAGE = 1.25

# id, display_name, max_hp, attack_power, defense_power, crit_rate, crit_damage
# Monsters currently deal damage through intents (flat amounts), so attack_power
# is 0 and crit is disabled (0.0 / 1.0) until a design pass sets enemy crit.
MONSTER_STATS = [
	("mire_imp", "Mire Imp", 44, 0, 0, 0.0, 1.0),
	("bone_crawler", "Bone Crawler", 52, 0, 0, 0.0, 1.0),
	("abyssal_crown_guardian", "Abyssal Crown Guardian", 160, 0, 0, 0.0, 1.0),
	("monster_dummy", "Training Goblin", 44, 0, 0, 0.0, 1.0),
]


def build_player_growth(sheet) -> None:
	sheet.append([None])
	sheet.append(["#data", "character", "level", "attack_power", "defense_power", "max_hp", "crit_rate", "crit_damage"])
	sheet.append([None, "string", "key,int", "int", "int", "int", "float", "float"])
	sheet.append([None, "data", "data", "data", "data", "data", "data", "data"])
	for level, atk, defense, hp in PLAYER_GROWTH:
		sheet.append([None, "tsuki", level, atk, defense, hp, PLAYER_CRIT_RATE, PLAYER_CRIT_DAMAGE])
	_apply_widths(sheet, {"B": 10, "C": 8, "D": 14, "E": 14, "F": 10, "G": 12, "H": 12})


def build_monster_stats(sheet) -> None:
	sheet.append([None])
	sheet.append(["#data", "id", "display_name", "max_hp", "attack_power", "defense_power", "crit_rate", "crit_damage"])
	sheet.append([None, "key,string", "string", "int", "int", "int", "float", "float"])
	sheet.append([None, "data", "data", "data", "data", "data", "data", "data"])
	for row in MONSTER_STATS:
		sheet.append([None, *row])
	_apply_widths(sheet, {"B": 24, "C": 26, "D": 10, "E": 14, "F": 14, "G": 12, "H": 12})


def _apply_widths(sheet, widths: dict[str, int]) -> None:
	for column, width in widths.items():
		sheet.column_dimensions[column].width = width
	sheet.freeze_panes = "A5"


def main() -> None:
	project_root = Path(__file__).resolve().parents[2]
	output_dir = project_root / "tables" / "excel"
	output_dir.mkdir(parents=True, exist_ok=True)

	workbook = openpyxl.Workbook()
	build_player_growth(workbook.active)
	workbook.active.title = "player_growth"
	build_monster_stats(workbook.create_sheet("monster_stats"))

	workbook.save(output_dir / "StatTable.xlsx")


if __name__ == "__main__":
	main()
