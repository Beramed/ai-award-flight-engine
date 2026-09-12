#!/usr/bin/env python3
"""Gera frames, tiles e UI pixel art para o Godot."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
FRAMES = ROOT / "assets" / "frames"
TILES = ROOT / "assets" / "tiles"
UI = ROOT / "assets" / "ui"


def pal(draw: ImageDraw.ImageDraw, pixels: list[str], colors: dict[str, str], ox=0, oy=0) -> None:
    for y, row in enumerate(pixels):
        for x, ch in enumerate(row):
            if ch in (".", " "):
                continue
            draw.point((ox + x, oy + y), fill=colors[ch])


def save_scale(im: Image.Image, path: Path, scale: int = 2) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.resize((im.width * scale, im.height * scale), Image.NEAREST).save(path)


def gen_kiko() -> None:
    out = FRAMES / "kiko"
    colors = {
        "k": "#1b140f", "s": "#e0b089", "b": "#3a2a22", "n": "#1c3358",
        "m": "#2c4d7a", "h": "#0e1b30", "w": "#d8dde6", "g": "#4a5560",
        "y": "#c9a227", "o": "#f2c14e", "a": "#8aa0b8", "q": "#9b1c2a",
        "r": "#b42318",
    }
    idle = [
        "......kkkk......", ".....kssssk.....", ".....ksbbsk.....",
        ".....kssssk.....", "......kssk......", ".....nnnnnn.....",
        "....nmmmmmmn....", "....nmwwmmmn....", "....nmmmmmmn....",
        "....nmmnnmmn....", ".....gg..gg.....", ".....gg..gg.....",
        ".....hh..hh.....", ".....hh..hh.....", ".....kk..kk.....",
    ]
    walk_a = idle[:-4] + [".....gg...gg....", ".....gg...hh....", ".....hh...kk....", ".....kk........."]
    walk_b = idle[:-4] + ["......gggg......", "......hhhh......", "......kkkk......", "......kkkk......"]
    walk_c = idle[:-4] + ["....gg...gg.....", "....hh...gg.....", "....kk...hh.....", ".........kk....."]
    jump = idle[:10] + [".gg..........gg.", ".hh..........hh.", ".kk..........kk.", "................", "................"]
    crouch = [
        "................", "................", "......kkkk......", ".....kssssk.....",
        ".....ksbbsk.....", ".....kssssk.....", ".....nnnnnn.....", "....nmmmmmmn....",
        "....nmwwmmmn....", "....nmmmmmmn....", "....gggggggg....", "....hhhhhhhh....",
        "....kk....kk....", "................", "................",
    ]
    shoot = idle[:6] + ["....nmmmmmmgggyo", "....nmwwmmmggg.."] + idle[8:]
    melee = [
        "......kkkk......", ".....kssssk.....", ".....ksbbsk.....", ".....kssssk.....",
        "......kssk...a..", ".....nnnnnn.aa..", "....nmmmmmmaa...", "....nmwwmmmn....",
        "....nmmmmmmn....", "....nmmnnmmn....", ".....gg..gg.....", ".....gg..gg.....",
        ".....hh..hh.....", ".....hh..hh.....", ".....kk..kk.....",
    ]
    rage = melee[:]
    rage[0] = "......qkkkq....."
    hurt = [r.replace("bb", "rr") if "bb" in r else r for r in idle]
    death = [
        "................", "................", "................", "................",
        "................", "................", ".kkkk.nnnnnn.gg.", "ksssskmmmmmmggh.",
        "ksbbskmmwwmmhhk.", "kssssknnnnnnkk..", ".kssk...........", "................",
        "................", "................", "................",
    ]
    aim_up = [
        "..........o.....", ".........gy.....", "......kkkg......", ".....ksssgk.....",
        ".....ksbbsk.....", ".....kssssk.....", "......kssk......", ".....nnnnnn.....",
        "....nmmmmmmn....", "....nmwwmmmn....", ".....gg..gg.....", ".....gg..gg.....",
        ".....hh..hh.....", ".....hh..hh.....", ".....kk..kk.....",
    ]
    anims = {
        "idle": [idle, idle, shoot, idle],
        "walk": [walk_a, idle, walk_b, walk_c, idle, walk_a, walk_b, walk_c],
        "jump": [jump, jump],
        "crouch": [crouch],
        "shoot": [shoot, shoot],
        "shoot_up": [aim_up, aim_up],
        "melee": [melee, melee, idle],
        "rage": [rage, melee, rage],
        "hurt": [hurt],
        "death": [death],
    }
    for name, frames in anims.items():
        for i, frame in enumerate(frames):
            im = Image.new("RGBA", (16, 15), (0, 0, 0, 0))
            pal(ImageDraw.Draw(im), frame, colors)
            save_scale(im, out / f"{name}_{i:02d}.png", 3)


def gen_javali() -> None:
    out = FRAMES / "javali"
    colors = {
        "k": "#1a120c", "b": "#6a3b1c", "m": "#8a5228", "l": "#c4894a",
        "n": "#3b2416", "e": "#f2e6c9", "r": "#c41c1c", "p": "#7a1d1d",
        "t": "#4d4d4d", "z": "#9aa3ad",
    }
    run1 = [
        "......................", "..............kk......", "....kkkkkkkkk.kbk.....",
        "...kmmmmmmmmmkbmk.....", "..kmllllllllmmbmk.....", ".kmlleellllllmmnk.....",
        "kmmllllllllmmnnnk.....", "knmmmmmmmmmmnnnk......", ".knn......nnnk........",
        "..kk.kk..kk.kk........", "......................",
    ]
    run2 = run1[:9] + [".kk....kk....kk.......", "......................"]
    charge = [
        "......................", "...........kk.........", "....kkkkkkk.kbkk......",
        "...kmmmmmmmmlbmk......", "..kmlllllllmmbmkk.....", ".kmlleellllmmnnnk.....",
        "kmmllllllllmmnnnk.....", "knmmmmmmmmmmnnnk......", ".knn......nnnk........",
        "kk.kk......kk.kk......", "......................",
    ]
    jump = run1[:8] + ["kk.kk......kk.kk......", "......................", "......................"]
    die = [
        "......................", "......................", "......................",
        ".kkkkkkkkkk...........", "kmmmmmmmmmmk.kk.......", "kllllllllmmkbmk.......",
        "kllleelllmmmbmk.......", "kmmmmmmmmmmnnnk.......", ".kkkkkkkkkkkkk........",
        "......................", "......................",
    ]
    shield = [
        "......................", "..............kk......", "....kkkkkkkkk.kbk.zzz.",
        "...kmmmmmmmmmkbmk.ztz.", "..kmllllllllmmbmk.ztz.", ".kmlleellllllmmnk.zzz.",
        "kmmllllllllmmnnnk.....", "knmmmmmmmmmmnnnk......", ".knn......nnnk........",
        "..kk.kk..kk.kk........", "......................",
    ]
    boss = [
        "........................", ".............rr.........", "............rprr.kk.....",
        ".....kkkkkkkkprkkbk.....", "....kmmmmmmmmmmmbmk.....", "...kmlllllllllmmbmk.....",
        "..kmlleeeelllllmmnk.....", ".kmmllllllllllmmnnk.....", "kmmmmmmmmmmmmmmnnnk.....",
        ".knn........nnnnk.......", "..kk.kk....kk.kk........", "........................",
    ]
    boss2 = [
        "........................", "............rrr.........", "...........rppr.kk......",
        ".....kkkkkkkprkkbk......", "....kmmmmmmmmmmmbmk.....", "...kmlllllllllmmbmkk....",
        "..kmlleeeelllllmmnk.....", ".kmmllllllllllmmnnk.....", "kmmmmmmmmmmmmmmnnnk.....",
        ".knn........nnnnk.......", "kk..kk......kk..kk......", "........................",
    ]
    mapping = {
        "run": [run1, run2, run1, charge],
        "charge": [charge, charge, run2],
        "jump": [jump, jump],
        "die": [die],
        "blindado": [shield, shield, run2],
        "boss_idle": [boss, boss2],
        "boss_charge": [boss2, boss, boss2],
        "boss_jump": [boss2, boss],
    }
    for name, frames in mapping.items():
        for i, frame in enumerate(frames):
            im = Image.new("RGBA", (24, 12), (0, 0, 0, 0))
            pal(ImageDraw.Draw(im), frame, colors)
            save_scale(im, out / f"{name}_{i:02d}.png", 3)


def gen_fx() -> None:
    out = FRAMES / "fx"

    def bullet(path: Path, color: str) -> None:
        im = Image.new("RGBA", (7, 3), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rectangle((0, 1, 6, 1), fill="#fff3c4")
        d.rectangle((1, 0, 5, 2), fill=color)
        d.point((6, 1), fill="#ffffff")
        save_scale(im, path, 2)

    bullet(out / "bullet.png", "#f0d060")
    bullet(out / "bullet_heavy.png", "#ff8a3c")
    bullet(out / "bullet_sniper.png", "#9cf0ff")
    grenade = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    g = ImageDraw.Draw(grenade)
    g.ellipse((1, 2, 6, 7), fill="#355e3b")
    g.rectangle((3, 0, 4, 2), fill="#888888")
    save_scale(grenade, out / "grenade.png", 2)
    for i, r in enumerate((3, 5, 7, 6)):
        ex = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(ex)
        d.ellipse((8 - r, 8 - r, 8 + r, 8 + r), fill="#ffb347")
        d.ellipse((8 - r + 2, 8 - r + 2, 8 + r - 2, 8 + r - 2), fill="#ff5a1f")
        save_scale(ex, out / f"explosion_{i:02d}.png", 2)
    coin = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    c = ImageDraw.Draw(coin)
    c.ellipse((1, 1, 6, 6), fill="#e2b007")
    c.ellipse((2, 2, 5, 5), fill="#ffe566")
    save_scale(coin, out / "coin.png", 2)
    crate = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(crate)
    d.rectangle((1, 1, 14, 14), fill="#8a5a2b", outline="#3b2416")
    d.line((1, 8, 14, 8), fill="#c4894a")
    d.line((8, 1, 8, 14), fill="#c4894a")
    save_scale(crate, UI / "crate.png", 2)
    heart = Image.new("RGBA", (9, 8), (0, 0, 0, 0))
    h = ImageDraw.Draw(heart)
    h.rectangle((1, 2, 7, 4), fill="#e11d48")
    h.polygon([(1, 4), (4, 7), (7, 4)], fill="#e11d48")
    save_scale(heart, UI / "heart.png", 2)


def gen_tiles() -> None:
    def tile(name: str, paint) -> None:
        im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        paint(ImageDraw.Draw(im), im)
        save_scale(im, TILES / f"{name}.png", 2)

    tile("dirt", lambda d, _i: d.rectangle((0, 0, 15, 15), fill="#5b3a1e"))
    tile("grass", lambda d, _i: (d.rectangle((0, 6, 15, 15), fill="#5b3a1e"), d.rectangle((0, 0, 15, 6), fill="#3f7a2c")))
    tile("wood", lambda d, _i: (d.rectangle((0, 0, 15, 15), fill="#6b4424"), d.line((0, 4, 15, 4), fill="#4a2e16")))
    tile("barn", lambda d, _i: (d.rectangle((0, 4, 15, 15), fill="#8b1e1e"), d.polygon([(0, 4), (8, 0), (15, 4)], fill="#6b1414")))
    tile("corn", lambda d, _i: (d.rectangle((7, 4, 8, 15), fill="#4a7a28"), d.ellipse((5, 1, 10, 7), fill="#d2b13a")))
    tile("fence", lambda d, _i: (d.rectangle((2, 2, 4, 15), fill="#8a6a3b"), d.rectangle((0, 5, 15, 7), fill="#c4a15a")))
    tile("metal", lambda d, _i: d.rectangle((0, 0, 15, 15), fill="#6d767e"))
    tile("fire", lambda d, _i: d.polygon([(3, 15), (8, 2), (13, 15)], fill="#ff6a00"))
    sky = Image.new("RGB", (480, 270), "#0b1020")
    d = ImageDraw.Draw(sky)
    for i in range(270):
        t = i / 269
        d.line((0, i, 479, i), fill=(int(11 + 40 * t), int(16 + 18 * t), int(32 + 30 * t)))
    d.ellipse((390, 28, 430, 68), fill="#e7e1c4")
    sky.save(TILES / "sky.png")
    portrait = Image.new("RGBA", (40, 40), "#1b140f")
    d = ImageDraw.Draw(portrait)
    d.rectangle((0, 0, 39, 39), outline="#e2b007")
    d.ellipse((10, 6, 30, 26), fill="#e0b089")
    d.rectangle((8, 22, 32, 38), fill="#1c3358")
    UI.mkdir(parents=True, exist_ok=True)
    portrait.save(UI / "portrait_kiko.png")
    sam = Image.new("RGBA", (40, 40), "#1b140f")
    d = ImageDraw.Draw(sam)
    d.rectangle((0, 0, 39, 39), outline="#e2b007")
    d.ellipse((10, 8, 30, 28), fill="#c9a07a")
    d.rectangle((6, 4, 34, 10), fill="#8b1e1e")
    sam.save(UI / "portrait_samurai.png")
    dialog = Image.new("RGBA", (220, 58), (12, 10, 8, 230))
    d = ImageDraw.Draw(dialog)
    d.rectangle((1, 1, 218, 56), outline="#e2b007")
    dialog.save(UI / "dialog.png")


def main() -> None:
    # Kiko vem da sprite sheet em tools/slice_kiko_sheet.py — não sobrescrever.
    gen_javali()
    gen_fx()
    gen_tiles()
    print("assets ready at", ROOT)


if __name__ == "__main__":
    main()
