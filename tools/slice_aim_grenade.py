#!/usr/bin/env python3
"""Recorta mira para cima/diagonal e animacoes de granada das sheets novas."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPR = ROOT / "assets" / "sprites"
KIKO = ROOT / "assets" / "frames" / "kiko"
FX = ROOT / "assets" / "frames" / "fx"

TARGET_H = 64
FRAME_W, FRAME_H = 96, 84
REF_BODY_H = 118
AIM_BG = (157, 195, 231)
GRENADE_BG = (174, 196, 217)


def knockout(crop: Image.Image, bg: tuple[int, int, int], tol: int = 30) -> Image.Image:
    im = crop.convert("RGBA")
    pix = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _a = pix[x, y]
            dist = max(abs(r - bg[0]), abs(g - bg[1]), abs(b - bg[2]))
            if dist <= tol:
                pix[x, y] = (0, 0, 0, 0)
            elif dist <= tol + 10 and b > r + 8 and b > g:
                pix[x, y] = (0, 0, 0, 0)
    return im


def keep_largest(im: Image.Image, n: int = 1, min_alpha: int = 40, min_area: int = 40) -> Image.Image:
    w, h = im.size
    pix = im.load()
    seen = bytearray(w * h)
    blobs: list[list[tuple[int, int]]] = []

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
            if len(cells) >= min_area:
                blobs.append(cells)
    if not blobs:
        box = im.split()[-1].getbbox()
        return im.crop(box) if box else im
    blobs.sort(key=len, reverse=True)
    keep: set[tuple[int, int]] = set()
    for cells in blobs[:n]:
        keep.update(cells)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    op = out.load()
    for x, y in keep:
        op[x, y] = pix[x, y]
    box = out.split()[-1].getbbox()
    if not box:
        return out
    pad = 2
    box = (
        max(0, box[0] - pad),
        max(0, box[1] - pad),
        min(w, box[2] + pad),
        min(h, box[3] + pad),
    )
    return out.crop(box)


def pack_body(im: Image.Image) -> Image.Image:
    box = im.split()[-1].getbbox()
    if box:
        im = im.crop(box)
    scale = TARGET_H / REF_BODY_H
    nw = max(1, round(im.width * scale))
    nh = max(1, round(im.height * scale))
    if nh > FRAME_H - 2:
        scale *= (FRAME_H - 2) / nh
        nw = max(1, round(im.width * scale))
        nh = max(1, round(im.height * scale))
    scaled = im.resize((nw, nh), Image.Resampling.NEAREST)
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


def pack_fx(im: Image.Image, canvas: int, max_dim: int) -> Image.Image:
    box = im.split()[-1].getbbox()
    if box:
        im = im.crop(box)
    scale = max_dim / max(im.width, im.height, 1)
    scale = min(scale, 1.0)
    nw = max(1, round(im.width * scale))
    nh = max(1, round(im.height * scale))
    scaled = im.resize((nw, nh), Image.Resampling.NEAREST)
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    x = (canvas - nw) // 2
    y = (canvas - nh) // 2
    out.paste(scaled, (x, y), scaled)
    return out


def cut(sheet: Image.Image, box: tuple[int, int, int, int], bg: tuple[int, int, int], tol: int = 30) -> Image.Image:
    return knockout(sheet.crop(box), bg=bg, tol=tol)


def kiko_cut(sheet: Image.Image, box: tuple[int, int, int, int], bg: tuple[int, int, int], n: int = 1) -> Image.Image:
    return keep_largest(cut(sheet, box, bg), n=n)


def write_kiko(name: str, frames: list[Image.Image]) -> None:
    KIKO.mkdir(parents=True, exist_ok=True)
    for i, frame in enumerate(frames):
        pack_body(frame).save(KIKO / f"{name}_{i:02d}.png")
    print(f"  kiko/{name}: {len(frames)} frames")


def write_fx(name: str, frames: list[Image.Image], canvas: int, max_dim: int) -> None:
    FX.mkdir(parents=True, exist_ok=True)
    for i, frame in enumerate(frames):
        packed = pack_fx(frame, canvas, max_dim)
        packed.save(FX / f"{name}_{i:02d}.png")
        if name == "grenade_fly" and i == 0:
            packed.save(FX / "grenade.png")
    print(f"  fx/{name}: {len(frames)} frames")


def contact(paths: list[Path], dest: Path) -> None:
    imgs = [Image.open(p).convert("RGBA") for p in paths]
    pad = 4
    w = sum(im.width for im in imgs) + pad * (len(imgs) + 1)
    h = max(im.height for im in imgs) + pad * 2
    sheet = Image.new("RGBA", (w, h), (40, 60, 90, 255))
    x = pad
    for im in imgs:
        sheet.paste(im, (x, pad), im)
        x += im.width + pad
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dest)


def main() -> None:
    aim = Image.open(SPR / "kiko_aim_rifle.png").convert("RGB")
    gren = Image.open(SPR / "kiko_grenade.png").convert("RGB")

    write_kiko("shoot_up", [
        kiko_cut(aim, (40, 300, 103, 415), AIM_BG),
        kiko_cut(aim, (163, 300, 232, 416), AIM_BG),
        kiko_cut(aim, (163, 300, 232, 416), AIM_BG),
    ])
    write_kiko("shoot_diag", [
        kiko_cut(aim, (282, 300, 345, 416), AIM_BG),
        kiko_cut(aim, (384, 308, 462, 416), AIM_BG),
        kiko_cut(aim, (478, 308, 560, 416), AIM_BG),
    ])
    write_kiko("throw_grenade", [
        kiko_cut(gren, (28, 53, 109, 161), GRENADE_BG),
        kiko_cut(gren, (153, 53, 243, 160), GRENADE_BG),
        kiko_cut(gren, (283, 53, 364, 161), GRENADE_BG),
        kiko_cut(gren, (31, 170, 107, 282), GRENADE_BG),
        kiko_cut(gren, (157, 170, 240, 282), GRENADE_BG),
        kiko_cut(gren, (285, 170, 365, 282), GRENADE_BG),
    ])

    grenade = keep_largest(cut(gren, (83, 474, 109, 500), GRENADE_BG, tol=42), n=1)
    fly = [grenade.rotate(ang, expand=True, resample=Image.Resampling.NEAREST) for ang in (0, 45, 90, 135)]
    write_fx("grenade_fly", fly, canvas=22, max_dim=16)

    write_fx("explosion", [
        keep_largest(cut(gren, (20, 440, 115, 510), GRENADE_BG)),
        keep_largest(cut(gren, (144, 412, 258, 503), GRENADE_BG)),
        keep_largest(cut(gren, (276, 347, 406, 502), GRENADE_BG)),
        keep_largest(cut(gren, (430, 349, 611, 506), GRENADE_BG)),
        keep_largest(cut(gren, (626, 344, 822, 505), GRENADE_BG)),
        keep_largest(cut(gren, (836, 369, 989, 514), GRENADE_BG)),
    ], canvas=96, max_dim=88)

    preview = Path("/tmp/kiko-aim-preview")
    contact([KIKO / f"shoot_up_{i:02d}.png" for i in range(3)], preview / "shoot_up.png")
    contact([KIKO / f"shoot_diag_{i:02d}.png" for i in range(3)], preview / "shoot_diag.png")
    contact([KIKO / f"throw_grenade_{i:02d}.png" for i in range(6)], preview / "throw_grenade.png")
    contact([FX / f"grenade_fly_{i:02d}.png" for i in range(4)], preview / "grenade_fly.png")
    contact([FX / f"explosion_{i:02d}.png" for i in range(6)], preview / "explosion.png")
    print("aim/grenade frames ready")


if __name__ == "__main__":
    main()
