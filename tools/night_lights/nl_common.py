"""Shared pieces of the night-lights pipeline (city_builder.md §12).

A person draws every light region by hand in the review page (serve.py);
regions.json holds them, and build.py bakes them into the assets the app
draws at night:

    assets/buildings/lights.json        polygons + kind per sprite
    assets/buildings/lit/<sprite>.png   the lit pixels of those regions

Run with the sprite pipeline's venv (needs numpy, opencv, Pillow):

    tools/sprite_pipeline/.venv/bin/python tools/night_lights/serve.py
"""
from __future__ import annotations

import json
import zlib
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SPRITES = ROOT / "assets" / "buildings"
LIT_DIR = SPRITES / "lit"
LIGHTS_JSON = SPRITES / "lights.json"
HERE = Path(__file__).resolve().parent
# Every region a person drew, per sprite: the source of truth.
REGIONS_JSON = HERE / "regions.json"

# Night tint the previews use — the app's multiply colour at full night
# (sky_component.dart: 255 - 175, 255 - 160, 255 - 95).
NIGHT_TINT = np.array([80, 95, 160], dtype=np.float32) / 255.0

# Window light colours, picked per region by a stable hash so a facade is not
# one flat yellow. **Warm shades only**, pale gold to amber: an earlier
# palette had a neutral white and a cool blue-white for variety, and the
# blue ones read as an eyesore beside the rest (the user's call, 2026-10-03).
# Keep the red channel full and blue well under green.
WINDOW_COLOURS = [
    (255, 214, 140),
    (255, 214, 140),
    (255, 226, 166),
    (255, 226, 166),
    (255, 200, 118),
    (255, 236, 196),
    (255, 207, 128),
    (255, 188, 104),
]


def sprite_names() -> list[str]:
    """Every building sprite (`<id>_v<n>.png`), roads excluded."""
    return sorted(
        p.stem for p in SPRITES.glob("*_v*.png") if not p.stem.startswith("road")
    )


def load_rgba(name: str) -> np.ndarray:
    return np.array(Image.open(SPRITES / f"{name}.png").convert("RGBA"))


def sprite_size(name: str) -> tuple[int, int]:
    """(width, height), read from the file's header."""
    with Image.open(SPRITES / f"{name}.png") as image:
        return image.size


def regions_of(name: str, saved: dict) -> list[dict]:
    """The regions drawn on a sprite: `[{id, k, p}]`, `k` being `w`
    (window), `g` (glow) or `l` (lamp) and `p` a flat polygon."""
    return saved.get(name, {}).get("regions", [])


def stable_hash(*parts) -> int:
    return zlib.crc32("/".join(str(p) for p in parts).encode())


def polygon_mask(shape: tuple[int, int], polygon: list[float]) -> np.ndarray:
    """Boolean mask of a flat `[x0, y0, x1, y1, ...]` polygon."""
    pts = np.array(polygon, dtype=np.float32).reshape(-1, 2)
    mask = np.zeros(shape, dtype=np.uint8)
    cv2.fillPoly(mask, [np.round(pts).astype(np.int32)], 255)
    return mask > 0


# Every region is a simple polygon: a window is four corners, and nothing
# needs more than six. That keeps the lit shapes clean and easy to draw and
# correct by hand in the review page.
MAX_VERTICES = 6


def tidy_polygon(mask: np.ndarray, min_fill: float = 0.6) -> list[float] | None:
    """The wand's patch of pixels as a simple polygon: the parallelogram it nearly
    fills (vertical sides, top and bottom on a facade slope or level) when
    there is one — most windows — and otherwise its convex hull cut down to
    at most [MAX_VERTICES] corners."""
    ys, xs = np.nonzero(mask)
    if len(xs) < 6:
        return None
    ys = ys.astype(np.float32)
    xs = xs.astype(np.float32)
    best = None
    for slope in (0.5, -0.5, 0.0):
        yy = ys - slope * xs
        x0, x1 = np.percentile(xs, 2), np.percentile(xs, 98) + 1
        y0, y1 = np.percentile(yy, 2), np.percentile(yy, 98) + 1
        inside = ((xs >= x0) & (xs < x1) & (yy >= y0) & (yy < y1)).sum()
        fill = inside / max((x1 - x0) * (y1 - y0), 1.0)
        if best is None or fill > best[0]:
            best = (fill, slope, (x0, x1, y0, y1))
    fill, slope, (x0, x1, y0, y1) = best
    if fill >= min_fill:
        corners = (
            x0, y0 + slope * x0,
            x1, y0 + slope * x1,
            x1, y1 + slope * x1,
            x0, y1 + slope * x0,
        )
        return [round(float(v), 1) for v in corners]
    points = np.stack([xs, ys], axis=1).astype(np.int32)
    hull = cv2.convexHull(points)
    epsilon = 0.6
    approx = cv2.approxPolyDP(hull, epsilon, True)
    while len(approx) > MAX_VERTICES:
        epsilon *= 1.4
        approx = cv2.approxPolyDP(hull, epsilon, True)
    if len(approx) < 3:
        return None
    pts = approx.reshape(-1, 2).astype(np.float32) + 0.5
    return [round(float(v), 1) for v in pts.reshape(-1)]


