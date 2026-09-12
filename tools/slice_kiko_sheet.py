#!/usr/bin/env python3
"""Recorta a sprite sheet do Kiko (pixel art enviada) e o pôster completo."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SHEET = ROOT / "assets" / "sprites" / "kiko_sheet.jpg"
POSTER = ROOT / "assets" / "sprites" / "title_keyart.jpg"
FRAMES = ROOT / "assets" / "frames" / "kiko"
UI = ROOT / "assets" / "ui"
FX = ROOT / "assets" / "frames" / "fx"

BG = (168, 204, 240)
STAND_H = 166
TARGET_H = 64
SCALE = TARGET_H / STAND_H
FRAME_W, FRAME_H = 96, 84


def is_bg(rgb: tuple[int, int, int], tol: int = 34) -> bool:
    return (
        abs(rgb[0] - BG[0]) <= tol
        and abs(rgb[1] - BG[1]) <= tol
        and abs(rgb[2] - BG[2]) <= tol
    )


def knockout(crop: Image.Image, tol: int = 34, fringe: int = 12) -> Image.Image:
    im = crop.convert("RGBA")
    pix = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _a = pix[x, y]
            dist = max(abs(r - BG[0]), abs(g - BG[1]), abs(b - BG[2]))
            if dist <= tol:
                pix[x, y] = (0, 0, 0, 0)
            elif dist <= tol + fringe:
                alpha = int(255 * (dist - tol) / fringe)
                pix[x, y] = (min(255, r + 6), g, max(0, b - 10), alpha)
    return im


def largest_component(im: Image.Image, min_alpha: int = 40) -> Image.Image:
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
        return im
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


def trim(im: Image.Image) -> Image.Image:
    box = im.split()[-1].getbbox()
    return im.crop(box) if box else im


def pack(im: Image.Image, mode: str = "feet") -> Image.Image:
    im = trim(largest_component(im))
    nw = max(1, round(im.width * SCALE))
    nh = max(1, round(im.height * SCALE))
    scaled = im.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    if mode == "center":
        x = (FRAME_W - nw) // 2
        y = (FRAME_H - nh) // 2
    else:
        # Center using the feet (lowest opaque pixels), not the gun AABB.
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


def cut(sheet: Image.Image, box: tuple[int, int, int, int], isolate: bool = True) -> Image.Image:
    im = knockout(sheet.crop(box))
    return largest_component(im) if isolate else im


def save(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)


def write_anim(name: str, frames: list[Image.Image], mode: str = "feet") -> None:
    for i, frame in enumerate(frames):
        save(pack(frame, mode), FRAMES / f"{name}_{i:02d}.png")


def main() -> None:
    sheet = Image.open(SHEET).convert("RGB")
    poster = Image.open(POSTER).convert("RGB")
    UI.mkdir(parents=True, exist_ok=True)
    poster.save(UI / "title_poster.png")
    poster.save(UI / "title_poster.jpg", quality=95)

    portraits = {
        "portrait_kiko": (18, 19, 143, 149),
        "portrait_kiko_rage": (157, 19, 282, 149),
        "portrait_kiko_side": (296, 19, 423, 148),
    }
    for name, box in portraits.items():
        im = knockout(sheet.crop(box), tol=28, fringe=8)
        save(trim(im), UI / f"{name}.png")

    walk1 = [
        cut(sheet, (21, 193, 130, 360)),
        cut(sheet, (134, 193, 228, 360)),
        cut(sheet, (233, 193, 336, 360)),
        cut(sheet, (338, 193, 442, 360)),
        cut(sheet, (444, 193, 540, 360)),
        cut(sheet, (545, 193, 641, 360)),
        cut(sheet, (641, 193, 749, 360)),
    ]
    walk2 = [
        cut(sheet, (19, 406, 147, 559)),
        cut(sheet, (156, 406, 233, 559)),
        cut(sheet, (237, 406, 329, 559)),
        cut(sheet, (332, 406, 428, 559)),
        cut(sheet, (434, 406, 517, 559)),
        cut(sheet, (529, 406, 621, 559)),
        cut(sheet, (633, 406, 748, 559)),
    ]
    shoot = [
        cut(sheet, (21, 601, 248, 734)),
        cut(sheet, (247, 597, 394, 734)),
        cut(sheet, (436, 604, 561, 734)),
        cut(sheet, (595, 597, 726, 734)),
    ]
    rage = [
        cut(sheet, (34, 779, 132, 945)),
        cut(sheet, (251, 777, 418, 941)),
        cut(sheet, (427, 776, 567, 941)),
        cut(sheet, (586, 748, 722, 928)),
    ]
    melee = [
        cut(sheet, (225, 1023, 330, 1190)),
        cut(sheet, (332, 1020, 497, 1190)),
        cut(sheet, (251, 777, 418, 941)),
    ]
    jump = [
        cut(sheet, (427, 776, 567, 941)),
        cut(sheet, (156, 406, 233, 559)),
        cut(sheet, (586, 748, 722, 928)),
    ]
    climb = [cut(sheet, (44, 972, 139, 1190))]
    hurt = [
        cut(sheet, (24, 1230, 119, 1366)),
        cut(sheet, (136, 1230, 231, 1366)),
    ]
    death = [
        cut(sheet, (271, 1272, 417, 1366)),
        cut(sheet, (431, 1311, 571, 1366)),
    ]

    # Idle: most planted standing walk poses.
    write_anim("idle", [walk1[3], walk1[4], walk1[3], walk1[2]])
    write_anim("walk", walk1 + walk2)
    write_anim("jump", jump)
    write_anim("crouch", [shoot[2], shoot[3]])
    write_anim("shoot", shoot)
    write_anim("shoot_up", [shoot[1], shoot[3]])
    write_anim("melee", melee)
    write_anim("rage", rage)
    write_anim("hurt", hurt)
    write_anim("death", death, mode="center")
    write_anim("climb", climb)
    write_anim("victory", [rage[3]])

    items = {
        "pickup_pistol": (492, 98, 550, 141),
        "pickup_rocket": (554, 91, 611, 149),
        "pickup_medkit": (666, 90, 723, 141),
        "grenade_sheet": (577, 1230, 634, 1278),
        "knives": (609, 1300, 666, 1364),
    }
    for name, box in items.items():
        im = trim(knockout(sheet.crop(box), tol=30, fringe=8))
        dest = UI if name.startswith("pickup") else FX
        save(im, dest / f"{name}.png")

    print("sliced kiko frames into", FRAMES)


if __name__ == "__main__":
    main()
