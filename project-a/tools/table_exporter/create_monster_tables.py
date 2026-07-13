#!/usr/bin/env python3
"""Create MonsterTable.xlsx: monster intent templates + the monster roster.

- monster_intents: reusable intent templates. For "attack" intents, power is a
  percent of the monster's attack_power; for "block", power is a flat shield.
  Enemy damage = attack_power * power / 100, mirroring the player's card model,
  so a monster is tuned mainly by its attack_power in the stats table.
- monsters: the roster's behaviour (action count + intent sequence). Combat
  numbers (hp/attack_power) live in the monster_stats sheet.
"""

from __future__ import annotations

from pathlib import Path

import openpyxl

# id, display_name, intent_type, power, icon_label, description_template
MONSTER_INTENTS = [
	("stab", "Stab", "attack", 100, "ATK", "공격력의 {0}% 피해."),
	("heavy_blow", "Heavy Blow", "attack", 150, "POW", "공격력의 {0}% 피해."),
	("brace", "Brace", "block", 80, "SHD", "실드 {0} 획득."),
]

# id, display_name, action_count, intents (in cast order)
MONSTERS = [
	("mire_imp", "Mire Imp", 3, ["stab", "brace", "heavy_blow"]),
	("bog_stalker", "Bog Stalker", 2, ["stab", "stab", "heavy_blow"]),
	("bone_crawler", "Bone Crawler", 2, ["heavy_blow", "stab", "brace"]),
	("gravebound_crawler", "Gravebound Crawler", 3, ["brace", "stab", "heavy_blow"]),
	("frost_revenant", "Frost Revenant", 2, ["brace", "heavy_blow", "stab", "heavy_blow"]),
	("crown_acolyte", "Crown Acolyte", 2, ["heavy_blow", "brace", "heavy_blow"]),
	("abyssal_crown_guardian", "Abyssal Crown Guardian", 3, ["heavy_blow", "brace", "heavy_blow", "stab"]),
]


def build_monster_intents(sheet) -> None:
	sheet.append([None])
	sheet.append(["#data", "id", "display_name", "intent_type", "power", "icon_label", "description_template"])
	sheet.append([None, "key,string", "string", "string", "int", "string", "string"])
	sheet.append([None, "data", "data", "data", "data", "data", "data"])
	for row in MONSTER_INTENTS:
		sheet.append([None, *row])
	for column, width in {"B": 18, "C": 16, "D": 12, "E": 8, "F": 12, "G": 40}.items():
		sheet.column_dimensions[column].width = width
	sheet.freeze_panes = "A5"


def build_monsters(sheet) -> None:
	sheet.append([None])
	sheet.append(["#data", "id", "display_name", "action_count", "intents[]"])
	sheet.append([None, "key,string", "string", "int", "string"])
	sheet.append([None, "data", "data", "data", "data"])
	for monster_id, name, action_count, intents in MONSTERS:
		sheet.append([None, monster_id, name, action_count, ",".join(intents)])
	for column, width in {"B": 24, "C": 26, "D": 14, "E": 44}.items():
		sheet.column_dimensions[column].width = width
	sheet.freeze_panes = "A5"


def main() -> None:
	project_root = Path(__file__).resolve().parents[2]
	output_dir = project_root / "tables" / "excel"
	output_dir.mkdir(parents=True, exist_ok=True)

	workbook = openpyxl.Workbook()
	build_monster_intents(workbook.active)
	workbook.active.title = "monster_intents"
	build_monsters(workbook.create_sheet("monsters"))

	workbook.save(output_dir / "MonsterTable.xlsx")


if __name__ == "__main__":
	main()
