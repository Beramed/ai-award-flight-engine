#!/usr/bin/env python3
"""Pixel-art farm props for the playable continuous world (not a flattened panorama)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets" / "tiles"


def new(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(img: Image.Image, x: int, y: int, color: tuple[int, ...], w: int = 1, h: int = 1) -> None:
    draw = ImageDraw.Draw(img)
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=color)


def save(img: Image.Image, name: str) -> None:
    path = OUT / name
    img.save(path)
    print(path, img.size)


def barrel() -> None:
    img = new(16, 22)
    put(img, 2, 1, (96, 58, 28, 255), 12, 20)
    put(img, 3, 2, (138, 86, 42, 255), 10, 18)
    put(img, 4, 3, (168, 110, 55, 255), 8, 4)
    put(img, 2, 6, (62, 40, 22, 255), 12, 2)
    put(img, 2, 14, (62, 40, 22, 255), 12, 2)
    put(img, 5, 8, (190, 130, 70, 255), 2, 5)
    put(img, 3, 19, (72, 44, 22, 255), 10, 2)
    save(img, "barrel.png")


def hay() -> None:
    img = new(28, 18)
    put(img, 1, 4, (176, 142, 48, 255), 26, 13)
    put(img, 2, 2, (210, 176, 70, 255), 24, 6)
    put(img, 3, 1, (230, 198, 88, 255), 22, 3)
    put(img, 4, 8, (150, 118, 36, 255), 20, 2)
    put(img, 2, 14, (128, 96, 28, 255), 24, 3)
    put(img, 8, 5, (240, 214, 110, 255), 3, 2)
    save(img, "hay.png")


def house() -> None:
    img = new(56, 48)
    put(img, 4, 18, (168, 122, 78, 255), 48, 30)
    put(img, 5, 20, (196, 148, 96, 255), 46, 10)
    put(img, 2, 10, (92, 42, 32, 255), 52, 10)
    put(img, 10, 2, (118, 48, 36, 255), 36, 12)
    put(img, 26, 0, (78, 32, 24, 255), 4, 10)
    put(img, 24, 28, (72, 46, 28, 255), 10, 20)
    put(img, 10, 26, (70, 120, 150, 255), 10, 8)
    put(img, 38, 26, (70, 120, 150, 255), 10, 8)
    put(img, 11, 27, (180, 210, 220, 255), 4, 3)
    put(img, 4, 46, (60, 40, 22, 255), 48, 2)
    save(img, "house.png")


def barn_big() -> None:
    img = new(72, 56)
    put(img, 6, 16, (168, 48, 42, 255), 60, 40)
    put(img, 8, 18, (196, 62, 52, 255), 56, 12)
    put(img, 2, 8, (92, 34, 30, 255), 68, 12)
    put(img, 18, 0, (118, 40, 34, 255), 36, 14)
    put(img, 28, 28, (70, 42, 28, 255), 16, 28)
    put(img, 12, 30, (50, 28, 18, 255), 10, 10)
    put(img, 50, 30, (50, 28, 18, 255), 10, 10)
    put(img, 32, 32, (210, 170, 70, 255), 8, 8)
    put(img, 6, 54, (48, 32, 20, 255), 60, 2)
    save(img, "barn_big.png")


def tree() -> None:
    img = new(32, 48)
    put(img, 14, 28, (92, 58, 32, 255), 5, 20)
    put(img, 13, 36, (72, 46, 26, 255), 7, 12)
    put(img, 6, 8, (36, 92, 42, 255), 20, 18)
    put(img, 4, 14, (28, 78, 36, 255), 24, 14)
    put(img, 8, 4, (48, 118, 52, 255), 16, 12)
    put(img, 10, 6, (70, 140, 64, 255), 6, 5)
    save(img, "tree.png")


def rock() -> None:
    img = new(24, 16)
    put(img, 2, 6, (92, 92, 96, 255), 20, 10)
    put(img, 4, 3, (120, 120, 124, 255), 16, 8)
    put(img, 7, 2, (150, 150, 154, 255), 8, 4)
    put(img, 3, 12, (70, 70, 74, 255), 18, 3)
    save(img, "rock_block.png")


def water() -> None:
    img = new(32, 32)
    put(img, 0, 6, (28, 62, 96, 255), 32, 26)
    put(img, 0, 10, (22, 50, 82, 255), 32, 22)
    put(img, 0, 4, (48, 110, 150, 255), 32, 4)
    put(img, 2, 3, (90, 170, 190, 255), 8, 2)
    put(img, 16, 5, (70, 140, 170, 255), 10, 2)
    save(img, "water.png")


def bridge() -> None:
    img = new(32, 12)
    put(img, 0, 2, (118, 78, 42, 255), 32, 8)
    put(img, 0, 3, (158, 110, 62, 255), 32, 4)
    for x in range(0, 32, 8):
        put(img, x, 1, (92, 58, 30, 255), 2, 10)
    put(img, 0, 9, (72, 46, 24, 255), 32, 2)
    save(img, "bridge.png")


def gate() -> None:
    img = new(36, 40)
    put(img, 2, 2, (90, 62, 34, 255), 6, 36)
    put(img, 28, 2, (90, 62, 34, 255), 6, 36)
    put(img, 2, 8, (138, 96, 52, 255), 32, 4)
    put(img, 2, 20, (138, 96, 52, 255), 32, 4)
    put(img, 8, 12, (110, 78, 42, 255), 20, 8)
    put(img, 4, 0, (70, 48, 26, 255), 4, 6)
    put(img, 28, 0, (70, 48, 26, 255), 4, 6)
    save(img, "gate.png")


def hills() -> None:
    img = new(960, 90)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 40, 959, 89], fill=(42, 58, 36, 255))
    for cx, cy, r, col in (
        (80, 50, 70, (36, 52, 32, 255)),
        (220, 44, 90, (48, 68, 40, 255)),
        (400, 52, 80, (34, 50, 30, 255)),
        (560, 40, 100, (46, 64, 38, 255)),
        (740, 48, 86, (32, 48, 28, 255)),
        (900, 54, 70, (44, 62, 36, 255)),
    ):
        draw.ellipse([cx - r, cy - r // 2, cx + r, cy + r], fill=col)
    save(img, "hills.png")


def grass_fg() -> None:
    img = new(32, 18)
    for x, h in ((2, 12), (6, 16), (10, 11), (15, 17), (20, 13), (25, 16), (29, 10)):
        put(img, x, 18 - h, (46, 110, 48, 255), 2, h)
        put(img, x, 18 - h, (90, 160, 70, 255), 1, 3)
    save(img, "grass_fg.png")


def dirt_road() -> None:
    img = new(32, 16)
    put(img, 0, 0, (110, 82, 48, 255), 32, 16)
    put(img, 0, 2, (128, 96, 56, 255), 32, 6)
    put(img, 4, 8, (92, 68, 40, 255), 6, 2)
    put(img, 18, 10, (148, 112, 68, 255), 8, 2)
    save(img, "dirt_road.png")


def shed() -> None:
    img = new(40, 36)
    put(img, 4, 12, (120, 96, 70, 255), 32, 24)
    put(img, 2, 6, (78, 62, 44, 255), 36, 10)
    put(img, 16, 18, (48, 36, 24, 255), 10, 18)
    put(img, 6, 16, (40, 32, 22, 255), 8, 8)
    put(img, 4, 34, (50, 38, 24, 255), 32, 2)
    save(img, "shed.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    barrel()
    hay()
    house()
    barn_big()
    tree()
    rock()
    water()
    bridge()
    gate()
    hills()
    grass_fg()
    dirt_road()
    shed()
