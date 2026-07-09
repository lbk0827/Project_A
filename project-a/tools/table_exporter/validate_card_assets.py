#!/usr/bin/env python3
"""Validate generated card data and matching runtime card art."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


REQUIRED_FIELDS = {
    "character",
    "id",
    "display_name",
    "cost",
    "card_type",
    "text",
    "copies",
    "keywords",
    "effects",
}


def main() -> int:
    project_root = Path(__file__).resolve().parents[2]
    cards_path = project_root / "data" / "generated" / "character_cards.json"
    art_dir = project_root / "assets" / "card" / "cardart_full"

    errors: list[str] = []
    cards = load_cards(cards_path, errors)
    if cards is None:
        print_errors(errors)
        return 1

    seen_ids: set[tuple[str, str]] = set()
    for index, card in enumerate(cards, start=1):
        validate_card_record(index, card, seen_ids, art_dir, errors)

    validate_no_legacy_card_art(art_dir, errors)

    if errors:
        print_errors(errors)
        return 1

    print(f"Validated {len(cards)} card record(s) and runtime card art.")
    return 0


def load_cards(cards_path: Path, errors: list[str]) -> list[Any] | None:
    if not cards_path.exists():
        errors.append(f"Missing card JSON: {cards_path}")
        return None
    try:
        cards = json.loads(cards_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        errors.append(f"Invalid JSON in {cards_path}: line {exc.lineno}, column {exc.colno}: {exc.msg}")
        return None
    if not isinstance(cards, list):
        errors.append(f"{cards_path} must contain a JSON array.")
        return None
    return cards


def validate_card_record(
    index: int,
    card: Any,
    seen_ids: set[tuple[str, str]],
    art_dir: Path,
    errors: list[str],
) -> None:
    if not isinstance(card, dict):
        errors.append(f"Card #{index} must be an object.")
        return

    missing = sorted(REQUIRED_FIELDS - set(card))
    if missing:
        errors.append(f"Card #{index} is missing field(s): {', '.join(missing)}")

    character = str(card.get("character", "")).strip()
    card_id = str(card.get("id", "")).strip()
    if not character:
        errors.append(f"Card #{index} has empty character.")
    if not card_id:
        errors.append(f"Card #{index} has empty id.")
    if not character or not card_id:
        return

    key = (character, card_id)
    if key in seen_ids:
        errors.append(f"Duplicate card key: {character}/{card_id}")
    seen_ids.add(key)

    art_path = art_dir / f"{character}_{card_id}.png"
    if not art_path.exists():
        errors.append(f"Missing card art for {character}/{card_id}: {art_path}")


def validate_no_legacy_card_art(art_dir: Path, errors: list[str]) -> None:
    if not art_dir.exists():
        errors.append(f"Missing card art directory: {art_dir}")
        return
    for path in sorted(art_dir.glob("*.png")):
        if "_" not in path.stem:
            errors.append(f"Runtime card art must include character prefix: {path}")


def print_errors(errors: list[str]) -> None:
    print("Card asset validation failed:", file=sys.stderr)
    for error in errors:
        print(f"  - {error}", file=sys.stderr)


if __name__ == "__main__":
    raise SystemExit(main())
