#!/usr/bin/env python3
"""Recorta as sheets de combate: pulo, tiro, melee e armas."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPR = ROOT / "assets" / "sprites"
FRAMES = ROOT / "assets" / "frames" / "kiko"
FX = ROOT / "assets" / "frames" / "fx"

TARGET_H = 64
FRAME_W, FRAME_H = 96, 84
BG = (165, 200, 232)


def knockout(crop: Image.Image, bg=BG, tol: int = 34, fringe: int = 12) -> Image.Image:
    im = crop.convert("RGBA")
    pix = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _a = pix[x, y]
            dist = max(abs(r - bg[0]), abs(g - bg[1]), abs(b - bg[2]))
            if dist <= tol:
                pix[x, y] = (0, 0, 0, 0)
            elif dist <= tol + fringe:
                alpha = int(255 * (dist - tol) / fringe)
                pix[x, y] = (min(255, r + 6), g, max(0, b - 10), alpha)
    return im


def largest_bbox(im: Image.Image, min_alpha: int = 40) -> Image.Image:
    w, h = im.size
    pix = im.load()
    seen = bytearray(w * h)
    best: list[tuple[int, int]] = []

    def idx(x: int, y: int) -> int:
        return y * w + x

    for y in range(h):
        for x in range(w):
            i = idx(x, y)
            if seen[i]:
                continue
            if pix[x, y][3] < min_alpha:
                seen[i] = 1
                continue
            stack = [(x, y)]
            seen[i] = 1
            cells: list[tuple[int, int]] = []
            while stack:
                cx, cy = stack.pop()
                cells.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or nx >= w or ny < 0 or ny >= h:
                        continue
                    j = idx(nx, ny)
                    if seen[j]:
                        continue
                    seen[j] = 1
                    if pix[nx, ny][3] >= min_alpha:
                        stack.append((nx, ny))
            if len(cells) > len(best):
                best = cells
    if not best:
        box = im.split()[-1].getbbox()
        return im.crop(box) if box else im
    xs = [p[0] for p in best]
    ys = [p[1] for p in best]
    pad = 2
    box = (
        max(0, min(xs) - pad),
        max(0, min(ys) - pad),
        min(w, max(xs) + 1 + pad),
        min(h, max(ys) + 1 + pad),
    )
    return im.crop(box)


def pack(im: Image.Image) -> Image.Image:
    im = largest_bbox(im)
    box = im.split()[-1].getbbox()
    if box:
        im = im.crop(box)
    scale = TARGET_H / max(im.height, 1)
    scale = min(scale, 1.15)
    nw = max(1, round(im.width * scale))
    nh = max(1, round(im.height * scale))
    scaled = im.resize((nw, nh), Image.Resampling.LANCZOS)
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


def cut(sheet: Image.Image, box: tuple[int, int, int, int], bg=BG) -> Image.Image:
    return knockout(sheet.crop(box), bg=bg)


def write_anim(name: str, frames: list[Image.Image]) -> None:
    FRAMES.mkdir(parents=True, exist_ok=True)
    for i, frame in enumerate(frames):
        pack(frame).save(FRAMES / f"{name}_{i:02d}.png")
    print(f"  {name}: {len(frames)} frames")


def make_big_bullet() -> None:
    im = Image.new("RGBA", (14, 8), (0, 0, 0, 0))
    p = im.load()
    for y in range(8):
        for x in range(14):
            if 1 <= y <= 6 and 0 <= x <= 12:
                p[x, y] = (232, 196, 64, 255)
            if 2 <= y <= 5 and 1 <= x <= 11:
                p[x, y] = (255, 236, 140, 255)
            if y == 4 and x == 13:
                p[x, y] = (255, 255, 255, 255)
    FX.mkdir(parents=True, exist_ok=True)
    im.save(FX / "bullet_revolver.png")


def main() -> None:
    shoot = Image.open(SPR / "shoot_actions.png").convert("RGB")
    melee = Image.open(SPR / "heavy_strike.png").convert("RGB")
    jumpw = Image.open(SPR / "jump_walk.png").convert("RGB")
    fuzil = Image.open(SPR / "shoot_fuzil.png").convert("RGB")
    revolver = Image.open(SPR / "shoot_revolver.png").convert("RGB")
    shotgun = Image.open(SPR / "shoot_shotgun.png").convert("RGB")

    write_anim("shoot", [
        cut(shoot, (4, 18, 66, 82)),
        cut(shoot, (114, 18, 168, 82)),
        cut(shoot, (193, 18, 243, 82)),
        cut(shoot, (266, 18, 320, 82)),
    ])
    write_anim("crouch", [
        cut(shoot, (193, 18, 243, 82)),
        cut(shoot, (266, 18, 320, 82)),
    ])
    write_anim("melee", [
        cut(melee, (11, 20, 57, 107)),
        cut(melee, (60, 20, 133, 107)),
        cut(melee, (60, 20, 133, 107)),
    ])
    write_anim("jump", [
        cut(jumpw, (6, 28, 74, 148)),
        cut(jumpw, (103, 28, 166, 148)),
        cut(jumpw, (193, 28, 255, 148)),
        cut(jumpw, (279, 28, 349, 148)),
        cut(jumpw, (376, 28, 421, 148)),
        cut(jumpw, (456, 28, 504, 148)),
    ])
    write_anim("jump_shoot", [
        cut(jumpw, (530, 28, 583, 148)),
        cut(jumpw, (611, 28, 666, 148)),
        cut(jumpw, (689, 28, 741, 148)),
        cut(jumpw, (776, 28, 832, 148)),
        cut(jumpw, (868, 28, 924, 148)),
        cut(jumpw, (954, 28, 1017, 148)),
        cut(jumpw, (18, 148, 82, 268)),
        cut(jumpw, (111, 148, 172, 268)),
        cut(jumpw, (196, 148, 256, 268)),
        cut(jumpw, (299, 148, 357, 268)),
        cut(jumpw, (380, 148, 437, 268)),
        cut(jumpw, (450, 148, 512, 268)),
    ])
    walk = [
        cut(jumpw, (531, 148, 593, 268)),
        cut(jumpw, (607, 148, 670, 268)),
        cut(jumpw, (683, 148, 741, 268)),
        cut(jumpw, (754, 148, 815, 268)),
        cut(jumpw, (829, 148, 886, 268)),
        cut(jumpw, (958, 148, 1023, 268)),
    ]
    write_anim("walk", walk)
    write_anim("idle", [walk[0], walk[1], walk[0], walk[5]])
    write_anim("shoot_fuzil", [
        cut(fuzil, (32, 48, 136, 185)),
        cut(fuzil, (186, 48, 304, 185)),
        cut(fuzil, (355, 48, 454, 185)),
        cut(fuzil, (528, 48, 626, 185)),
        cut(fuzil, (714, 48, 809, 185)),
        cut(fuzil, (855, 48, 978, 185)),
    ])
    write_anim("jump_shoot_fuzil", [
        cut(fuzil, (32, 48, 136, 185)),
        cut(fuzil, (186, 48, 304, 185)),
        cut(fuzil, (355, 48, 454, 185)),
        cut(fuzil, (528, 48, 626, 185)),
        cut(fuzil, (714, 48, 809, 185)),
        cut(fuzil, (855, 48, 978, 185)),
    ])
    write_anim("shoot_pistola", [
        cut(revolver, (34, 48, 130, 190)),
        cut(revolver, (190, 48, 292, 190)),
        cut(revolver, (399, 48, 500, 190)),
        cut(revolver, (554, 48, 647, 190)),
        cut(revolver, (695, 48, 793, 190)),
        cut(revolver, (909, 48, 1016, 190)),
    ])
    write_anim("shoot_doze", [
        cut(shotgun, (16, 36, 98, 160)),
        cut(shotgun, (110, 36, 252, 160)),
        cut(shotgun, (324, 36, 408, 160)),
        cut(shotgun, (441, 36, 528, 160)),
        cut(shotgun, (564, 36, 649, 160)),
    ])
    make_big_bullet()
    print("combat frames ready")


if __name__ == "__main__":
    main()
