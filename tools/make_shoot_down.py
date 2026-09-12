#!/usr/bin/env python3
"""Create shoot_down frames from shoot_up (vertical rifle flip) + crouched legs.

Feet stay on the original canvas row. Nearest-neighbor only. No stretch.
"""
from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
KIKO = ROOT / "assets" / "frames" / "kiko"
FRAME_W, FRAME_H = 96, 84


def bbox(im: Image.Image) -> tuple[int, int, int, int]:
    box = im.split()[-1].getbbox()
    return box if box else (0, 0, im.width, im.height)


def extract_up_barrel(up: Image.Image) -> Image.Image:
    """Take the upward rifle muzzle from shoot_up and flip it to point down."""
    pix = up.load()
    w, h = up.size
    seeds: list[tuple[int, int]] = []
    for y in range(21, 25):
        for x in range(44, 54):
            if pix[x, y][3] > 80:
                seeds.append((x, y))
    visited: set[tuple[int, int]] = set()
    q = deque(seeds)
    gun: set[tuple[int, int]] = set()
    while q:
        x, y = q.popleft()
        if (x, y) in visited:
            continue
        visited.add((x, y))
        _r, _g, _b, a = pix[x, y]
        if a < 80 or x < 42 or x > 55 or y > 44:
            continue
        gun.add((x, y))
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1), (x + 1, y + 1), (x - 1, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                q.append((nx, ny))
    mask = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mp = mask.load()
    for x, y in gun:
        mp[x, y] = pix[x, y]
    box = mask.split()[-1].getbbox()
    barrel = mask.crop(box) if box else mask
    return barrel.transpose(Image.FLIP_TOP_BOTTOM)


def erase_horizontal_rifle(crouch: Image.Image) -> Image.Image:
    out = crouch.copy()
    pix = out.load()
    for y in range(28, 76):
        for x in range(55, FRAME_W):
            pix[x, y] = (0, 0, 0, 0)
    return out


def plant(im: Image.Image, foot_y: int = 83) -> Image.Image:
    """Keep canvas size; shift so the lowest opaque row sits on foot_y. No resize."""
    box = bbox(im)
    out = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    sprite = im.crop((0, 0, FRAME_W, FRAME_H))
    dy = foot_y - box[3]
    out.paste(sprite, (0, dy), sprite)
    return out


def compose(crouch: Image.Image, barrel: Image.Image, gx: int, gy: int) -> Image.Image:
    body = erase_horizontal_rifle(crouch)
    body.alpha_composite(barrel, (gx, gy))
    # Extend the barrel downward so it reads as a 90-degree shot.
    body.alpha_composite(barrel, (gx, gy + barrel.height - 7))
    return plant(body)


def recoil(im: Image.Image, dy: int) -> Image.Image:
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    _l, _t, _r, b = bbox(im)
    feet = im.crop((0, b - 10, FRAME_W, FRAME_H))
    body = im.crop((0, 0, FRAME_W, b - 8))
    out.paste(body, (0, dy), body)
    out.paste(feet, (0, b - 10), feet)
    return plant(out)


def main() -> None:
    ups = [Image.open(KIKO / f"shoot_up_{i:02d}.png").convert("RGBA") for i in range(3)]
    crouch0 = Image.open(KIKO / "crouch_00.png").convert("RGBA")
    crouch1 = Image.open(KIKO / "crouch_01.png").convert("RGBA")
    barrels = [extract_up_barrel(up) for up in ups]

    start = plant(crouch0)
    aim = compose(crouch0, barrels[0], 40, 46)
    fire = compose(crouch0, barrels[1], 40, 47)
    rec = recoil(compose(crouch0, barrels[2], 40, 45), -1)
    recovery = plant(crouch1)

    sequence = [start, aim, fire, rec, recovery]
    for i, frame in enumerate(sequence):
        dest = KIKO / f"shoot_down_{i:02d}.png"
        frame.save(dest)
        print(f"  {dest.name} bbox={bbox(frame)}")

    extras = {
        "shoot_down_crouch_start_00": start,
        "shoot_down_aim_00": aim,
        "shoot_down_fire_00": fire,
        "shoot_down_recoil_00": rec,
        "shoot_down_recovery_00": recovery,
    }
    for name, frame in extras.items():
        frame.save(KIKO / f"{name}.png")

    names = ["shoot_up_00"] + [f"shoot_down_{i:02d}" for i in range(5)]
    sheet = Image.new("RGBA", (FRAME_W * len(names) + 8, FRAME_H + 8), (24, 32, 48, 255))
    x = 4
    for name in names:
        im = Image.open(KIKO / f"{name}.png").convert("RGBA")
        sheet.paste(im, (x, 4), im)
        x += FRAME_W
    preview = Path("/tmp/shoot_down_preview.png")
    sheet.save(preview)
    print(f"preview {preview}")


if __name__ == "__main__":
    main()