def region_centroid(polygon: list[float]) -> tuple[float, float]:
    pts = np.array(polygon, dtype=np.float32).reshape(-1, 2)
    return float(pts[:, 0].mean()), float(pts[:, 1].mean())


def bake_lit(rgba: np.ndarray, regions: list[dict], sprite: str) -> np.ndarray:
    """The lit pixels of [regions] as an RGBA image the size of the sprite.

    A window keeps the sprite's own detail — frames, curtains, panes — as a
    brightness pattern, recoloured to a warm light; a `glow` region (signs,
    lamps, screens) keeps its own hue and is pushed bright. Alpha is the
    region's coverage with a one-pixel feather, clipped to the sprite.
    """
    h, w = rgba.shape[:2]
    rgb = rgba[..., :3].astype(np.float32)
    luma = (0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]) / 255.0
    out = np.zeros((h, w, 4), dtype=np.float32)
    for region in regions:
        if region.get("k") == "l":
            # A point lamp is drawn by the app (a core and a halo), not baked.
            continue
        mask = polygon_mask((h, w), region["p"]) & (rgba[..., 3] > 40)
        if not mask.any():
            continue
        cx, cy = region_centroid(region["p"])
        seed = stable_hash(sprite, round(cx), round(cy))
        values = luma[mask]
        lo, hi = np.percentile(values, 5), np.percentile(values, 95)
        norm = np.clip((luma - lo) / max(hi - lo, 0.08), 0.0, 1.0)
        if region.get("k") == "g":
            # Keep the hue: scale each pixel so its brightest channel is full.
            peak = np.maximum(rgb.max(axis=2, keepdims=True), 1.0)
            colour = rgb / peak * 255.0
            colour = colour * 0.75 + 255.0 * 0.25
            shade = 0.86 + 0.14 * norm
        else:
            base = np.array(
                WINDOW_COLOURS[seed % len(WINDOW_COLOURS)], dtype=np.float32
            )
            colour = np.broadcast_to(base, rgb.shape)
            # Brighter towards the top of the window, like a ceiling lamp.
            ys = np.arange(h, dtype=np.float32)[:, None]
            y0, y1 = np.where(mask.any(axis=1))[0][[0, -1]]
            fall = 1.0 - 0.14 * np.clip((ys - y0) / max(y1 - y0, 1), 0, 1)
            shade = (0.74 + 0.26 * norm) * fall
        lit = np.clip(colour * shade[..., None], 0, 255)
        soft = cv2.GaussianBlur(mask.astype(np.float32), (0, 0), 0.6)
        soft = np.clip(soft * 1.25, 0, 1) * (rgba[..., 3] / 255.0)
        better = soft > out[..., 3]
        out[..., :3][better] = lit[better]
        out[..., 3][better] = soft[better]
    out[..., 3] *= 255.0
    return np.clip(out, 0, 255).astype(np.uint8)


def night_preview(
    rgba: np.ndarray, lit: np.ndarray, background=(18, 24, 38)
) -> np.ndarray:
    """What the sprite looks like at night with [lit] switched on: the
    tinted sprite, a soft glow, then the lit pixels. RGB, on [background]."""
    h, w = rgba.shape[:2]
    alpha = rgba[..., 3:4].astype(np.float32) / 255.0
    base = rgba[..., :3].astype(np.float32) * NIGHT_TINT
    canvas = np.empty((h, w, 3), dtype=np.float32)
    canvas[:] = background
    canvas = canvas * (1 - alpha) + base * alpha
    la = lit[..., 3:4].astype(np.float32) / 255.0
    lrgb = lit[..., :3].astype(np.float32)
    glow_a = cv2.GaussianBlur(la, (0, 0), 3.0)[..., None] if la.any() else la
    glow_c = cv2.GaussianBlur(lrgb * la, (0, 0), 3.0)
    canvas = canvas + glow_c * 0.55 * (glow_a > 0)
    canvas = canvas * (1 - la) + lrgb * la
    return np.clip(canvas, 0, 255).astype(np.uint8)


def write_regions(saved: dict) -> None:
    """regions.json, one region per line so a review reads well in a diff."""
    if not saved:
        REGIONS_JSON.write_text("{}\n")
        return
    blocks = []
    for name in sorted(saved):
        entry = saved[name]
        rows = ",\n".join("  " + json.dumps(r) for r in entry.get("regions", []))
        head = f' {json.dumps(name)}: {{"reviewed": {json.dumps(bool(entry.get("reviewed")))}, "regions": ['
        blocks.append(f"{head}\n{rows}\n ]}}" if rows else f"{head}]}}")
    REGIONS_JSON.write_text("{\n" + ",\n".join(blocks) + "\n}\n")


def read_json(path: Path, default):
    if not path.exists():
        return default
    return json.loads(path.read_text())


def write_json(path: Path, data, compact=False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    separators = (",", ":") if compact else None
    path.write_text(json.dumps(data, separators=separators) + "\n")
