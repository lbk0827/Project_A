#!/usr/bin/env python3
"""Create MonsterTable.xlsx: monster intent templates + the monster roster.

- MonsterIntents: reusable intent templates. For "Attack" intents, power is a
  percent of the monster's Attack; for "Block", power is a flat shield.
  Enemy damage = Attack * Power / 100, mirroring the player's card model,
  so a monster is tuned mainly by its Attack in the stats table.
- monsters: the roster's behaviour (action count + intent sequence). Combat
  numbers (hp/Attack) live in the MonsterStats sheet.
"""

from __future__ import annotations

from pathlib import Path

import openpyxl

# Id, DisplayName, IntentType, Power, IconLabel, DescriptionTemplate
MONSTER_INTENTS = [
	("Stab", "찌르기", "Attack", 100, "ATK", "공격력의 {0}% 피해."),
	("HeavyBlow", "강타", "Attack", 150, "POW", "공격력의 {0}% 피해."),
	("Brace", "방어", "Block", 80, "SHD", "실드 {0} 획득."),
]

# id, DisplayName, ActionCount, intents (in cast order)
MONSTERS = [
	("MireImp", "마이어 임프", 3, ["Stab", "Brace", "HeavyBlow"]),
	("BogStalker", "늪 추적자", 2, ["Stab", "Stab", "HeavyBlow"]),
	("BoneCrawler", "뼈 크롤러", 2, ["HeavyBlow", "Stab", "Brace"]),
	("GraveboundCrawler", "무덤 크롤러", 3, ["Brace", "Stab", "HeavyBlow"]),
	("FrostRevenant", "프로스트 레버넌트", 2, ["Brace", "HeavyBlow", "Stab", "HeavyBlow"]),
	("CrownAcolyte", "왕관 시종", 2, ["HeavyBlow", "Brace", "HeavyBlow"]),
	("AbyssalCrownGuardian", "심연 왕관 수호자", 3, ["HeavyBlow", "Brace", "HeavyBlow", "Stab"]),
]


def build_MonsterIntents(sheet) -> None:
	sheet.append([None])
	sheet.append(["#data", "Id", "DisplayName", "IntentType", "Power", "IconLabel", "DescriptionTemplate"])
	sheet.append([None, "key,string", "string", "string", "int", "string", "string"])
	sheet.append([None, "data", "data", "data", "data", "data", "data"])
	for row in MONSTER_INTENTS:
		sheet.append([None, *row])
	for column, width in {"B": 18, "C": 16, "D": 12, "E": 8, "F": 12, "G": 40}.items():
		sheet.column_dimensions[column].width = width
	sheet.freeze_panes = "A5"


def build_monsters(sheet) -> None:
	sheet.append([None])
	sheet.append(["#data", "Id", "DisplayName", "ActionCount", "Intents[]"])
	sheet.append([None, "key,string", "string", "int", "string"])
	sheet.append([None, "data", "data", "data", "data"])
	for monster_id, name, ActionCount, intents in MONSTERS:
		sheet.append([None, monster_id, name, ActionCount, ",".join(intents)])
	for column, width in {"B": 24, "C": 26, "D": 14, "E": 44}.items():
		sheet.column_dimensions[column].width = width
	sheet.freeze_panes = "A5"


def main() -> None:
	project_root = Path(__file__).resolve().parents[2]
	output_dir = project_root / "tables" / "excel"
	output_dir.mkdir(parents=True, exist_ok=True)

	workbook = openpyxl.Workbook()
	build_MonsterIntents(workbook.active)
	workbook.active.title = "MonsterIntents"
	build_monsters(workbook.create_sheet("Monsters"))

	workbook.save(output_dir / "MonsterTable.xlsx")


if __name__ == "__main__":
	main()
