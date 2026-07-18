from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parent
PROJECT_ROOT = ROOT.parents[4]
CELL = 181
COLS = 4

ORIGINAL_SHEET = ROOT / "miu_spritesheet_transparent_4x7_181x181.png"
RUNTIME_SHEET = PROJECT_ROOT / "project-a/assets/characters/spritesheets/miu_spritesheet.png"
DOC_SHEET = ROOT / "miu_spritesheet_reworked_4x9_181x181.png"
PREVIEW = ROOT / "miu_spritesheet_preview.png"
SCENE = PROJECT_ROOT / "project-a/scenes/characters/miu.tscn"
QA_DIR = ROOT / "qa"


def split_grid(image: Image.Image, cols: int, rows: int) -> list[Image.Image]:
    frames = []
    for row in range(rows):
        for col in range(cols):
            frames.append(
                image.crop((col * CELL, row * CELL, (col + 1) * CELL, (row + 1) * CELL))
            )
    return frames


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()


def shift(frame: Image.Image, dx: int = 0, dy: int = 0) -> Image.Image:
    return ImageChops.offset(frame, dx, dy)


def scale_from_bottom(frame: Image.Image, sx: float = 1.0, sy: float = 1.0, dy: int = 0) -> Image.Image:
    bbox = alpha_bbox(frame)
    if bbox is None:
        return Image.new("RGBA", (CELL, CELL))
    cropped = frame.crop(bbox)
    width = max(1, round(cropped.width * sx))
    height = max(1, round(cropped.height * sy))
    sprite = cropped.resize((width, height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CELL, CELL))
    bottom = bbox[3]
    x = (CELL - width) // 2
    y = bottom - height + dy
    canvas.alpha_composite(sprite, (x, y))
    return canvas


