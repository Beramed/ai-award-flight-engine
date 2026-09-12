#!/usr/bin/env python3
"""Generate indexed 4bpp PNG sheets for the Mega Drive (SGDK) port."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
GFX = ROOT / "res" / "gfx"

KIKO_COLORS = {
    "k": (0x1B, 0x14, 0x0F),
    "s": (0xE0, 0xB0, 0x89),
    "b": (0x3A, 0x2A, 0x22),
    "n": (0x1C, 0x33, 0x58),
    "m": (0x2C, 0x4D, 0x7A),
    "h": (0x0E, 0x1B, 0x30),
    "w": (0xD8, 0xDD, 0xE6),
    "g": (0x4A, 0x55, 0x60),
    "y": (0xC9, 0xA2, 0x27),
    "o": (0xF2, 0xC1, 0x4E),
    "a": (0x8A, 0xA0, 0xB8),
    "q": (0x9B, 0x1C, 0x2A),
    "r": (0xB4, 0x23, 0x18),
}

JAVALI_COLORS = {
    "k": (0x1A, 0x12, 0x0C),
    "b": (0x6A, 0x3B, 0x1C),
    "m": (0x8A, 0x52, 0x28),
    "l": (0xC4, 0x89, 0x4A),
    "n": (0x3B, 0x24, 0x16),
    "e": (0xF2, 0xE6, 0xC9),
    "r": (0xC4, 0x1C, 0x1C),
    "p": (0x7A, 0x1D, 0x1D),
    "t": (0x4D, 0x4D, 0x4D),
    "z": (0x9A, 0xA3, 0xAD),
}

PAL_KIKO = [
    (0, 0, 0),
    (0x1B, 0x14, 0x0F),
    (0xE0, 0xB0, 0x89),
    (0x3A, 0x2A, 0x22),
    (0x1C, 0x33, 0x58),
    (0x2C, 0x4D, 0x7A),
    (0x0E, 0x1B, 0x30),
    (0xD8, 0xDD, 0xE6),
    (0x4A, 0x55, 0x60),
    (0xC9, 0xA2, 0x27),
    (0xF2, 0xC1, 0x4E),
    (0x8A, 0xA0, 0xB8),
    (0x9B, 0x1C, 0x2A),
    (0xB4, 0x23, 0x18),
    (0xFF, 0xFF, 0xFF),
    (0x0B, 0x10, 0x20),
]

PAL_JAVALI = [
    (0, 0, 0),
    (0x1A, 0x12, 0x0C),
    (0x6A, 0x3B, 0x1C),
    (0x8A, 0x52, 0x28),
    (0xC4, 0x89, 0x4A),
    (0x3B, 0x24, 0x16),
    (0xF2, 0xE6, 0xC9),
    (0xC4, 0x1C, 0x1C),
    (0x7A, 0x1D, 0x1D),
    (0x4D, 0x4D, 0x4D),
    (0x9A, 0xA3, 0xAD),
    (0xFF, 0xB3, 0x47),
    (0xFF, 0x5A, 0x1F),
    (0xE2, 0xB0, 0x07),
    (0xFF, 0xE5, 0x66),
    (0xFF, 0xFF, 0xFF),
]

PAL_STAGE = [
    (0x0B, 0x10, 0x20),
    (0x12, 0x1A, 0x32),
    (0x3F, 0x7A, 0x2C),
    (0x5B, 0x3A, 0x1E),
    (0x6B, 0x44, 0x24),
    (0x8B, 0x1E, 0x1E),
    (0xD2, 0xB1, 0x3A),
    (0xC4, 0xA1, 0x5A),
    (0xFF, 0x6A, 0x00),
    (0x6D, 0x76, 0x7E),
    (0xE7, 0xE1, 0xC4),
    (0x4A, 0x2E, 0x16),
    (0x8A, 0x6A, 0x3B),
    (0x1A, 0x22, 0x3A),
    (0xC9, 0xA2, 0x27),
    (0xF2, 0xF0, 0xE4),
]


def paint_pixels(size: tuple[int, int], rows: list[str], colors: dict[str, tuple[int, int, int]]) -> Image.Image:
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    px = im.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in (".", " "):
                continue
            rgb = colors[ch]
            px[x, y] = (rgb[0], rgb[1], rgb[2], 255)
    return im


def scale_pad(im: Image.Image, scale: int, fw: int, fh: int) -> Image.Image:
    big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    out = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    ox = (fw - big.width) // 2
    oy = fh - big.height
    if oy < 0:
        oy = 0
    out.paste(big, (ox, oy), big)
    return out


def nearest_index(rgb: tuple[int, int, int], pal: list[tuple[int, int, int]], start: int = 1) -> int:
    best, bd = start, 10**9
    for i, c in enumerate(pal[start:], start):
        d = (rgb[0] - c[0]) ** 2 + (rgb[1] - c[1]) ** 2 + (rgb[2] - c[2]) ** 2
        if d < bd:
            best, bd = i, d
    return best


def to_indexed(im: Image.Image, pal: list[tuple[int, int, int]], transparent: bool) -> Image.Image:
    rgba = im.convert("RGBA")
    out = Image.new("P", rgba.size)
    flat: list[int] = []
    for c in pal:
        flat.extend(c)
    flat.extend([0] * (768 - len(flat)))
    out.putpalette(flat)
    src = rgba.load()
    data = []
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = src[x, y]
            if transparent and a < 128:
                data.append(0)
            else:
                data.append(nearest_index((r, g, b), pal, 0 if not transparent else 1))
    out.putdata(data)
    return out


def save_indexed(im: Image.Image, pal: list[tuple[int, int, int]], path: Path, transparent: bool) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    to_indexed(im, pal, transparent).save(path, format="PNG")


def sheet(anims: list[list[Image.Image]], fw: int, fh: int) -> Image.Image:
    max_f = max(len(a) for a in anims)
    out = Image.new("RGBA", (max_f * fw, len(anims) * fh), (0, 0, 0, 0))
    for ay, frames in enumerate(anims):
        for ax, fr in enumerate(frames):
            out.paste(fr, (ax * fw, ay * fh), fr)
    return out


def kiko_frames() -> dict[str, list[list[str]]]:
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
    return {
        "idle": [idle, idle, shoot, idle],
        "walk": [walk_a, idle, walk_b, walk_c],
        "jump": [jump, jump],
        "crouch": [crouch],
        "shoot": [shoot, shoot],
        "melee": [melee, melee, idle],
        "hurt": [hurt],
        "death": [death],
        "rage": [rage, melee],
    }


def javali_frames() -> dict[str, list[list[str]]]:
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
    return {
        "run": [run1, run2, run1, charge],
        "charge": [charge, charge, run2],
        "jump": [jump, jump],
        "die": [die],
        "blindado": [shield, shield, run2],
    }


def boss_frames() -> dict[str, list[list[str]]]:
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
    return {
        "idle": [boss, boss2],
        "charge": [boss2, boss, boss2],
        "jump": [boss2, boss],
    }


def raster(rows: list[str], colors: dict[str, tuple[int, int, int]], scale: int, fw: int, fh: int) -> Image.Image:
    w = max(len(r) for r in rows)
    h = len(rows)
    return scale_pad(paint_pixels((w, h), rows, colors), scale, fw, fh)


def make_kiko() -> None:
    anims = kiko_frames()
    order = ["idle", "walk", "jump", "crouch", "shoot", "melee", "hurt", "death", "rage"]
    rows = [[raster(fr, KIKO_COLORS, 2, 32, 32) for fr in anims[name]] for name in order]
    save_indexed(sheet(rows, 32, 32), PAL_KIKO, GFX / "kiko.png", True)


def make_javali() -> None:
    anims = javali_frames()
    order = ["run", "charge", "jump", "die", "blindado"]
    rows = [[raster(fr, JAVALI_COLORS, 2, 48, 24) for fr in anims[name]] for name in order]
    save_indexed(sheet(rows, 48, 24), PAL_JAVALI, GFX / "javali.png", True)


def make_boss() -> None:
    anims = boss_frames()
    order = ["idle", "charge", "jump"]
    rows = [[raster(fr, JAVALI_COLORS, 3, 64, 32) for fr in anims[name]] for name in order]
    save_indexed(sheet(rows, 64, 32), PAL_JAVALI, GFX / "boss.png", True)


def make_fx() -> None:
    bullet = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(bullet)
    d.rectangle((1, 3, 14, 4), fill="#fff3c4")
    d.rectangle((2, 2, 12, 5), fill="#f0d060")
    d.point((14, 3), fill="#ffffff")
    save_indexed(bullet, PAL_KIKO, GFX / "bullet.png", True)

    frames = []
    for r in (3, 5, 7, 6):
        ex = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        d = ImageDraw.Draw(ex)
        d.ellipse((16 - r * 2, 16 - r * 2, 16 + r * 2, 16 + r * 2), fill="#ffb347")
        d.ellipse((16 - r * 2 + 4, 16 - r * 2 + 4, 16 + r * 2 - 4, 16 + r * 2 - 4), fill="#ff5a1f")
        frames.append(ex)
    save_indexed(sheet([frames], 32, 32), PAL_JAVALI, GFX / "explosion.png", True)

    crate = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(crate)
    d.rectangle((4, 8, 27, 31), fill="#8a5a2b", outline="#3b2416")
    d.line((4, 20, 27, 20), fill="#c4894a")
    d.line((16, 8, 16, 31), fill="#c4894a")
    save_indexed(crate, PAL_JAVALI, GFX / "crate.png", True)

    heart = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    h = ImageDraw.Draw(heart)
    h.rectangle((3, 4, 12, 8), fill="#e11d48")
    h.polygon([(3, 8), (8, 14), (12, 8)], fill="#e11d48")
    save_indexed(heart, PAL_KIKO, GFX / "heart.png", True)


def make_tiles() -> None:
    # 12 cells of 16x16: empty, sky, grass, dirt, wood, barn, corn, fence, fire, metal, plat, moon
    im = Image.new("RGB", (192, 16), PAL_STAGE[0])
    d = ImageDraw.Draw(im)

    def cell(i: int) -> int:
        return i * 16

    d.rectangle((cell(1), 0, cell(1) + 15, 15), fill=PAL_STAGE[1])
    d.rectangle((cell(2), 6, cell(2) + 15, 15), fill=PAL_STAGE[3])
    d.rectangle((cell(2), 0, cell(2) + 15, 6), fill=PAL_STAGE[2])
    d.rectangle((cell(3), 0, cell(3) + 15, 15), fill=PAL_STAGE[3])
    d.rectangle((cell(4), 0, cell(4) + 15, 15), fill=PAL_STAGE[4])
    d.line((cell(4), 4, cell(4) + 15, 4), fill=PAL_STAGE[11])
    d.rectangle((cell(5), 4, cell(5) + 15, 15), fill=PAL_STAGE[5])
    d.polygon([(cell(5), 4), (cell(5) + 8, 0), (cell(5) + 15, 4)], fill=(0x6B, 0x14, 0x14))
    d.rectangle((cell(6) + 7, 4, cell(6) + 8, 15), fill=PAL_STAGE[2])
    d.ellipse((cell(6) + 5, 1, cell(6) + 10, 7), fill=PAL_STAGE[6])
    d.rectangle((cell(7) + 2, 2, cell(7) + 4, 15), fill=PAL_STAGE[12])
    d.rectangle((cell(7), 5, cell(7) + 15, 7), fill=PAL_STAGE[7])
    d.polygon([(cell(8) + 3, 15), (cell(8) + 8, 2), (cell(8) + 13, 15)], fill=PAL_STAGE[8])
    d.rectangle((cell(9), 0, cell(9) + 15, 15), fill=PAL_STAGE[9])
    d.rectangle((cell(10), 8, cell(10) + 15, 15), fill=PAL_STAGE[4])
    d.ellipse((cell(11) + 3, 3, cell(11) + 12, 12), fill=PAL_STAGE[10])
    save_indexed(im, PAL_STAGE, GFX / "tiles.png", False)


def make_title() -> None:
    im = Image.new("RGB", (240, 72), (8, 10, 22))
    d = ImageDraw.Draw(im)
    d.rectangle((2, 2, 237, 69), outline=(201, 162, 39))
    d.rectangle((4, 4, 235, 67), outline=(242, 193, 78))
    kiko = raster(kiko_frames()["idle"][0], KIKO_COLORS, 3, 48, 48)
    im.paste(kiko, (12, 16), kiko)
    # Pixel title
    def glyph(x: int, y: int, ch: str, color: tuple[int, int, int]) -> None:
        # 3x5 tiny letters we care about
        font = {
            "K": ["#..#", "#.#.", "##..", "#.#.", "#..#"],
            "I": [".##.", ".#..", ".#..", ".#..", ".##."],
            "O": [".##.", "#..#", "#..#", "#..#", ".##."],
            "W": ["#..#", "#..#", "#.##", "##.#", "#..#"],
            "L": ["#...", "#...", "#...", "#...", "####"],
            "D": ["##..", "#.#.", "#..#", "#.#.", "##.."],
            "F": ["####", "#...", "###.", "#...", "#..."],
            "U": ["#..#", "#..#", "#..#", "#..#", ".##."],
            "R": ["###.", "#..#", "###.", "#.#.", "#..#"],
            "Y": ["#..#", "#..#", ".##.", ".#..", ".#.."],
            "M": ["#..#", "####", "#.##", "#..#", "#..#"],
            "A": [".##.", "#..#", "####", "#..#", "#..#"],
            "T": ["####", ".#..", ".#..", ".#..", ".#.."],
            "J": ["..##", "...#", "...#", "#..#", ".##."],
            "V": ["#..#", "#..#", "#..#", ".#.#", "..#."],
            " ": ["....", "....", "....", "....", "...."],
            ":": ["....", ".#..", "....", ".#..", "...."],
            "-": ["....", "....", "####", "....", "...."],
        }
        rows = font.get(ch, font[" "])
        for gy, row in enumerate(rows):
            for gx, pix in enumerate(row):
                if pix == "#":
                    d.rectangle((x + gx * 3, y + gy * 3, x + gx * 3 + 2, y + gy * 3 + 2), fill=color)

    text = "KIKO WILD FURY"
    x = 70
    for ch in text:
        glyph(x, 14, ch, (242, 193, 78))
        x += 12
    x = 78
    for ch in "MATAJAVA":
        glyph(x, 40, ch, (226, 176, 7))
        x += 14
    save_indexed(im, PAL_STAGE, GFX / "title.png", False)


def main() -> None:
    GFX.mkdir(parents=True, exist_ok=True)
    make_kiko()
    make_javali()
    make_boss()
    make_fx()
    make_tiles()
    make_title()
    print("MD gfx written to", GFX)


if __name__ == "__main__":
    main()
