#!/usr/bin/env python3
"""Hunter portrait, kneel-down shots, and a farm panorama with smaller props."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "tools" / "source"
SPR = ROOT / "assets" / "sprites"
KIKO = ROOT / "assets" / "frames" / "kiko"
UI = ROOT / "assets" / "ui"
TILES = ROOT / "assets" / "tiles"

TARGET_H = 64
FRAME_W, FRAME_H = 96, 84
REF_BODY_H = 118
KNEEL_BG = (163, 196, 227)


def knockout(crop: Image.Image, bg: tuple[int, int, int], tol: int = 30) -> Image.Image:
    im = crop.convert("RGBA")
    pix = im.load()
    br, bgc, bb = bg
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _a = pix[x, y]
            dist = max(abs(r - br), abs(g - bgc), abs(b - bb))
            if dist <= tol:
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


def write_kiko(name: str, frames: list[Image.Image]) -> None:
    KIKO.mkdir(parents=True, exist_ok=True)
    for i, frame in enumerate(frames):
        pack_body(frame).save(KIKO / f"{name}_{i:02d}.png")
    print(f"  kiko/{name}: {len(frames)} frames")


def make_portrait() -> None:
    src = Image.open(SRC / "samurai_sheet.png").convert("RGBA")
    SPR.mkdir(parents=True, exist_ok=True)
    # Keep the central bust; drop the tiny side sprites and UI chrome.
    bust = src.crop((168, 42, 700, 620))
    knocked = knockout(bust, (250, 249, 249), tol=28)
    # Also drop leftover cream / card beige.
    pix = knocked.load()
    for y in range(knocked.height):
        for x in range(knocked.width):
            r, g, b, a = pix[x, y]
            if a < 8:
                continue
            if r > 220 and g > 215 and b > 200:
                pix[x, y] = (0, 0, 0, 0)
            elif r > 235 and g > 230 and b > 220:
                pix[x, y] = (0, 0, 0, 0)
    face = keep_largest(knocked, n=1, min_area=400)
    box = face.split()[-1].getbbox()
    if box:
        face = face.crop(box)
    canvas = Image.new("RGBA", (160, 160), (12, 10, 8, 255))
    # Fit the bust, a little extra room for the rifle.
    scale = min(148 / face.width, 150 / face.height)
    nw = max(1, round(face.width * scale))
    nh = max(1, round(face.height * scale))
    scaled = face.resize((nw, nh), Image.Resampling.NEAREST)
    canvas.paste(scaled, ((160 - nw) // 2, 160 - nh - 2), scaled)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 159, 159), outline=(196, 154, 42, 255))
    draw.rectangle((1, 1, 158, 158), outline=(92, 64, 18, 255))
    UI.mkdir(parents=True, exist_ok=True)
    canvas.save(UI / "portrait_samurai.png")
    canvas.save("/tmp/portrait_samurai_new.png")
    print("  portrait_samurai", canvas.size)


def slice_kneel() -> None:
    src = Image.open(SRC / "kiko_kneel_down.png").convert("RGBA")
    x0, y0 = 6, 19
    cw, ch = 199, 189

    def cell(col: int, row: int) -> Image.Image:
        box = (
            x0 + col * cw + 10,
            y0 + row * ch + 6,
            x0 + (col + 1) * cw - 8,
            y0 + (row + 1) * ch - 4,
        )
        return keep_largest(knockout(src.crop(box), KNEEL_BG, tol=32), n=1)

    grid = [[cell(c, r) for c in range(3)] for r in range(3)]
    write_kiko("crouch", [grid[0][0], grid[1][0]])
    write_kiko("crouch_shoot", [grid[0][0], grid[0][1], grid[1][2]])
    write_kiko("shoot_diag_down", [grid[0][2], grid[2][1], grid[2][1]])
    write_kiko("shoot_down", [grid[2][0], grid[2][2], grid[2][2]])
    preview = Image.new("RGBA", (FRAME_W * 4 + 20, FRAME_H + 8), (40, 50, 70, 255))
    frames = [
        KIKO / "crouch_00.png",
        KIKO / "crouch_shoot_01.png",
        KIKO / "shoot_diag_down_01.png",
        KIKO / "shoot_down_01.png",
    ]
    x = 4
    for p in frames:
        im = Image.open(p)
        preview.paste(im, (x, 4), im)
        x += FRAME_W + 4
    preview.save("/tmp/kneel_frames_preview.png")
    print("  kneel preview /tmp/kneel_frames_preview.png")


def shrink_panorama() -> None:
    raw = Path(__file__).resolve().parents[1] / "tools" / "source" / "fazenda_panorama_full.png"
    live = TILES / "fazenda_panorama.png"
    if not raw.exists():
        Image.open(live).save(raw)
    src = Image.open(raw).convert("RGB")
    w, h = src.size
    out = Image.new("RGB", (w, h))
    sp = src.load()
    op = out.load()
    ground = 236
    sky_dest = 128
    sky_src = 92
    for y in range(h):
        if y < sky_dest:
            sy = y * sky_src / max(1, sky_dest)
        elif y < ground:
            t = (y - sky_dest) / max(1, ground - sky_dest)
            sy = sky_src + t * (ground - sky_src)
        else:
            sy = y
        syi = min(h - 1, max(0, int(round(sy))))
        for x in range(w):
            op[x, y] = sp[x, syi]
    dest = TILES / "fazenda_panorama.png"
    out.save(dest)
    Image.open(raw).crop((0, 0, min(w, 960), 110)).resize((960, 270), Image.Resampling.NEAREST).save(
        TILES / "fazenda_sky.png"
    )
    out.crop((0, 0, 480, 270)).save("/tmp/fazenda_start_scaled.png")
    print("  panorama shrunk", dest, out.size)


def main() -> None:
    make_portrait()
    slice_kneel()
    shrink_panorama()
    print("farm-flow assets ready")


if __name__ == "__main__":
    main()