def rotate_keep(frame: Image.Image, angle: float, dx: int = 0, dy: int = 0) -> Image.Image:
    rotated = frame.rotate(angle, resample=Image.Resampling.BICUBIC, center=(CELL // 2, CELL - 24))
    return shift(rotated, dx, dy)


def checkerboard(size: tuple[int, int], block: int = 12) -> Image.Image:
    image = Image.new("RGB", size, "#20242b")
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], block):
        for x in range(0, size[0], block):
            color = "#2d333d" if (x // block + y // block) % 2 else "#242a32"
            draw.rectangle((x, y, x + block - 1, y + block - 1), fill=color)
    return image


def save_gif(frames: list[Image.Image], path: Path, duration: int) -> None:
    rendered = []
    for frame in frames:
        background = checkerboard((CELL, CELL))
        background.paste(frame, mask=frame.getchannel("A"))
        rendered.append(background)
    rendered[0].save(
        path,
        save_all=True,
        append_images=rendered[1:],
        duration=duration,
        loop=0,
        disposal=2,
    )


def make_scene() -> str:
    lines = [
        "[gd_scene load_steps=39 format=3]",
        "",
        '[ext_resource type="Texture2D" path="res://assets/characters/spritesheets/miu_spritesheet.png" id="1_sheet"]',
        '[ext_resource type="Script" uid="uid://qdct5rji41m1" path="res://scripts/player/heroine_controller.gd" id="2_controller"]',
        "",
    ]
    for index in range(36):
        x = (index % COLS) * CELL
        y = (index // COLS) * CELL
        lines.extend(
            [
                f'[sub_resource type="AtlasTexture" id="AtlasTexture_miu_{index:02d}"]',
                'atlas = ExtResource("1_sheet")',
                f"region = Rect2({x}, {y}, {CELL}, {CELL})",
                "",
            ]
        )

    animations = {
        "Attack": (list(range(6, 18)), False, 12.0),
        "Dead": (list(range(32, 36)), False, 7.0),
        "Hit": (list(range(26, 32)), False, 8.0),
        "Idle": (list(range(0, 6)), True, 5.0),
        "Run": (list(range(18, 26)), True, 12.0),
    }
    lines.append('[sub_resource type="SpriteFrames" id="SpriteFrames_miu"]')
    lines.append("animations = [")
    for anim_index, (name, (indices, loop, speed)) in enumerate(animations.items()):
        lines.append("{")
        lines.append('"frames": [')
        for frame_index, index in enumerate(indices):
            lines.append("{")
            lines.append('"duration": 1.0,')
            lines.append(f'"texture": SubResource("AtlasTexture_miu_{index:02d}")')
            lines.append("}" + ("," if frame_index < len(indices) - 1 else ""))
        lines.append("],")
        lines.append(f'"loop": {str(loop).lower()},')
        lines.append(f'"name": &"{name}",')
        lines.append(f'"speed": {speed}')
        lines.append("}" + ("," if anim_index < len(animations) - 1 else ""))
    lines.extend(
        [
            "]",
            "",
            '[node name="Miu" type="CharacterBody2D"]',
            'script = ExtResource("2_controller")',
            "move_to_attack_position = false",
            "attack_impact_delay = 0.28",
            "attack_recover_delay = 0.42",
            "attack_fx_enabled = false",
            "",
            '[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]',
            'sprite_frames = SubResource("SpriteFrames_miu")',
            'animation = &"Idle"',
            'autoplay = "Idle"',
            "",
        ]
    )
    return "\n".join(lines)


def build() -> None:
    QA_DIR.mkdir(exist_ok=True)
    original = split_grid(Image.open(ORIGINAL_SHEET).convert("RGBA"), 4, 7)

    idle_base = original[0]
    idle = [
        scale_from_bottom(idle_base, 1.0, 1.0, 0),
        scale_from_bottom(idle_base, 0.998, 0.998, 0),
        scale_from_bottom(idle_base, 0.996, 0.996, 0),
        scale_from_bottom(idle_base, 0.998, 0.998, 0),
        scale_from_bottom(idle_base, 1.0, 1.0, 0),
        scale_from_bottom(idle_base, 0.998, 0.998, 1),
    ]

    attack = [
        original[4],
        shift(original[4], -1, 0),
        original[5],
        original[6],
        shift(original[9], -1, 0),
        original[9],
        original[10],
        shift(original[10], -3, 0),
        shift(original[9], -2, 0),
        original[6],
        original[5],
        original[4],
    ]

    run = original[12:20]
    hit_base = scale_from_bottom(idle_base, 0.94, 0.94, 0)
    hit = [
        hit_base,
        shift(hit_base, -2, 0),
        shift(hit_base, -5, 0),
        shift(hit_base, -3, 1),
        shift(hit_base, -1, 0),
        hit_base,
    ]
    dead = original[24:28]
    frames = idle + attack + run + hit + dead

    sheet = Image.new("RGBA", (COLS * CELL, 9 * CELL))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, ((index % COLS) * CELL, (index // COLS) * CELL))
    sheet.save(RUNTIME_SHEET)
    sheet.save(DOC_SHEET)

    preview = checkerboard(sheet.size)
    preview.paste(sheet, mask=sheet.getchannel("A"))
    preview.save(PREVIEW)

    save_gif(idle, QA_DIR / "idle.gif", 180)
    save_gif(attack, QA_DIR / "attack.gif", 85)
    save_gif(run, QA_DIR / "run.gif", 83)
    save_gif(hit, QA_DIR / "hit.gif", 100)
    save_gif(dead, QA_DIR / "dead.gif", 143)

    strip = Image.new("RGBA", (12 * CELL, 5 * CELL))
    for row, group in enumerate([idle, attack, run, hit, dead]):
        for col, frame in enumerate(group):
            strip.alpha_composite(frame, (col * CELL, row * CELL))
    strip_preview = checkerboard(strip.size)
    strip_preview.paste(strip, mask=strip.getchannel("A"))
    strip_preview.save(QA_DIR / "miu_animation_strip_preview.png")

    bbox_preview = preview.copy()
    draw = ImageDraw.Draw(bbox_preview)
    report = [
        "sheet=miu_spritesheet.png size=724x1629 grid=4x9 cell=181x181",
        "mapping=idle:0-5 attack:6-17 run:18-25 hit:26-31 dead:32-35",
        "idle=reworked stationary breathing",
        "attack=reworked 12-frame stationary handgun sequence",
        "hit=reworked standing in-place hit",
    ]
    edge_risk = []
    for index, frame in enumerate(frames):
        bbox = alpha_bbox(frame)
        if bbox is None:
            edge_risk.append(index)
            report.append(f"{index:02d}: empty")
            continue
        left, top, right, bottom = bbox
        margins = (left, top, CELL - right, CELL - bottom)
        if min(margins) < 3:
            edge_risk.append(index)
        report.append(
            f"{index:02d}: bbox={right-left}x{bottom-top} "
            f"margins=l{left},t{top},r{CELL-right},b{CELL-bottom}"
        )
        cell_x = (index % COLS) * CELL
        cell_y = (index // COLS) * CELL
        draw.rectangle(
            (cell_x + left, cell_y + top, cell_x + right - 1, cell_y + bottom - 1),
            outline="#ff4d67",
            width=1,
        )
    report.append(f"edge_risk_frames={edge_risk}")
    (QA_DIR / "miu_frame_bbox_report.txt").write_text(
        "\n".join(report) + "\n", encoding="utf-8"
    )
    bbox_preview.save(QA_DIR / "miu_bbox_preview.png")

    SCENE.write_text(make_scene(), encoding="utf-8")


if __name__ == "__main__":
    build()
