#!/usr/bin/env python3
"""Melee por arma, projéteis em pixel art e cartucho da espingarda."""
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
                pix[x, y] = (min(255, r + 4), g, max(0, b - 8), alpha)
    return im


def trim(im: Image.Image) -> Image.Image:
    box = im.split()[-1].getbbox()
    return im.crop(box) if box else im


def pack(im: Image.Image) -> Image.Image:
    im = trim(im)
    scale = min(1.15, TARGET_H / max(im.height, 1))
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
    x = int(round(FRAME_W * 0.40 - foot_cx))
    y = FRAME_H - nh - 1
    x = max(-nw + 12, min(x, FRAME_W - 12))
    y = max(0, y)
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def save_anim(name: str, frames: list[Image.Image]) -> None:
    FRAMES.mkdir(parents=True, exist_ok=True)
    for i, frame in enumerate(frames):
        pack(knockout(frame)).save(FRAMES / f"{name}_{i:02d}.png")
    print(f"  {name}: {len(frames)}")


def save_fx(name: str, im: Image.Image) -> None:
    FX.mkdir(parents=True, exist_ok=True)
    trim(knockout(im)).save(FX / f"{name}.png")
    print(f"  fx {name}")


def main() -> None:
    smg_melee = Image.open(SPR / "melee_fuzil.png")
    save_anim("melee_fuzil", [
        smg_melee.crop((17, 18, 63, 107)),
        smg_melee.crop((66, 18, 139, 107)),
        smg_melee.crop((66, 18, 139, 107)),
    ])
    close = Image.open(SPR / "melee_revolver_shotgun.png")
    save_anim("melee_pistola", [
        close.crop((70, 90, 330, 400)),
        close.crop((70, 90, 330, 400)),
    ])
    save_anim("melee_doze", [
        close.crop((340, 90, 670, 420)),
        close.crop((340, 90, 670, 420)),
    ])

    fuzil_sheet = Image.open(SPR / "shoot_fuzil.png")
    fuzil_frames = [
        fuzil_sheet.crop((16, 4, 119, 145)),
        fuzil_sheet.crop((170, 4, 288, 145)),
        fuzil_sheet.crop((339, 4, 465, 145)),
        fuzil_sheet.crop((512, 4, 610, 145)),
        fuzil_sheet.crop((698, 4, 812, 145)),
        fuzil_sheet.crop((839, 4, 944, 145)),
    ]
    save_anim("shoot_fuzil", fuzil_frames)
    save_anim("jump_shoot_fuzil", fuzil_frames)

    eject = Image.open(SPR / "shotgun_eject.png")
    extra = [
        eject.crop((9, 2, 81, 95)),
        eject.crop((90, 2, 150, 95)),
    ]
    # Keep existing shotgun body frames 00-04; add eject as 05-06.
    save_anim("shoot_doze_eject", extra)
    # Also append onto shoot_doze by writing 05/06 from eject.
    for i, frame in enumerate(extra):
        pack(knockout(frame)).save(FRAMES / f"shoot_doze_{i + 5:02d}.png")
    print("  shoot_doze extra eject frames")

    save_fx("shotgun_blast", Image.open(SPR / "fx_shotgun_blast.png"))
    save_fx("muzzle_revolver", Image.open(SPR / "fx_revolver_shot.png"))
    save_fx("muzzle_fuzil", Image.open(SPR / "fx_fuzil_muzzle.png"))

    p6 = Image.open(SPR / "fx_fuzil_bullet.png")
    save_fx("bullet_fuzil", p6.crop((14, 16, 40, 30)))

    p4 = Image.open(SPR / "fx_revolver_shot.png")
    save_fx("bullet_revolver", p4.crop((58, 16, 77, 38)))
    save_fx("casing", p4.crop((8, 44, 28, 64)))

    blast = Image.open(SPR / "fx_shotgun_blast.png")
    save_fx("pellet_doze", blast.crop((160, 80, 174, 95)))
    print("weapon fx ready")


if __name__ == "__main__":
    main()
