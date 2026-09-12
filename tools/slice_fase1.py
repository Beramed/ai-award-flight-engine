#!/usr/bin/env python3
"""Recorta walk do Kiko, javalis, passaro, drone e monta o panorama da fazenda."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SPR = ROOT / "assets" / "sprites"
KIKO = ROOT / "assets" / "frames" / "kiko"
JAVALI = ROOT / "assets" / "frames" / "javali"
BIRD = ROOT / "assets" / "frames" / "passaro"
DRONE = ROOT / "assets" / "frames" / "drone"
FX = ROOT / "assets" / "frames" / "fx"
UI = ROOT / "assets" / "ui"
TILES = ROOT / "assets" / "tiles"
ART = Path("/opt/cursor/artifacts/assets")

KIKO_W, KIKO_H = 96, 84
BODY_H = 64
BOAR_W, BOAR_H = 80, 56
BOAR_BODY = 40
FLY_W, FLY_H = 64, 48


def knockout_blue(im: Image.Image, bg=(163, 201, 237), tol=34) -> Image.Image:
    im = im.convert("RGBA")
    pix = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _a = pix[x, y]
            dist = max(abs(r - bg[0]), abs(g - bg[1]), abs(b - bg[2]))
            if dist <= tol or (b > r + 10 and b > g and dist <= tol + 14):
                pix[x, y] = (0, 0, 0, 0)
    return im


def knockout_grid(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    pix = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _a = pix[x, y]
            mx, mn = max(r, g, b), min(r, g, b)
            if mx < 72 and (mx - mn) < 24:
                pix[x, y] = (0, 0, 0, 0)
            elif mx < 95 and abs(r - g) < 14 and abs(g - b) < 14 and b < 110:
                pix[x, y] = (0, 0, 0, 0)
    return im


def keep_largest(im: Image.Image, n: int = 1, min_area: int = 30) -> Image.Image:
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
            if pix[x, y][3] < 40:
                seen[i] = 1
                continue
            stack = [(x, y)]
            seen[i] = 1
            cells: list[tuple[int, int]] = []
            while stack:
                cx, cy = stack.pop()
                cells.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    j = idx(nx, ny)
                    if seen[j]:
                        continue
                    seen[j] = 1
                    if pix[nx, ny][3] >= 40:
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
    return out.crop(box) if box else out


def pack_feet(im: Image.Image, canvas_w: int, canvas_h: int, body_h: int) -> Image.Image:
    box = im.split()[-1].getbbox()
    if not box:
        return Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    im = im.crop(box)
    scale = body_h / max(im.height, 1)
    scale = min(scale, 1.15)
    nw = max(1, round(im.width * scale))
    nh = max(1, round(im.height * scale))
    if nh > canvas_h - 2:
        scale *= (canvas_h - 2) / nh
        nw = max(1, round(im.width * scale))
        nh = max(1, round(im.height * scale))
    scaled = im.resize((nw, nh), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    alpha = scaled.split()[-1]
    ap = alpha.load()
    foot_xs: list[int] = []
    scan_from = max(0, nh - max(5, nh // 6))
    for y in range(scan_from, nh):
        for x in range(nw):
            if ap[x, y] > 80:
                foot_xs.append(x)
    foot_cx = (min(foot_xs) + max(foot_xs)) / 2 if foot_xs else nw / 2
    x = int(round(canvas_w * 0.46 - foot_cx))
    y = canvas_h - nh - 1
    x = max(-nw + 10, min(x, canvas_w - 10))
    y = max(0, y)
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def pack_center(im: Image.Image, canvas: int, max_dim: int) -> Image.Image:
    box = im.split()[-1].getbbox()
    if box:
        im = im.crop(box)
    scale = max_dim / max(im.width, im.height, 1)
    scale = min(scale, 1.0)
    nw = max(1, round(im.width * scale))
    nh = max(1, round(im.height * scale))
    scaled = im.resize((nw, nh), Image.Resampling.NEAREST)
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.paste(scaled, ((canvas - nw) // 2, (canvas - nh) // 2), scaled)
    return out


def split_row(im: Image.Image, y0: int, y1: int, n: int, trim_top: int = 2, trim_bottom: int = 16) -> list[Image.Image]:
    w = im.width
    cw = w / n
    frames: list[Image.Image] = []
    for i in range(n):
        x0 = int(i * cw) + 4
        x1 = int((i + 1) * cw) - 4
        crop = im.crop((x0, y0 + trim_top, x1, y1 - trim_bottom))
        frames.append(keep_largest(knockout_grid(crop), n=3, min_area=25))
    return frames


def write_anim(folder: Path, name: str, frames: list[Image.Image], packer) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    for i, frame in enumerate(frames):
        packer(frame).save(folder / f"{name}_{i:02d}.png")
    print(f"  {folder.name}/{name}: {len(frames)}")


def make_syringe() -> None:
    im = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((2, 5, 10, 8), fill=(230, 240, 245, 255))
    d.rectangle((10, 6, 13, 7), fill=(180, 190, 200, 255))
    d.rectangle((1, 4, 3, 9), fill=(40, 50, 60, 255))
    d.rectangle((4, 6, 8, 7), fill=(210, 40, 50, 255))
    FX.mkdir(parents=True, exist_ok=True)
    UI.mkdir(parents=True, exist_ok=True)
    im.save(FX / "syringe.png")
    im.resize((18, 18), Image.Resampling.NEAREST).save(UI / "pickup_syringe.png")


def make_rock(src: Image.Image) -> None:
    rock = keep_largest(knockout_grid(src.crop((430, 400, 560, 470))), n=1, min_area=20)
    packed = pack_center(rock, 16, 12)
    FX.mkdir(parents=True, exist_ok=True)
    packed.save(FX / "rock.png")


def stitch_panorama() -> None:
    names = [
        "fazenda_start.png",
        "fazenda_farm.png",
        "fazenda_lake.png",
        "fazenda_fields.png",
        "fazenda_approach.png",
        "fazenda_arena.png",
    ]
    parts: list[Image.Image] = []
    target_h = 270
    for name in names:
        path = ART / name
        if not path.exists():
            print("missing", path)
            continue
        im = Image.open(path).convert("RGB")
        w = max(480, round(im.width * target_h / im.height))
        parts.append(im.resize((w, target_h), Image.Resampling.LANCZOS))
    if not parts:
        return
    total = sum(p.width for p in parts)
    canvas = Image.new("RGB", (total, target_h))
    x = 0
    for p in parts:
        canvas.paste(p, (x, 0))
        x += p.width
    wide = canvas.resize((5600, 270), Image.Resampling.LANCZOS)
    TILES.mkdir(parents=True, exist_ok=True)
    wide.save(TILES / "fazenda_panorama.png")
    print("  panorama", wide.size)


def main() -> None:
    walk_sheet = Image.open(SPR / "kiko_walk_rifle.png")
    idle = [
        knockout_blue(walk_sheet.crop(b))
        for b in [(6, 23, 58, 99), (57, 23, 101, 98), (102, 23, 150, 98), (198, 23, 245, 99)]
    ]
    walk = [
        knockout_blue(walk_sheet.crop(b))
        for b in [
            (5, 120, 63, 190),
            (67, 120, 102, 190),
            (104, 120, 146, 190),
            (147, 120, 191, 190),
            (194, 120, 231, 190),
            (237, 120, 279, 190),
            (284, 120, 337, 190),
        ]
    ]
    kiko_pack = lambda im: pack_feet(keep_largest(im), KIKO_W, KIKO_H, BODY_H)
    write_anim(KIKO, "idle", idle, kiko_pack)
    write_anim(KIKO, "walk", walk, kiko_pack)

    boar_pack = lambda im: pack_feet(im, BOAR_W, BOAR_H, BOAR_BODY)
    morte = Image.open(SPR / "javali_morte.png")
    ataque = Image.open(SPR / "javali_ataque.png")
    die_fwd = split_row(morte, 48, 175, 5, 2, 18) + split_row(morte, 180, 305, 5, 8, 16)
    die_flip = split_row(morte, 358, 543, 8, 26, 8)
    charge = split_row(ataque, 40, 168, 5, 2, 16) + split_row(ataque, 175, 300, 5, 8, 16)
    throw = split_row(ataque, 352, 537, 8, 24, 10)
    write_anim(JAVALI, "charge", charge, boar_pack)
    write_anim(JAVALI, "run", charge[:4], boar_pack)
    write_anim(JAVALI, "throw", throw, boar_pack)
    write_anim(JAVALI, "die_forward", die_fwd, boar_pack)
    write_anim(JAVALI, "die_flip", die_flip, boar_pack)
    write_anim(JAVALI, "die", die_fwd[-2:], boar_pack)

    fly_pack = lambda im: pack_center(im, FLY_W, 40)
    bird = Image.open(SPR / "passaro.png")
    drone = Image.open(SPR / "drone.png")
    bird_fly = split_row(bird, 32, 160, 5, 2, 8) + split_row(bird, 168, 300, 5, 6, 10)
    bird_drop = split_row(bird, 348, 532, 8, 22, 8)
    drone_fly = split_row(drone, 36, 168, 5, 10, 8) + split_row(drone, 178, 305, 5, 6, 10)
    drone_drop = split_row(drone, 348, 552, 8, 22, 8)
    write_anim(BIRD, "fly", bird_fly, fly_pack)
    write_anim(BIRD, "drop", bird_drop, fly_pack)
    write_anim(DRONE, "fly", drone_fly, fly_pack)
    write_anim(DRONE, "drop", drone_drop, fly_pack)

    make_syringe()
    make_rock(ataque)
    stitch_panorama()
    print("fase1 sprites ready")


if __name__ == "__main__":
    main()
