#!/usr/bin/env python3
"""Strip leftover sky-blue halos and keep Kiko frames on a fixed 96x84 canvas."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
KIKO = ROOT / "assets" / "frames" / "kiko"
FX = ROOT / "assets" / "frames" / "fx"
FRAME_W, FRAME_H = 96, 84
BODY_H = 64
BG = (165, 200, 232)


def is_halo(r: int, g: int, b: int, a: int) -> bool:
    if a < 70:
        return True
    dist = max(abs(r - BG[0]), abs(g - BG[1]), abs(b - BG[2]))
    if dist <= 48:
        return True
    if a < 210 and b > r + 14 and b >= g:
        return True
    if a < 180 and b > 90 and b > r + 8 and g > r:
        return True
    return False


def strip_halo(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    pix = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = pix[x, y]
            if is_halo(r, g, b, a):
                pix[x, y] = (0, 0, 0, 0)
    return im


def strip_bullet(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    pix = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = pix[x, y]
            if a < 40:
                pix[x, y] = (0, 0, 0, 0)
                continue
            brass = r > 90 and g > 50 and r >= g and r > b + 8
            if brass:
                continue
            if b > r + 6 and b > 70:
                pix[x, y] = (0, 0, 0, 0)
            elif abs(r - BG[0]) <= 40 and abs(g - BG[1]) <= 40 and abs(b - BG[2]) <= 40:
                pix[x, y] = (0, 0, 0, 0)
    box = im.split()[-1].getbbox()
    return im.crop(box) if box else im


def pack_fixed(im: Image.Image) -> Image.Image:
    box = im.split()[-1].getbbox()
    if not box:
        return Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    trimmed = im.crop(box)
    scale = BODY_H / max(trimmed.height, 1)
    # Never upscale death/hurt flats; never let a gun pose shrink the body.
    if trimmed.height < BODY_H * 0.72:
        scale = 1.0
    else:
        scale = min(scale, 1.0)
    nw = max(1, round(trimmed.width * scale))
    nh = max(1, round(trimmed.height * scale))
    scaled = trimmed.resize((nw, nh), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    alpha = scaled.split()[-1]
    ap = alpha.load()
    foot_xs: list[int] = []
    scan_from = max(0, nh - max(6, nh // 6))
    for y in range(scan_from, nh):
        for x in range(nw):
            if ap[x, y] > 80:
                foot_xs.append(x)
    foot_cx = (min(foot_xs) + max(foot_xs)) / 2 if foot_xs else nw / 2
    x = int(round(FRAME_W * 0.42 - foot_cx))
    y = FRAME_H - nh - 1
    x = max(-nw + 16, min(x, FRAME_W - 16))
    y = max(0, y)
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def main() -> None:
    kiko_n = 0
    for path in sorted(KIKO.glob("*.png")):
        cleaned = strip_halo(Image.open(path))
        pack_fixed(cleaned).save(path)
        kiko_n += 1
    fx_n = 0
    for name in [
        "bullet.png",
        "bullet_fuzil.png",
        "bullet_heavy.png",
        "bullet_revolver.png",
        "bullet_sniper.png",
        "pellet_doze.png",
        "muzzle_fuzil.png",
        "muzzle_revolver.png",
        "casing.png",
        "shotgun_blast.png",
    ]:
        path = FX / name
        if not path.exists():
            continue
        strip_bullet(Image.open(path)).save(path)
        fx_n += 1
    print(f"normalized {kiko_n} kiko frames, {fx_n} fx")


if __name__ == "__main__":
    main()
