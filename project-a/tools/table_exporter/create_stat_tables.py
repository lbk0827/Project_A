#!/usr/bin/env python3
"""Create the combatant stat table workbook (player growth + monster stats).

Follows the same #data layout the exporter expects. The player growth sheet is
a reference progression table (Level -> stats) for a future Character screen;
combat reads the current tier. Monster stats mirror the same schema so both
sides share crit fields. Crit values are stored as fractions/multipliers
(CritRate 0.03 = 3%, CritDamage 1.25 = +25%).
"""

from __future__ import annotations

from pathlib import Path

import openpyxl


# Level, Attack, Defense, MaxHp
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

# id, DisplayName, MaxHp, Attack, Defense, CritRate, CritDamage
# Monsters currently deal damage through intents (flat amounts), so Attack
# is 0 and crit is disabled (0.0 / 1.0) until a design pass sets enemy crit.
MONSTER_STATS = [
	("AbyssalCrownGuardian", "심연 왕관 수호자", 2500, 30, 48, 0.0, 1.0),
	("BogStalker", "늪 추적자", 650, 16, 14, 0.0, 1.0),
	("MireImp", "마이어 임프", 500, 14, 18, 0.0, 1.0),
	("BoneCrawler", "뼈 크롤러", 800, 18, 20, 0.0, 1.0),
	("CrownAcolyte", "왕관 시종", 1400, 28, 32, 0.0, 1.0),
	("FrostRevenant", "프로스트 레버넌트", 1200, 24, 40, 0.0, 1.0),
	("GraveboundCrawler", "무덤 크롤러", 950, 20, 36, 0.0, 1.0),
	("MonsterDummy", "훈련 고블린", 44, 0, 0, 0.0, 1.0),
]


def build_PlayerGrowth(sheet) -> None:
	sheet.append([None])
	sheet.append(["#archive", "Character", "Level", "Attack", "Defense", "MaxHp", "CritRate", "CritDamage"])
	sheet.append([None, "string", "key,int", "int", "int", "int", "float", "float"])
	sheet.append([None, "data", "data", "data", "data", "data", "data", "data"])
	for Level, atk, defense, hp in PLAYER_GROWTH:
		sheet.append([None, "Tsuki", Level, atk, defense, hp, PLAYER_CRIT_RATE, PLAYER_CRIT_DAMAGE])
	_apply_widths(sheet, {"B": 10, "C": 8, "D": 14, "E": 14, "F": 10, "G": 12, "H": 12})


def build_MonsterStats(sheet) -> None:
	sheet.append([None])
	sheet.append(["#data", "Id", "DisplayName", "MaxHp", "Attack", "Defense", "CritRate", "CritDamage"])
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
	build_PlayerGrowth(workbook.active)
	workbook.active.title = "PlayerGrowth"
	build_MonsterStats(workbook.create_sheet("MonsterStats"))

	workbook.save(output_dir / "StatTable.xlsx")


if __name__ == "__main__":
	main()
