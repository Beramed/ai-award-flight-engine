#!/usr/bin/env python3
"""Slice player / javali / bird / drone reference sheets into fixed-canvas frames.

Key poses come from the supplied sheets. Intermediate frames are interpolated
(not duplicated) and every animation is renumbered sequentially.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SPR = ROOT / "assets" / "sprites"
KIKO = ROOT / "assets" / "frames" / "kiko"
JAVALI = ROOT / "assets" / "frames" / "javali"
BIRD = ROOT / "assets" / "frames" / "passaro"
DRONE = ROOT / "assets" / "frames" / "drone"
FX = ROOT / "assets" / "frames" / "fx"
DEBUG = Path("/tmp/sprite-debug")

KIKO_W, KIKO_H, KIKO_BODY = 96, 84, 64
BOAR_W, BOAR_H, BOAR_BODY = 80, 56, 40
FLY_W, FLY_H = 64, 64
FLY_BODY = 46


def knockout_dark(im: Image.Image, dark: int = 26, white: int = 198) -> Image.Image:
    arr = np.array(im.convert("RGB"), dtype=np.uint8)
    mx = arr.max(axis=2)
    mn = arr.min(axis=2)
    sat = mx - mn
    s = arr.sum(axis=2, dtype=np.int32)
    bg = (mx < dark) | (s < 72) | ((mn > white) & (sat < 48))
    # JPEG ringing: very dark gray near black
    bg |= (mx < 40) & (sat < 18)
    rgba = np.dstack([arr, np.where(bg, 0, 255).astype(np.uint8)])
    return Image.fromarray(rgba, "RGBA")


def knockout_grid(im: Image.Image) -> Image.Image:
    arr = np.array(im.convert("RGBA"))
    r, g, b, a = arr[:, :, 0].astype(np.int16), arr[:, :, 1].astype(np.int16), arr[:, :, 2].astype(np.int16), arr[:, :, 3]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    sat = mx - mn
    # Dark UI grid / charcoal background, including mid-gray cells.
    grid = (sat < 28) & (mx < 125)
    grid |= (mx < 48)
    arr[:, :, 3] = np.where(grid, 0, a)
    return Image.fromarray(arr, "RGBA")


def despeckle(im: Image.Image, min_neighbors: int = 2) -> Image.Image:
    arr = np.array(im)
    a = arr[:, :, 3] > 40
    n = np.zeros(a.shape, dtype=np.uint8)
    n[1:, :] += a[:-1, :]
    n[:-1, :] += a[1:, :]
    n[:, 1:] += a[:, :-1]
    n[:, :-1] += a[:, 1:]
    keep = a & (n >= min_neighbors)
    arr[:, :, 3] = np.where(keep, arr[:, :, 3], 0)
    return Image.fromarray(arr, "RGBA")


def connected_boxes(im: Image.Image, min_area: int = 160, max_area: int = 18000) -> list[tuple[int, int, int, int, int]]:
    a = np.array(im.split()[-1]) > 40
    h, w = a.shape
    seen = np.zeros((h, w), dtype=np.uint8)
    boxes: list[tuple[int, int, int, int, int]] = []
    for y in range(h):
        for x in range(w):
            if not a[y, x] or seen[y, x]:
                continue
            stack = [(x, y)]
            seen[y, x] = 1
            minx = maxx = x
            miny = maxy = y
            area = 0
            while stack:
                cx, cy = stack.pop()
                area += 1
                if cx < minx:
                    minx = cx
                if cx > maxx:
                    maxx = cx
                if cy < miny:
                    miny = cy
                if cy > maxy:
                    maxy = cy
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    if seen[ny, nx] or not a[ny, nx]:
                        continue
                    seen[ny, nx] = 1
                    stack.append((nx, ny))
            bw = maxx - minx + 1
            bh = maxy - miny + 1
            if min_area <= area <= max_area and bh >= 14 and bw >= 8:
                boxes.append((minx, miny, maxx + 1, maxy + 1, area))
    return boxes


def _x_overlap(a: tuple, b: tuple) -> int:
    return min(a[2], b[2]) - max(a[0], b[0])


def merge_boxes(boxes: list[tuple], gap: int = 8) -> list[tuple]:
    """Merge split limbs / muzzle flashes into the nearby character, never a whole row."""
    items = [list(b) for b in boxes]
    changed = True
    while changed:
        changed = False
        items.sort(key=lambda b: b[4], reverse=True)
        for i in range(len(items)):
            for j in range(i + 1, len(items)):
                a, b = items[i], items[j]
                small, large = (b, a) if b[4] < a[4] else (a, b)
                sw, sh = small[2] - small[0], small[3] - small[1]
                lw, lh = large[2] - large[0], large[3] - large[1]
                near = not (
                    a[2] + gap < b[0] or b[2] + gap < a[0] or a[3] + gap < b[1] or b[3] + gap < a[1]
                )
                if not near:
                    continue
                vertical_stack = _x_overlap(a, b) > min(lw, sw) * 0.35 and max(a[4], b[4]) < 5000
                tiny_flash = small[4] < 420 and large[4] > 700
                if not (tiny_flash or (vertical_stack and small[4] < large[4] * 0.65)):
                    continue
                items[i][0] = min(a[0], b[0])
                items[i][1] = min(a[1], b[1])
                items[i][2] = max(a[2], b[2])
                items[i][3] = max(a[3], b[3])
                items[i][4] = a[4] + b[4]
                items.pop(j)
                changed = True
                break
            if changed:
                break
    return [tuple(x) for x in items]


def crop_box(im: Image.Image, box: tuple, pad: int = 2) -> Image.Image:
    x0, y0, x1, y1 = box[0], box[1], box[2], box[3]
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(im.width, x1 + pad)
    y1 = min(im.height, y1 + pad)
    return im.crop((x0, y0, x1, y1))


def pack_feet(im: Image.Image, canvas_w: int, canvas_h: int, body_h: int) -> Image.Image:
    box = im.split()[-1].getbbox()
    if not box:
        return Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    im = im.crop(box)
    scale = body_h / max(im.height, 1)
    scale = min(scale, 1.12)
    nw = max(1, round(im.width * scale))
    nh = max(1, round(im.height * scale))
    if nh > canvas_h - 2:
        scale *= (canvas_h - 2) / nh
        nw = max(1, round(im.width * scale))
        nh = max(1, round(im.height * scale))
    if nw > canvas_w - 4:
        scale *= (canvas_w - 4) / nw
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
    x = max(-nw + 12, min(x, canvas_w - 12))
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
    if nw > canvas - 2 or nh > canvas - 2:
        s = min((canvas - 2) / nw, (canvas - 2) / nh)
        nw = max(1, round(nw * s))
        nh = max(1, round(nh * s))
    scaled = im.resize((nw, nh), Image.Resampling.NEAREST)
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.paste(scaled, ((canvas - nw) // 2, (canvas - nh) // 2), scaled)
    return out


def centroid(im: Image.Image) -> tuple[float, float]:
    arr = np.array(im.split()[-1])
    ys, xs = np.nonzero(arr > 40)
    if len(xs) == 0:
        return im.width / 2, im.height / 2
    return float(xs.mean()), float(ys.mean())


def shift_im(im: Image.Image, dx: int, dy: int) -> Image.Image:
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (dx, dy), im)
    return out


def mean_abs(a: Image.Image, b: Image.Image) -> float:
    aa = np.array(a, dtype=np.int16)
    bb = np.array(b, dtype=np.int16)
    mask = (aa[:, :, 3] > 20) | (bb[:, :, 3] > 20)
    if not mask.any():
        return 0.0
    diff = np.abs(aa.astype(np.int16) - bb)[mask]
    return float(diff.mean())


def lerp_pixelart(a: Image.Image, b: Image.Image, t: float) -> Image.Image:
    ca = centroid(a)
    cb = centroid(b)
    dx = int(round((cb[0] - ca[0]) * t))
    dy = int(round((cb[1] - ca[1]) * t))
    a2 = shift_im(a, dx, dy)
    b2 = shift_im(b, -int(round((cb[0] - ca[0]) * (1.0 - t))), -int(round((cb[1] - ca[1]) * (1.0 - t))))
    aa = np.array(a2, dtype=np.float32)
    bb = np.array(b2, dtype=np.float32)
    out = np.empty_like(aa)
    a_op = aa[:, :, 3:4]
    b_op = bb[:, :, 3:4]
    pick_b = (t >= 0.5) | ((b_op > a_op) & (t >= 0.35))
    out[:, :, :3] = np.where(pick_b, bb[:, :, :3], aa[:, :, :3])
    out[:, :, 3] = a_op[:, :, 0] * (1.0 - t) + b_op[:, :, 0] * t
    # Keep pixel-art edges: snap weak alpha
    out[:, :, 3] = np.where(out[:, :, 3] < 48, 0, np.where(out[:, :, 3] > 200, 255, out[:, :, 3]))
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


def inbetween_count(a: Image.Image, b: Image.Image) -> int:
    d = mean_abs(a, b)
    ca = np.array(centroid(a))
    cb = np.array(centroid(b))
    move = float(np.linalg.norm(ca - cb))
    # Unrelated poses must not be blended into muddy ghosts.
    if d > 26.0 or move > 14.0:
        return 0
    if d < 6.0 and move < 1.5:
        return 0
    if d < 14.0 and move < 5.0:
        return 1
    if d < 22.0:
        return 2
    return 1


def interpolate(frames: list[Image.Image]) -> list[Image.Image]:
    if len(frames) <= 1:
        return frames
    out: list[Image.Image] = [frames[0]]
    for i in range(len(frames) - 1):
        a, b = frames[i], frames[i + 1]
        n = inbetween_count(a, b)
        for k in range(1, n + 1):
            mid = lerp_pixelart(a, b, k / (n + 1))
            if mean_abs(mid, out[-1]) < 3.5 or mean_abs(mid, b) < 3.5:
                continue
            out.append(mid)
        if mean_abs(b, out[-1]) >= 2.0:
            out.append(b)
        elif out[-1] is not b:
            out[-1] = b
    return out


def clear_anim(folder: Path, name: str) -> None:
    import re
    pat = re.compile(rf"^{re.escape(name)}_\d+\.png$")
    if not folder.exists():
        return
    for old in folder.iterdir():
        if pat.match(old.name):
            old.unlink(missing_ok=True)
            Path(str(old) + ".import").unlink(missing_ok=True)


def write_anim(folder: Path, name: str, frames: list[Image.Image], packer) -> list[Image.Image]:
    folder.mkdir(parents=True, exist_ok=True)
    packed = [packer(fr) for fr in frames]
    packed = interpolate(packed)
    clear_anim(folder, name)
    for i, fr in enumerate(packed):
        if fr.size != packed[0].size:
            canvas = Image.new("RGBA", packed[0].size, (0, 0, 0, 0))
            canvas.paste(fr, (0, packed[0].size[1] - fr.size[1]))
            fr = canvas
            packed[i] = fr
        fr.save(folder / f"{name}_{i:02d}.png")
    print(f"  {folder.name}/{name}: {len(packed)} frames {packed[0].size if packed else ''}")
    return packed


def contact_sheet(frames: list[Image.Image], path: Path, cols: int = 8) -> None:
    if not frames:
        return
    w, h = frames[0].size
    cols = min(cols, len(frames))
    rows = (len(frames) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * w, rows * h), (12, 12, 16, 255))
    for i, fr in enumerate(frames):
        sheet.paste(fr, ((i % cols) * w, (i // cols) * h), fr)
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)


def kiko_packer(im: Image.Image) -> Image.Image:
    return pack_feet(im, KIKO_W, KIKO_H, KIKO_BODY)


def _in_rect(cx: float, cy: float, rect: tuple[int, int, int, int]) -> bool:
    x0, y0, x1, y1 = rect
    return x0 <= cx < x1 and y0 <= cy < y1


def _dilate4(mask: np.ndarray) -> np.ndarray:
    out = mask.copy()
    out[1:, :] |= mask[:-1, :]
    out[:-1, :] |= mask[1:, :]
    out[:, 1:] |= mask[:, :-1]
    out[:, :-1] |= mask[:, 1:]
    return out


def grow_silhouette(rgb: np.ndarray, dilate_n: int = 6) -> np.ndarray:
    """Keep dark uniforms by growing from highlights into near-black clothing."""
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    sat = mx - mn
    bg = mx < 12
    label = (mn > 185) & (sat < 50)
    seed = ((mx > 28) | (sat > 14)) & (~label) & (~bg)
    grow_ok = (~bg) & (~label)
    mask = seed.copy()
    for _ in range(dilate_n):
        mask = _dilate4(mask) & grow_ok
    return mask


def column_blobs(rgb: np.ndarray, col: tuple[int, int, int, int], dilate_n: int = 6) -> list[tuple]:
    x0, y0, x1, y1 = col
    sub = rgb[y0:y1, x0:x1]
    mask = grow_silhouette(sub, dilate_n=dilate_n)
    h, w = mask.shape
    seen = np.zeros((h, w), dtype=np.uint8)
    boxes: list[tuple] = []
    for y in range(h):
        for x in range(w):
            if not mask[y, x] or seen[y, x]:
                continue
            stack = [(x, y)]
            seen[y, x] = 1
            minx = maxx = x
            miny = maxy = y
            area = 0
            while stack:
                cx, cy = stack.pop()
                area += 1
                if cx < minx:
                    minx = cx
                if cx > maxx:
                    maxx = cx
                if cy < miny:
                    miny = cy
                if cy > maxy:
                    maxy = cy
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    if seen[ny, nx] or not mask[ny, nx]:
                        continue
                    seen[ny, nx] = 1
                    stack.append((nx, ny))
            bw, bh = maxx - minx + 1, maxy - miny + 1
            if area >= 500 and 18 <= bw < 160 and bh >= 28:
                boxes.append((minx + x0, miny + y0, maxx + 1 + x0, maxy + 1 + y0, area))
    return boxes, mask, (x0, y0)


def extract_kiko() -> None:
    src = Image.open(SPR / "kiko_ref_sheet.jpg").convert("RGB")
    rgb = np.array(src)
    cols = [(0, 0, 350, 1008), (358, 0, 700, 1008), (722, 0, 1060, 1008)]
    chars: list[tuple] = []
    full_mask = np.zeros(rgb.shape[:2], dtype=bool)
    for i, col in enumerate(cols):
        boxes, mask, (x0, y0) = column_blobs(rgb, col, dilate_n=8 if i == 2 else 6)
        full_mask[y0:y0 + mask.shape[0], x0:x0 + mask.shape[1]] |= mask
        chars.extend(boxes)
    alpha = np.where(full_mask, 255, 0).astype(np.uint8)
    rgba = Image.fromarray(np.dstack([rgb, alpha]), "RGBA")

    regions = {
        "idle": [(353, 18, 707, 115)],
        "walk": [(353, 116, 707, 205)],
        "shoot": [(8, 18, 350, 255), (353, 205, 540, 295)],
        "rage": [(8, 540, 350, 720), (353, 205, 707, 300)],
        "jump": [(500, 250, 707, 400)],
        "melee": [(430, 300, 640, 420)],
        "climb": [(8, 265, 250, 530), (353, 300, 430, 520)],
        "victory": [(90, 630, 340, 780), (470, 410, 620, 520)],
        "hurt": [(8, 860, 160, 1008), (353, 520, 480, 640)],
        "death": [(140, 860, 350, 1008), (470, 540, 600, 640)],
        "crouch_walk": [(707, 18, 1060, 150), (707, 255, 1060, 395), (707, 850, 1060, 1008)],
        "crouch_shoot": [(707, 145, 1060, 260)],
        "crouch": [(707, 255, 1060, 395)],
        "shoot_down": [(707, 385, 1060, 850)],
    }
    groups: dict[str, list[tuple]] = {k: [] for k in regions}
    for b in chars:
        cx = (b[0] + b[2]) / 2
        cy = (b[1] + b[3]) / 2
        for name, rects in regions.items():
            if any(_in_rect(cx, cy, r) for r in rects):
                groups[name].append(b)
                break
    print("  kiko groups", {k: len(v) for k, v in groups.items() if v})

    def take(name: str, limit: int = 16) -> list[Image.Image]:
        items = sorted(groups[name], key=lambda b: (b[1] // 18, b[0]))
        picked: list[tuple] = []
        for b in items:
            if any(abs(b[0] - p[0]) < 10 and abs(b[1] - p[1]) < 10 for p in picked):
                continue
            picked.append(b)
            if len(picked) >= limit:
                break
        return [crop_box(rgba, b, pad=1) for b in picked]

    idle = take("idle", 8) or take("shoot", 4)
    walk = take("walk", 10)
    if len(walk) < 4:
        walk_sheet = SPR / "kiko_walk_rifle.png"
        if walk_sheet.exists():
            ws = Image.open(walk_sheet).convert("RGBA")
            pix = np.array(ws)
            bg = np.array([165, 200, 232], dtype=np.int16)
            dist = np.max(np.abs(pix[:, :, :3].astype(np.int16) - bg), axis=2)
            pix[:, :, 3] = np.where(dist <= 36, 0, 255)
            ws = Image.fromarray(pix, "RGBA")
            walk = [
                ws.crop(box)
                for box in [
                    (5, 120, 63, 190), (67, 120, 102, 190), (104, 120, 146, 190),
                    (147, 120, 191, 190), (194, 120, 231, 190), (237, 120, 279, 190),
                    (284, 120, 337, 190),
                ]
            ]
    shoot = take("shoot", 10)
    climb = take("climb", 9)
    rage = take("rage", 6)
    jump = take("jump", 6)
    melee = take("melee", 6)
    victory = take("victory", 4)
    hurt = take("hurt", 6)
    death = take("death", 6)
    crouch_walk = take("crouch_walk", 16)
    crouch = take("crouch", 6) or crouch_walk[:2]
    shoot_down = take("shoot_down", 12)
    crouch_shoot = take("crouch_shoot", 8)

    # Crouch idle from first crouch-walk / crouch-shoot stills.
    if crouch:
        write_anim(KIKO, "crouch", crouch[:4], kiko_packer)
    if crouch_walk:
        write_anim(KIKO, "crouch_walk", crouch_walk, kiko_packer)
    if crouch_shoot:
        write_anim(KIKO, "crouch_shoot", crouch_shoot, kiko_packer)
    if shoot_down:
        sd = write_anim(KIKO, "shoot_down", shoot_down, kiko_packer)
        # Named recoil / aim stills from the fire poses.
        if sd:
            write_anim(KIKO, "shoot_down_aim", [shoot_down[0]], kiko_packer)
            write_anim(KIKO, "shoot_down_fire", [shoot_down[min(2, len(shoot_down) - 1)]], kiko_packer)
            write_anim(KIKO, "shoot_down_recoil", [shoot_down[min(3, len(shoot_down) - 1)]], kiko_packer)
            write_anim(KIKO, "shoot_down_recovery", [shoot_down[0]], kiko_packer)
            write_anim(KIKO, "shoot_down_crouch_start", [crouch[0] if crouch else shoot_down[0]], kiko_packer)
            write_anim(KIKO, "shoot_recoil", [shoot_down[min(2, len(shoot_down) - 1)]], kiko_packer)
    if idle:
        write_anim(KIKO, "idle", idle, kiko_packer)
    if walk:
        wk = write_anim(KIKO, "walk", walk, kiko_packer)
        write_anim(KIKO, "run", walk, kiko_packer)
        if idle:
            write_anim(KIKO, "stand_to_crouch", [idle[0], crouch[0] if crouch else idle[0]], kiko_packer)
            write_anim(KIKO, "crouch_to_stand", [crouch[0] if crouch else idle[0], idle[0]], kiko_packer)
    if shoot:
        write_anim(KIKO, "shoot", shoot, kiko_packer)
        write_anim(KIKO, "shoot_horizontal", shoot, kiko_packer)
        # Diagonal-down from lower rifle poses if we have enough.
        if len(shoot) >= 4:
            write_anim(KIKO, "shoot_diag_down", shoot[2:6], kiko_packer)
    if climb:
        write_anim(KIKO, "climb", climb, kiko_packer)
    if rage:
        write_anim(KIKO, "rage", rage, kiko_packer)
    if jump or idle:
        keys = jump if jump else idle[:1]
        if idle:
            crouch_key = crouch[0] if crouch else idle[0]
            jump_seq = [crouch_key, idle[0], keys[0]]
            if len(keys) > 1:
                jump_seq.append(keys[-1])
            jump_seq.append(idle[0])
        else:
            jump_seq = keys
        write_anim(KIKO, "jump", jump_seq, kiko_packer)
        write_anim(KIKO, "jump_start", [jump_seq[0], jump_seq[min(1, len(jump_seq) - 1)]], kiko_packer)
        write_anim(KIKO, "jump_up", [jump_seq[min(1, len(jump_seq) - 1)], jump_seq[min(2, len(jump_seq) - 1)]], kiko_packer)
        write_anim(KIKO, "jump_fall", [jump_seq[min(2, len(jump_seq) - 1)], jump_seq[-1]], kiko_packer)
        write_anim(KIKO, "landing", [jump_seq[-1], idle[0] if idle else jump_seq[-1]], kiko_packer)
    if melee:
        write_anim(KIKO, "melee", melee, kiko_packer)
    if victory:
        write_anim(KIKO, "victory", victory, kiko_packer)
        write_anim(KIKO, "interact", victory, kiko_packer)
    if hurt:
        write_anim(KIKO, "hurt", hurt, kiko_packer)
        write_anim(KIKO, "hit", hurt, kiko_packer)
    if death:
        write_anim(KIKO, "death", death, kiko_packer)

    # Contact sheets for visual QA
    for name in ["idle", "walk", "crouch", "crouch_walk", "shoot_down", "hurt", "death", "jump"]:
        files = sorted(KIKO.glob(f"{name}_*.png"))
        if files:
            contact_sheet([Image.open(f) for f in files], DEBUG / f"kiko_{name}.png")


def extract_javali() -> None:
    src = Image.open(SPR / "javali_ref_sheet.png")
    rgba = despeckle(knockout_dark(src, dark=20, white=210), min_neighbors=1)
    boxes = [b for b in connected_boxes(rgba, min_area=900, max_area=12000) if (b[3] - b[1]) >= 40]
    boxes = merge_boxes(boxes, gap=6)
    pack = lambda im: pack_feet(im, BOAR_W, BOAR_H, BOAR_BODY)

    run_boxes = []
    throw_boxes = []
    death_boxes = []
    hit_boxes = []
    for b in boxes:
        x0, y0, x1, y1, area = b
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        w, h = x1 - x0, y1 - y0
        if w < 70 or h < 42:
            continue
        if cy > 365 and x0 > 1180:
            continue
        # Numbered run cycle occupies the left grid under the title row.
        if cy >= 185 and cx < 1120:
            run_boxes.append(b)
        elif cy < 160 and cx < 980:
            death_boxes.append(b)
        elif cx > 1650 and cy > 280:
            death_boxes.append(b)
        elif 1400 < cx < 1750 and 180 < cy < 280:
            hit_boxes.append(b)
        elif cx > 1500:
            throw_boxes.append(b)
        elif cy < 160:
            throw_boxes.append(b)

    def crops(items, limit=20):
        items = sorted(items, key=lambda b: (b[1] // 40, b[0]))
        picked = []
        for b in items:
            if any(abs(b[0] - p[0]) < 12 and abs(b[1] - p[1]) < 12 for p in picked):
                continue
            picked.append(b)
            if len(picked) >= limit:
                break
        return [crop_box(rgba, b) for b in picked]

    run = crops(run_boxes, 24)
    throw = crops(throw_boxes, 12)
    death = crops(death_boxes, 16)
    hit = crops(hit_boxes, 8)
    idle = run[:3] if run else throw[:2]

    if idle:
        write_anim(JAVALI, "idle", idle, pack)
    if run:
        write_anim(JAVALI, "walk", run[:12], pack)
        write_anim(JAVALI, "run", run, pack)
        write_anim(JAVALI, "charge", run, pack)
    if throw:
        write_anim(JAVALI, "throw", throw, pack)
        write_anim(JAVALI, "attack", throw, pack)
    if hit:
        write_anim(JAVALI, "hit", hit, pack)
    elif run:
        write_anim(JAVALI, "hit", run[:2], pack)
    if death:
        write_anim(JAVALI, "die", death, pack)
        write_anim(JAVALI, "die_forward", death, pack)
        write_anim(JAVALI, "death", death, pack)
        write_anim(JAVALI, "die_flip", list(reversed(death)), pack)
    # Keep armored/boss on the same canvas using run frames as fallback
    if run:
        write_anim(JAVALI, "blindado", run[:6], pack)
        write_anim(JAVALI, "jump", run[2:6] if len(run) >= 6 else run, pack)
    for name in ["run", "throw", "die", "charge"]:
        files = sorted(JAVALI.glob(f"{name}_*.png"))
        if files:
            contact_sheet([Image.open(f) for f in files], DEBUG / f"javali_{name}.png")


def extract_bird() -> None:
    src = Image.open(SPR / "passaro_ref_sheet.jpg")
    rgba = despeckle(knockout_dark(src, dark=30, white=210))
    boxes = [b for b in connected_boxes(rgba, min_area=1200, max_area=9000) if (b[2] - b[0]) >= 50]
    pack = lambda im: pack_center(im, FLY_W, FLY_BODY)
    fly_boxes = []
    drop_boxes = []
    death_boxes = []
    for b in boxes:
        x0, y0, x1, y1, area = b
        cy = (y0 + y1) / 2
        h = y1 - y0
        if cy < 430:
            fly_boxes.append(b)
        elif h < 42:
            death_boxes.append(b)  # splash / impact
        else:
            drop_boxes.append(b)

    def crops(items, limit=24):
        items = sorted(items, key=lambda b: (b[1] // 30, b[0]))
        return [crop_box(rgba, b) for b in items[:limit]]

    fly = crops(fly_boxes, 30)
    drop = crops(drop_boxes, 16)
    death = crops(death_boxes, 8)
    if fly:
        write_anim(BIRD, "fly", fly, pack)
        write_anim(BIRD, "idle", fly[4:8] or fly[:4], pack)
        write_anim(BIRD, "walk", fly, pack)
        write_anim(BIRD, "run", fly, pack)
    if drop:
        write_anim(BIRD, "drop", drop, pack)
        write_anim(BIRD, "attack", drop, pack)
    if fly:
        write_anim(BIRD, "hit", fly[:3], pack)
    if death or drop:
        write_anim(BIRD, "die", (death or drop[-4:]), pack)
        write_anim(BIRD, "death", (death or drop[-4:]), pack)
    for name in ["fly", "drop"]:
        files = sorted(BIRD.glob(f"{name}_*.png"))
        if files:
            contact_sheet([Image.open(f) for f in files], DEBUG / f"bird_{name}.png")


def extract_drone() -> None:
    src = Image.open(SPR / "drone.png").convert("RGBA")
    grid = knockout_grid(src)

    def cells(y0: int, y1: int, n: int, trim_top: int = 8, trim_bot: int = 10) -> list[Image.Image]:
        w = src.width
        cw = w / n
        out = []
        for i in range(n):
            crop = grid.crop((int(i * cw) + 8, y0 + trim_top, int((i + 1) * cw) - 8, y1 - trim_bot))
            out.append(crop)
        return out

    def keep_largest_local(im: Image.Image, min_area: int = 40) -> Image.Image:
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
                if len(cells) > len(best):
                    best = cells
        if not best:
            box = im.split()[-1].getbbox()
            return im.crop(box) if box else im
        xs = [p[0] for p in best]
        ys = [p[1] for p in best]
        return im.crop((min(xs), min(ys), max(xs) + 1, max(ys) + 1))

    def split_parts(cell: Image.Image) -> tuple[Image.Image, Image.Image | None]:
        arr = np.array(cell)
        r, g, b, a = arr[:, :, 0].astype(np.int16), arr[:, :, 1].astype(np.int16), arr[:, :, 2].astype(np.int16), arr[:, :, 3]
        brown = (a > 40) & (r > g + 15) & (r > 90) & (b < 90)
        drone = arr.copy()
        drone[:, :, 3] = np.where((a > 40) & (~brown), a, 0)
        crate = arr.copy()
        crate[:, :, 3] = np.where(brown, a, 0)
        d_im = keep_largest_local(Image.fromarray(drone.astype(np.uint8), "RGBA"))
        c_im = Image.fromarray(crate.astype(np.uint8), "RGBA")
        if c_im.split()[-1].getbbox() is None:
            c_im = None
        else:
            c_im = keep_largest_local(c_im)
        if d_im.split()[-1].getbbox() is None:
            d_im = keep_largest_local(cell)
        return d_im, c_im

    pack = lambda im: pack_center(im, FLY_W, 50)
    drones = []
    crate = None
    for cell in cells(28, 168, 5) + cells(168, 312, 5):
        d, c = split_parts(cell)
        drones.append(d)
        if c is not None:
            crate = c
    drops = []
    for cell in cells(328, 548, 8, trim_top=10, trim_bot=16):
        d, c = split_parts(cell)
        drops.append(d)
        if c is not None and crate is None:
            crate = c
    write_anim(DRONE, "fly", drones, pack)
    write_anim(DRONE, "idle", drones[:4], pack)
    write_anim(DRONE, "walk", drones, pack)
    write_anim(DRONE, "run", drones, pack)
    write_anim(DRONE, "drop", drops, pack)
    write_anim(DRONE, "attack", drops, pack)
    write_anim(DRONE, "hit", drones[:3], pack)
    write_anim(DRONE, "die", drops[-4:] if drops else drones[:3], pack)
    write_anim(DRONE, "death", drops[-4:] if drops else drones[:3], pack)
    if crate is not None:
        FX.mkdir(parents=True, exist_ok=True)
        packed_c = pack_center(crate, 24, 20)
        packed_c.save(FX / "drone_crate.png")
        packed_c.save(DRONE / "crate_00.png")
    files = sorted(DRONE.glob("fly_*.png"))
    if files:
        contact_sheet([Image.open(f) for f in files], DEBUG / "drone_fly.png")


def interpolate_existing_kiko() -> None:
    """Add in-betweens to weapon sheets we did not replace."""
    keep = [
        "shoot_up", "shoot_diag", "shoot_pistola", "shoot_fuzil", "shoot_doze",
        "throw_grenade", "melee_fuzil", "melee_pistola", "melee_doze",
        "jump_shoot", "jump_shoot_fuzil",
    ]
    for name in keep:
        files = sorted(KIKO.glob(f"{name}_*.png"))
        if len(files) < 2 or len(files) > 8:
            continue
        frames = [Image.open(f).convert("RGBA") for f in files]
        if any(fr.size != (KIKO_W, KIKO_H) for fr in frames):
            frames = [pack_feet(fr, KIKO_W, KIKO_H, KIKO_BODY) if fr.size != (KIKO_W, KIKO_H) else fr for fr in frames]
        expanded = interpolate(frames)
        if len(expanded) <= len(frames):
            continue
        clear_anim(KIKO, name)
        for i, fr in enumerate(expanded):
            fr.save(KIKO / f"{name}_{i:02d}.png")
        print(f"  kiko/{name}: {len(frames)} -> {len(expanded)}")


def main() -> None:
    DEBUG.mkdir(parents=True, exist_ok=True)
    print("kiko")
    extract_kiko()
    print("javali")
    extract_javali()
    print("bird")
    extract_bird()
    print("drone")
    extract_drone()
    print("interpolate leftover kiko")
    interpolate_existing_kiko()
    print("done")


if __name__ == "__main__":
    main()
