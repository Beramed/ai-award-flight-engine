#!/usr/bin/env python3
"""HUD portraits: hit face, rage side-profile with a red headband."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / "assets" / "ui"
SRC = Path("/home/ubuntu/.cursor/projects/workspace/assets")


def add_headband(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    pix = im.load()
    # Hair/forehead band across the upper head, skipping the metal frame.
    y0, y1 = int(h * 0.22), int(h * 0.31)
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0 - 1)
        if t < 0.18:
            color = (220, 46, 42, 255)
        elif t > 0.78:
            color = (118, 14, 18, 255)
        else:
            color = (188, 24, 28, 255)
        for x in range(int(w * 0.18), int(w * 0.72)):
            r, g, b, a = pix[x, y]
            if a < 180:
                continue
            # Dark hair / scalp only — skip skin and the frame.
            if r > 140 and g > 90:
                continue
            if abs(r - g) < 18 and r > 90:
                continue
            if max(r, g, b) < 110 and b >= r - 8:
                pix[x, y] = color
    # Small knot on the back of the head.
    draw = ImageDraw.Draw(im)
    kx, ky = int(w * 0.22), int(h * 0.255)
    draw.rectangle((kx - 3, ky - 2, kx + 2, ky + 4), fill=(168, 18, 22, 255))
    return im


def main() -> None:
    UI.mkdir(parents=True, exist_ok=True)
    hurt = Image.open(SRC / "06d14f0a-1d9c-4b42-9ad6-700a7c21e783.png").convert("RGBA")
    side = Image.open(SRC / "289c67ab-757f-4d6f-adff-95ad234ffee8.png").convert("RGBA")
    hurt.save(UI / "portrait_kiko_hurt.png")
    add_headband(side).save(UI / "portrait_kiko_rage.png")
    print("  ui portrait_kiko_hurt", hurt.size)
    print("  ui portrait_kiko_rage", side.size)


if __name__ == "__main__":
    main()
