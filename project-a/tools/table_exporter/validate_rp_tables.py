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
    settings_rows = load_rows(generated / "character_rp_settings.json")
    skill_rows = load_rows(generated / "character_rp_skills.json")

    settings_by_character = {str(row.get("character", "")): row for row in settings_rows}
    seen_skill_ids: set[str] = set()

    for character, settings in settings_by_character.items():
        if not character:
            raise ValueError("character_rp_settings: character is required")
        max_rp = float(settings.get("max_rp", 0.0))
        starting_rp = float(settings.get("starting_rp", 0.0))
        if max_rp <= 0.0:
            raise ValueError(f"{character}: max_rp must be positive")
        if not 0.0 <= starting_rp <= max_rp:
            raise ValueError(f"{character}: starting_rp must be between 0 and max_rp")
        for field in ("rp_per_enemy_kill", "rp_per_action_point", "rp_per_end_turn"):
            if float(settings.get(field, -1.0)) < 0.0:
                raise ValueError(f"{character}: {field} cannot be negative")

    for skill in skill_rows:
        skill_id = str(skill.get("id", ""))
        character = str(skill.get("character", ""))
        if not skill_id or skill_id in seen_skill_ids:
            raise ValueError(f"character_rp_skills: invalid or duplicate id {skill_id!r}")
        seen_skill_ids.add(skill_id)
        if character not in settings_by_character:
            raise ValueError(f"{skill_id}: missing RP settings for {character!r}")
        cost = float(skill.get("rp_cost", 0.0))
        max_rp = float(settings_by_character[character]["max_rp"])
        if cost <= 0.0 or cost > max_rp:
            raise ValueError(f"{skill_id}: rp_cost must be positive and not exceed max_rp")
        if float(skill.get("damage_percent", 0.0)) <= 0.0:
            raise ValueError(f"{skill_id}: damage_percent must be positive")
        if int(skill.get("hit_count", 0)) <= 0:
            raise ValueError(f"{skill_id}: hit_count must be positive")
        if str(skill.get("target", "")) != "all_enemies":
            raise ValueError(f"{skill_id}: current RP targeting flow requires all_enemies")
        if not str(skill.get("motion_animation", "")):
            raise ValueError(f"{skill_id}: motion_animation is required")

    print(f"Validated {len(settings_rows)} RP setting row(s) and {len(skill_rows)} RP skill row(s).")


if __name__ == "__main__":
    main()
