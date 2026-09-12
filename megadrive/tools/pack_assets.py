#!/usr/bin/env python3
"""Pack Godot pixel art into indexed Mega Drive sprite sheets."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT.parent / "assets"
GFX = ROOT / "res" / "gfx"

KIKO_W, KIKO_H = 48, 48
JAVALI_W, JAVALI_H = 72, 40
BOSS_W, BOSS_H = 72, 40


def to_md_indexed(im: Image.Image, n_colors: int = 15, transparent: bool = True) -> Image.Image:
    rgba = im.convert("RGBA")
    w, h = rgba.size
    pix = list(rgba.getdata())
    opaque = [(r, g, b) for r, g, b, a in pix if a >= 128]
    out = Image.new("P", (w, h))
    if not opaque:
        out.putpalette([0] * 768)
        return out
    tmp = Image.new("RGB", (len(opaque), 1))
    tmp.putdata(opaque)
    q = tmp.quantize(colors=max(1, min(n_colors, len(set(opaque)))), method=Image.Quantize.MEDIANCUT)
    pal = list(q.getpalette()[: n_colors * 3])
    while len(pal) < n_colors * 3:
        pal.extend([0, 0, 0])
    full = [0, 0, 0] + pal
    full.extend([0] * (768 - len(full)))
    out.putpalette(full)
    colors = [tuple(pal[i : i + 3]) for i in range(0, len(pal), 3)]
    data = []
    for r, g, b, a in pix:
        if transparent and a < 128:
            data.append(0)
            continue
        best, bd = 1, 10**9
        for i, c in enumerate(colors, start=1):
            d = (r - c[0]) ** 2 + (g - c[1]) ** 2 + (b - c[2]) ** 2
            if d < bd:
                best, bd = i, d
        data.append(best)
    out.putdata(data)
    return out


def save_indexed(im: Image.Image, path: Path, transparent: bool = True) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    to_md_indexed(im, transparent=transparent).save(path, format="PNG")


def pad_frame(im: Image.Image, fw: int, fh: int) -> Image.Image:
    src = im.convert("RGBA")
    out = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    ox = max(0, (fw - src.width) // 2)
    oy = max(0, fh - src.height)
    out.paste(src, (ox, oy), src)
    return out


def load_seq(folder: str, prefix: str, count: int) -> list[Image.Image]:
    frames: list[Image.Image] = []
    base = GODOT / "frames" / folder
    for i in range(count):
        path = base / f"{prefix}_{i:02d}.png"
        if not path.exists():
            break
        frames.append(Image.open(path).convert("RGBA"))
    if not frames:
        raise FileNotFoundError(f"missing Godot frames {folder}/{prefix}_00.png")
    return frames


def sheet(anims: list[list[Image.Image]], fw: int, fh: int) -> Image.Image:
    max_f = max(len(a) for a in anims)
    out = Image.new("RGBA", (max_f * fw, len(anims) * fh), (0, 0, 0, 0))
    for ay, frames in enumerate(anims):
        for ax, fr in enumerate(frames):
            cell = pad_frame(fr, fw, fh)
            out.paste(cell, (ax * fw, ay * fh), cell)
    return out


def opaque_bbox(im: Image.Image) -> tuple[int, int, int, int]:
    a = im.convert("RGBA")
    px = a.load()
    xs, ys = [], []
    for y in range(a.height):
        for x in range(a.width):
            if px[x, y][3] >= 128:
                xs.append(x)
                ys.append(y)
    if not xs:
        return (0, 0, 0, 0)
    return (min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)


def make_kiko() -> None:
    anims = [
        load_seq("kiko", "idle", 4),
        load_seq("kiko", "walk", 8),
        load_seq("kiko", "jump", 2),
        load_seq("kiko", "crouch", 1),
        load_seq("kiko", "shoot", 2),
        load_seq("kiko", "melee", 3),
        load_seq("kiko", "hurt", 1),
        load_seq("kiko", "death", 1),
        load_seq("kiko", "rage", 3),
    ]
    sh = sheet(anims, KIKO_W, KIKO_H)
    save_indexed(sh, GFX / "kiko.png", True)
    print("kiko opaque", opaque_bbox(pad_frame(anims[0][0], KIKO_W, KIKO_H)))


def make_javali() -> None:
    anims = [
        load_seq("javali", "run", 4),
        load_seq("javali", "charge", 3),
        load_seq("javali", "jump", 2),
        load_seq("javali", "die", 1),
        load_seq("javali", "blindado", 3),
    ]
    sh = sheet(anims, JAVALI_W, JAVALI_H)
    save_indexed(sh, GFX / "javali.png", True)
    print("javali opaque", opaque_bbox(pad_frame(anims[0][0], JAVALI_W, JAVALI_H)))


def make_boss() -> None:
    anims = [
        load_seq("javali", "boss_idle", 2),
        load_seq("javali", "boss_charge", 3),
        load_seq("javali", "boss_jump", 2),
    ]
    sh = sheet(anims, BOSS_W, BOSS_H)
    save_indexed(sh, GFX / "boss.png", True)
    print("boss opaque", opaque_bbox(pad_frame(anims[0][0], BOSS_W, BOSS_H)))


def make_fx() -> None:
    bullet = Image.open(GODOT / "frames" / "fx" / "bullet.png").convert("RGBA")
    save_indexed(pad_frame(bullet, 16, 8), GFX / "bullet.png", True)

    boom = []
    for i in range(4):
        boom.append(Image.open(GODOT / "frames" / "fx" / f"explosion_{i:02d}.png").convert("RGBA"))
    save_indexed(sheet([boom], 32, 32), GFX / "explosion.png", True)

    crate = Image.open(GODOT / "ui" / "crate.png").convert("RGBA")
    save_indexed(pad_frame(crate, 32, 32), GFX / "crate.png", True)

    heart = Image.open(GODOT / "ui" / "heart.png").convert("RGBA")
    save_indexed(pad_frame(heart, 16, 16), GFX / "heart.png", True)


def make_tiles() -> None:
    names = ["empty", "sky", "grass", "dirt", "wood", "barn", "corn", "fence", "fire", "metal", "plat", "moon"]
    strip = Image.new("RGBA", (16 * len(names), 16), (11, 16, 32, 255))
    for i, name in enumerate(names):
        src = GODOT / "tiles" / f"{name}.png"
        if name == "empty":
            cell = Image.new("RGBA", (16, 16), (11, 16, 32, 255))
        elif name == "sky":
            sky = Image.open(GODOT / "tiles" / "sky.png").convert("RGB")
            cell = sky.resize((16, 16), Image.Resampling.NEAREST)
        elif name == "plat":
            wood = Image.open(GODOT / "tiles" / "wood.png").convert("RGBA").resize((16, 16), Image.Resampling.NEAREST)
            cell = Image.new("RGBA", (16, 16), (11, 16, 32, 255))
            cell.paste(wood.crop((0, 8, 16, 16)), (0, 8))
        elif name == "moon":
            cell = Image.new("RGBA", (16, 16), (11, 16, 32, 255))
            # small moon from sky crop
            sky = Image.open(GODOT / "tiles" / "sky.png").convert("RGB")
            moon = sky.crop((390, 28, 430, 68)).resize((16, 16), Image.Resampling.NEAREST)
            cell.paste(moon)
        elif src.exists():
            cell = Image.open(src).convert("RGBA").resize((16, 16), Image.Resampling.NEAREST)
        else:
            cell = Image.new("RGBA", (16, 16), (11, 16, 32, 255))
        strip.paste(cell, (i * 16, 0))
    save_indexed(strip.convert("RGB"), GFX / "tiles.png", False)


def make_title() -> None:
    poster = Image.open(GODOT / "ui" / "title_poster.png").convert("RGB")
    # Crest + title + Kiko bust from the vertical poster.
    crop = poster.crop((0, 20, poster.width, 280))
    title = crop.resize((192, 80), Image.Resampling.LANCZOS)
    save_indexed(title, GFX / "title.png", False)


def main() -> None:
    GFX.mkdir(parents=True, exist_ok=True)
    make_kiko()
    make_javali()
    make_boss()
    make_fx()
    make_tiles()
    make_title()
    print("MD gfx packed from", GODOT)


if __name__ == "__main__":
    main()
