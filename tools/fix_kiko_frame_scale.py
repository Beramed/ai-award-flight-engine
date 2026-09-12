#!/usr/bin/env python3
"""Keep crouch/down-aim frames the same on-screen size as idle/walk. Strip fringe."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets" / "frames" / "kiko"
CANVAS = (96, 84)
FEET_Y = 82
IDLE_TOP = 19


def bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
    px = im.load()
    w, h = im.size
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] < 24:
                continue
            minx = min(minx, x)
            miny = min(miny, y)
            maxx = max(maxx, x)
            maxy = max(maxy, y)
    if maxx < 0:
        return None
    return minx, miny, maxx, maxy


def harden_alpha(im: Image.Image) -> Image.Image:
    px = im.load()
    w, h = im.size
    out = im.copy()
    opx = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 96:
                opx[x, y] = (0, 0, 0, 0)
                continue
            # Drop bright cyan/turquoise fringe leftover from generated frames.
            if b >= 150 and g >= 130 and r < 120 and a < 220:
                opx[x, y] = (0, 0, 0, 0)
                continue
            opx[x, y] = (r, g, b, 255)
    return out


def fit_to_idle(src: Image.Image) -> Image.Image:
    im = harden_alpha(src.convert("RGBA"))
    box = bbox(im)
    if box is None:
        canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        return canvas
    x0, y0, x1, y1 = box
    crop = im.crop((x0, y0, x1 + 1, y1 + 1))
    target_h = FEET_Y - IDLE_TOP
    if crop.size[1] > target_h + 2:
        scale = target_h / float(crop.size[1])
        nw = max(1, int(round(crop.size[0] * scale)))
        nh = max(1, int(round(crop.size[1] * scale)))
        crop = crop.resize((nw, nh), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    px = (CANVAS[0] - crop.size[0]) // 2
    py = FEET_Y - crop.size[1] + 1
    canvas.paste(crop, (px, py), crop)
    return canvas


def rewrite(name: str, source: str | None = None) -> None:
    src_path = ROOT / (source or name)
    dst_path = ROOT / name
    im = Image.open(src_path)
    out = fit_to_idle(im)
    out.save(dst_path)
    print("wrote", dst_path.name, out.size)


def main() -> None:
    for i in range(2):
        rewrite(f"crouch_{i:02d}.png")
    for i in range(3):
        rewrite(f"crouch_shoot_{i:02d}.png")
    # Replace generated oversized down-shot with scaled crouch-shoot (same Kiko size).
    crouch_srcs = ["crouch_shoot_00.png", "crouch_shoot_01.png", "crouch_shoot_02.png"]
    for i in range(5):
        rewrite(f"shoot_down_{i:02d}.png", crouch_srcs[min(i, 2)])
    rewrite("shoot_down_crouch_start_00.png", "crouch_shoot_00.png")
    rewrite("shoot_down_aim_00.png", "crouch_shoot_01.png")
    rewrite("shoot_down_fire_00.png", "crouch_shoot_02.png")
    rewrite("shoot_down_recoil_00.png", "crouch_shoot_01.png")
    rewrite("shoot_down_recovery_00.png", "crouch_shoot_00.png")


if __name__ == "__main__":
    main()
