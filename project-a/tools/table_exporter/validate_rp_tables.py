"""Validate generated character RP settings and RP skill tables."""

from __future__ import annotations

import json
from pathlib import Path


def load_rows(path: Path) -> list[dict]:
    rows = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(rows, list) or not rows:
        raise ValueError(f"{path.name}: expected a non-empty JSON array")
    return rows


def main() -> None:
    project_root = Path(__file__).resolve().parents[2]
    generated = project_root / "data" / "generated"
    settings_rows = load_rows(generated / "CharacterRpSettings.json")
    skill_rows = load_rows(generated / "CharacterRpSkills.json")

    settings_by_character = {str(row.get("Character", "")): row for row in settings_rows}
    seen_skill_ids: set[str] = set()

    for character, settings in settings_by_character.items():
        if not character:
            raise ValueError("CharacterRpSettings: Character is required")
        max_rp = float(settings.get("MaxRp", 0.0))
        starting_rp = float(settings.get("StartingRp", 0.0))
        if max_rp <= 0.0:
            raise ValueError(f"{character}: max_rp must be positive")
        if not 0.0 <= starting_rp <= max_rp:
            raise ValueError(f"{character}: starting_rp must be between 0 and max_rp")
        for field in ("RpPerEnemyKill", "RpPerActionPoint", "RpPerEndTurn"):
            if float(settings.get(field, -1.0)) < 0.0:
                raise ValueError(f"{character}: {field} cannot be negative")

    for skill in skill_rows:
        skill_id = str(skill.get("Id", ""))
        character = str(skill.get("Character", ""))
        if not skill_id or skill_id in seen_skill_ids:
            raise ValueError(f"CharacterRpSkills: invalid or duplicate Id {skill_id!r}")
        seen_skill_ids.add(skill_id)
        if character not in settings_by_character:
            raise ValueError(f"{skill_id}: missing RP settings for {character!r}")
        cost = float(skill.get("RpCost", 0.0))
        max_rp = float(settings_by_character[character]["MaxRp"])
        if cost <= 0.0 or cost > max_rp:
            raise ValueError(f"{skill_id}: RpCost must be positive and not exceed MaxRp")
        if float(skill.get("DamagePercent", 0.0)) <= 0.0:
            raise ValueError(f"{skill_id}: DamagePercent must be positive")
        if int(skill.get("HitCount", 0)) <= 0:
            raise ValueError(f"{skill_id}: HitCount must be positive")
        if str(skill.get("Target", "")) != "AllEnemies":
            raise ValueError(f"{skill_id}: current RP targeting flow requires AllEnemies")
        if not str(skill.get("MotionAnimation", "")):
            raise ValueError(f"{skill_id}: MotionAnimation is required")

    print(f"Validated {len(settings_rows)} RP setting row(s) and {len(skill_rows)} RP skill row(s).")


if __name__ == "__main__":
    main()
