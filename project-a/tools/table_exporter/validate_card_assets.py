#!/usr/bin/env python3
"""Validate generated card data and matching runtime card art."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


REQUIRED_FIELDS = {
    "card_key",
    "character",
    "id",
    "display_name",
    "cost",
    "card_type",
    "text_template",
    "copies",
    "keywords",
}


def main() -> int:
    project_root = Path(__file__).resolve().parents[2]
    cards_path = project_root / "data" / "generated" / "character_cards.json"
    effect_rows_path = project_root / "data" / "generated" / "card_effect_rows.json"
    art_dir = project_root / "assets" / "card" / "cardart_full"

    errors: list[str] = []
    cards = load_cards(cards_path, errors)
    effect_rows = load_cards(effect_rows_path, errors)
    if cards is None or effect_rows is None:
        print_errors(errors)
        return 1

    card_keys = {
        card_key(str(card.get("character", "")).strip(), str(card.get("id", "")).strip())
        for card in cards
        if isinstance(card, dict)
    }
    effect_card_keys = validate_effect_rows(effect_rows, card_keys, errors)

    seen_ids: set[tuple[str, str]] = set()
    for index, card in enumerate(cards, start=1):
        validate_card_record(index, card, seen_ids, effect_card_keys, art_dir, errors)

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
    effect_card_keys: set[str],
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

    expected_card_key = card_key(character, card_id)
    exported_card_key = str(card.get("card_key", "")).strip()
    if exported_card_key != expected_card_key:
        errors.append(f"{character}/{card_id} has invalid card_key: {exported_card_key}")
    if expected_card_key not in effect_card_keys:
        errors.append(f"{character}/{card_id} has no row in card_effect_rows.")
    if "effects" in card or "inspiration" in card:
        errors.append(f"{character}/{card_id} still exports legacy JSON effect field(s).")

    art_path = art_dir / f"{character}_{card_id}.png"
    if not art_path.exists():
        errors.append(f"Missing card art for {character}/{card_id}: {art_path}")


def validate_effect_rows(effect_rows: list[Any], card_keys: set[str], errors: list[str]) -> set[str]:
    seen_ids: set[str] = set()
    effect_card_keys: set[str] = set()
    for index, row in enumerate(effect_rows, start=1):
        if not isinstance(row, dict):
            errors.append(f"Effect row #{index} must be an object.")
            continue
        row_id = str(row.get("id", "")).strip()
        row_card_key = str(row.get("card_key", "")).strip()
        character = str(row.get("character", "")).strip()
        card_id = str(row.get("card_id", "")).strip()
        trigger = str(row.get("trigger", "")).strip()
        effect_type = str(row.get("effect_type", "")).strip()
        if not row_id:
            errors.append(f"Effect row #{index} has empty id.")
        elif row_id in seen_ids:
            errors.append(f"Duplicate effect row id: {row_id}")
        seen_ids.add(row_id)
        expected_card_key = card_key(character, card_id)
        if not row_card_key:
            errors.append(f"Effect row {row_id or index} has empty card_key.")
        elif row_card_key != expected_card_key:
            errors.append(f"Effect row {row_id or index} has invalid card_key: {row_card_key}")
        if not card_id:
            errors.append(f"Effect row #{index} has empty card_id.")
        elif row_card_key not in card_keys:
            errors.append(f"Effect row {row_id} references missing card_key: {row_card_key}")
        else:
            effect_card_keys.add(row_card_key)
        if not trigger:
            errors.append(f"Effect row {row_id or index} has empty trigger.")
        if not effect_type:
            errors.append(f"Effect row {row_id or index} has empty effect_type.")
        if row.get("text_arg_index") is not None and row.get("percent") is None and row.get("amount") is None and row.get("duration_turns") is None:
            errors.append(f"Effect row {row_id or index} has text_arg_index but no numeric value.")
    return effect_card_keys


def card_key(character: str, card_id: str) -> str:
    return f"{character}/{card_id}"


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
