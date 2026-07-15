from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent
PROJECT_ROOT = ROOT.parents[4]
CELL = 181
COLS = 4

ORIGINAL_SHEET = ROOT / "momoka_spritesheet_transparent_4x8_181x181.png"
BRIDGE_SOURCE = ROOT / "momoka_attack_bridges_transparent.png"
RUN_SOURCE = ROOT / "momoka_run_alternating_transparent.png"
RUNTIME_SHEET = (
    PROJECT_ROOT
    / "project-a/assets/characters/spritesheets/momoka_spritesheet.png"
)
DOC_SHEET = ROOT / "momoka_spritesheet_extended_attack_4x9_181x181.png"
PREVIEW = ROOT / "momoka_spritesheet_preview.png"
QA_DIR = ROOT / "qa"


def split_grid(image: Image.Image, cols: int, rows: int) -> list[Image.Image]:
    frames = []
    for row in range(rows):
        top = round(row * image.height / rows)
        bottom = round((row + 1) * image.height / rows)
        for col in range(cols):
            left = round(col * image.width / cols)
            right = round((col + 1) * image.width / cols)
            frames.append(image.crop((left, top, right, bottom)))
    return frames


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").point(
        lambda value: 255 if value > 8 else 0
    ).getbbox()
    if bbox is None:
        raise ValueError("Empty sprite frame")
    return bbox


def keep_largest_component(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    width, height = image.size
    opaque = bytearray(1 if value > 8 else 0 for value in alpha.tobytes())
    visited = bytearray(width * height)
    largest: list[int] = []

    for start in range(width * height):
        if not opaque[start] or visited[start]:
            continue
        component = []
        queue = deque([start])
        visited[start] = 1
        while queue:
            current = queue.popleft()
            component.append(current)
            x = current % width
            y = current // width
            for ny in range(max(0, y - 1), min(height, y + 2)):
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbor = ny * width + nx
                    if opaque[neighbor] and not visited[neighbor]:
                        visited[neighbor] = 1
                        queue.append(neighbor)
        if len(component) > len(largest):
            largest = component

    keep = bytearray(width * height)
    for index in largest:
        keep[index] = 1
    cleaned_alpha = bytearray(alpha.tobytes())
    for index, is_kept in enumerate(keep):
        if not is_kept:
            cleaned_alpha[index] = 0
    cleaned = image.copy()
    cleaned.putalpha(Image.frombytes("L", image.size, bytes(cleaned_alpha)))
    return cleaned


def place_generated(frame: Image.Image) -> Image.Image:
    frame = keep_largest_component(frame)
    cropped = frame.crop(alpha_bbox(frame))
    scale = 174 / cropped.height
    width = round(cropped.width * scale)
    height = round(cropped.height * scale)
    sprite = cropped.resize((width, height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CELL, CELL))
    canvas.alpha_composite(sprite, ((CELL - width) // 2, 3))
    return canvas


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


def build() -> None:
    QA_DIR.mkdir(exist_ok=True)
    original = split_grid(Image.open(ORIGINAL_SHEET).convert("RGBA"), 4, 8)
    bridges = [
        place_generated(frame)
        for frame in split_grid(Image.open(BRIDGE_SOURCE).convert("RGBA"), 4, 1)
    ]
    run_frames = [
        place_generated(frame)
        for frame in split_grid(Image.open(RUN_SOURCE).convert("RGBA"), 4, 2)
    ]

    idle = original[0:4]
    attack = [
        bridges[0],
        original[4],
        bridges[1],
        original[5],
        original[6],
        bridges[2],
        bridges[3],
        original[7],
    ]
    run = run_frames
    hit = original[16:24]
    dead = original[24:32]
    frames = idle + attack + run + hit + dead

    sheet = Image.new("RGBA", (COLS * CELL, 9 * CELL))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(
            frame,
            ((index % COLS) * CELL, (index // COLS) * CELL),
        )
    sheet.save(RUNTIME_SHEET)
    sheet.save(DOC_SHEET)

    preview = checkerboard(sheet.size)
    preview.paste(sheet, mask=sheet.getchannel("A"))
    preview.save(PREVIEW)

    save_gif(idle, QA_DIR / "idle.gif", 200)
    save_gif(attack, QA_DIR / "attack.gif", 75)
    save_gif(run, QA_DIR / "run.gif", 85)
    save_gif(hit, QA_DIR / "hit.gif", 200)
    save_gif(dead, QA_DIR / "dead.gif", 143)

    strip = Image.new("RGBA", (8 * CELL, 5 * CELL))
    for row, group in enumerate([idle, attack, run, hit, dead]):
        for col, frame in enumerate(group):
            strip.alpha_composite(frame, (col * CELL, row * CELL))
    strip_preview = checkerboard(strip.size)
    strip_preview.paste(strip, mask=strip.getchannel("A"))
    strip_preview.save(QA_DIR / "momoka_animation_strip_preview.png")

    bbox_preview = preview.copy()
    bbox_draw = ImageDraw.Draw(bbox_preview)
    report = [
        "sheet=momoka_spritesheet.png size=724x1629 grid=4x9 cell=181x181",
        "mapping=idle:0-3 attack:4-11 run:12-19 hit:20-27 dead:28-35",
        "attack_original_keyframes=5,7,8,11",
        "attack_generated_bridges=4,6,9,10",
        "run_generated_alternating_steps=12-19",
    ]
    edge_risk = []
    for index, frame in enumerate(frames):
        left, top, right, bottom = alpha_bbox(frame)
        margins = (left, top, CELL - right, CELL - bottom)
        if min(margins) < 3:
            edge_risk.append(index)
        report.append(
            f"{index:02d}: bbox={right-left}x{bottom-top} "
            f"margins=l{left},t{top},r{CELL-right},b{CELL-bottom}"
        )
        cell_x = (index % COLS) * CELL
        cell_y = (index // COLS) * CELL
        bbox_draw.rectangle(
            (cell_x + left, cell_y + top, cell_x + right - 1, cell_y + bottom - 1),
            outline="#ff4d67",
            width=1,
        )
    report.append(f"edge_risk_frames={edge_risk}")
    (QA_DIR / "momoka_frame_bbox_report.txt").write_text(
        "\n".join(report) + "\n", encoding="utf-8"
    )
    bbox_preview.save(QA_DIR / "momoka_bbox_preview.png")


if __name__ == "__main__":
    build()
