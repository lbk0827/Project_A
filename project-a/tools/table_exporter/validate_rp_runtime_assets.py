"""Static validation for RP runtime JSON, scenes, scripts, and image assets."""

from __future__ import annotations

import json
import re
from pathlib import Path

from PIL import Image


RES_PATH = re.compile(r'res://[^"\']+')


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    checked_files = [
        root / "scripts" / "core" / "ingame.gd",
        root / "scripts" / "ui" / "battle_ui.gd",
        root / "scripts" / "ui" / "card_preview_large.gd",
        root / "scripts" / "player" / "heroine_controller.gd",
        root / "scripts" / "vfx" / "MoonSlashVfx.gd",
        root / "scenes" / "vfx" / "FxTsukiMoonSlash.tscn",
    ]
    missing: list[str] = []
    for source in checked_files:
        text = source.read_text(encoding="utf-8")
        for resource_path in RES_PATH.findall(text):
            if "%" in resource_path:
                continue
            target = root / resource_path.removeprefix("res://")
            if not target.exists():
                missing.append(f"{source.relative_to(root)} -> {resource_path}")
    if missing:
        raise FileNotFoundError("Missing RP runtime resources:\n" + "\n".join(missing))

    skill = json.loads((root / "data/generated/CharacterRpSkills.json").read_text(encoding="utf-8"))[0]
    heroine_scene = (root / "scenes/player/heroine.tscn").read_text(encoding="utf-8")
    animation = str(skill["MotionAnimation"])
    if f'"name": &"{animation}"' not in heroine_scene:
        raise ValueError(f"Heroine scene does not define animation {animation!r}")

    card_art_path = root / "assets/card/cardart_full" / f'{skill["Character"]}{skill["Id"]}.png'
    with Image.open(card_art_path) as card_art:
        if card_art.height <= card_art.width:
            raise ValueError(f"{card_art_path.name}: expected portrait card art")

    image_path = root / "assets/vfx/MoonSlashMoon.png"
    with Image.open(image_path) as image:
        if image.mode != "RGBA":
            raise ValueError(f"{image_path.name}: expected RGBA, got {image.mode}")
        alpha = image.getchannel("A")
        if any(alpha.getpixel(point) != 0 for point in ((0, 0), (image.width - 1, 0), (0, image.height - 1), (image.width - 1, image.height - 1))):
            raise ValueError(f"{image_path.name}: corners must be transparent")
        if alpha.getbbox() is None:
            raise ValueError(f"{image_path.name}: alpha channel has no visible content")

    sprite_sheet_path = root / "assets/vfx/MoonSlashSheet.png"
    with Image.open(sprite_sheet_path) as sprite_sheet:
        if sprite_sheet.width != sprite_sheet.height:
            raise ValueError(f"{sprite_sheet_path.name}: expected a square sprite sheet")
        if sprite_sheet.width % 4 != 0 or sprite_sheet.height % 4 != 0:
            raise ValueError(f"{sprite_sheet_path.name}: dimensions must be divisible by 4")
        if sprite_sheet.width // 4 < 256:
            raise ValueError(f"{sprite_sheet_path.name}: frame resolution is too small")

    print(f"Validated {len(checked_files)} RP runtime files, card art, and MoonSlash VFX textures.")


if __name__ == "__main__":
    main()
