#!/usr/bin/env python3
"""HUD arcade, ícones de arma, granada e frames de hurt/death do Kiko."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPR = ROOT / "assets" / "sprites"
FRAMES = ROOT / "assets" / "frames" / "kiko"
FX = ROOT / "assets" / "frames" / "fx"
UI = ROOT / "assets" / "ui"

BG = (165, 200, 232)
TARGET_H = 64
FRAME_W, FRAME_H = 96, 84


def knockout(crop: Image.Image, bg=BG, tol: int = 32, fringe: int = 10) -> Image.Image:
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
                pix[x, y] = (r, g, b, alpha)
    return im


def trim(im: Image.Image) -> Image.Image:
    box = im.split()[-1].getbbox()
    return im.crop(box) if box else im


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


def pack(im: Image.Image, mode: str = "feet") -> Image.Image:
    im = trim(largest_component(im))
    scale = min(1.0, TARGET_H / max(im.height, 1), (FRAME_W - 4) / max(im.width, 1))
    nw = max(1, round(im.width * scale))
    nh = max(1, round(im.height * scale))
    scaled = im.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    if mode == "center":
        x = (FRAME_W - nw) // 2
        y = (FRAME_H - nh) // 2
    else:
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


def fit_icon(im: Image.Image, height: int) -> Image.Image:
    im = trim(im)
    scale = height / max(im.height, 1)
    nw = max(1, round(im.width * scale))
    nh = max(1, round(im.height * scale))
    return im.resize((nw, nh), Image.Resampling.NEAREST)


def process_hud() -> None:
    src = Image.open(SPR / "hud_panel.png").convert("RGBA")
    pix = src.load()
    # Empty the orange HP fill so the live bar can overlay it.
    for y in range(60, 86):
        for x in range(164, 354):
            r, g, b, a = pix[x, y]
            if a > 180 and r > 170 and (r - g) > 40 and b < 110:
                pix[x, y] = (0, 0, 0, 255)
    # Cover baked LIVES/SCORE lines; the live HUD redraws them.
    panel_blue = (26, 76, 112, 255)
    for y in range(96, 170):
        for x in range(164, 448):
            pix[x, y] = panel_blue
    UI.mkdir(parents=True, exist_ok=True)
    src.save(UI / "hud_panel.png")
    print("  ui hud_panel", src.size)


def process_weapons() -> None:
    shotgun = knockout(Image.open(SPR / "icon_shotgun.png").crop((36, 0, 116, 41)))
    revolver = knockout(Image.open(SPR / "icon_revolver.png").crop((18, 0, 62, 33)))
    smg = knockout(Image.open(SPR / "icon_smg.png"))
    UI.mkdir(parents=True, exist_ok=True)
    fit_icon(shotgun, 18).save(UI / "weapon_doze.png")
    fit_icon(revolver, 18).save(UI / "weapon_pistola.png")
    fit_icon(smg, 18).save(UI / "weapon_fuzil.png")
    print("  ui weapons")


def process_grenades() -> None:
    sheet = Image.open(SPR / "grenades.png")
    pin_up = trim(largest_component(knockout(sheet.crop((24, 18, 94, 90)))))
    tossed = trim(largest_component(knockout(sheet.crop((98, 36, 160, 111)))))
    FX.mkdir(parents=True, exist_ok=True)
    UI.mkdir(parents=True, exist_ok=True)
    fit_icon(tossed, 20).save(FX / "grenade.png")
    fit_icon(pin_up, 20).save(FX / "grenade_toss.png")
    fit_icon(tossed, 18).save(UI / "weapon_grenade.png")
    print("  fx grenade", tossed.size, "->", Image.open(FX / "grenade.png").size)


def process_hurt_death() -> None:
    sheet = Image.open(SPR / "kiko_hurt_death.png")
    hurt = [
        knockout(sheet.crop((8, 16, 60, 82))),
        knockout(sheet.crop((58, 16, 112, 82))),
    ]
    death = [
        knockout(sheet.crop((118, 32, 196, 82))),
        knockout(sheet.crop((196, 52, 260, 82))),
    ]
    FRAMES.mkdir(parents=True, exist_ok=True)
    for i, frame in enumerate(hurt):
        pack(frame, "feet").save(FRAMES / f"hurt_{i:02d}.png")
    for i, frame in enumerate(death):
        pack(frame, "center").save(FRAMES / f"death_{i:02d}.png")
    print("  kiko hurt/death")


def main() -> None:
    process_hud()
    process_weapons()
    process_grenades()
    process_hurt_death()
    print("sliced HUD art")


if __name__ == "__main__":
    main()
