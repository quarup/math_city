#!/usr/bin/env python3
"""Composite the §5.5 road tile set: geometry from code, texture from NB.

Per city_builder.md §5.5, roads need 5 core sprites + 1 safety (`deadend`);
generating finished tiles in Nano Banana tested poorly (edges didn't meet at
the diamond edge midpoints, breaking seamless tiling). This compositor takes
the opposite split: *geometry from code* (exact edge-midpoint crossings,
guaranteed seam-free), *surface from Nano Banana* (asphalt / sidewalk / dash
styling quilted out of a single NB-generated reference tile,
raw_sheets/road_style_ref.jpeg, so the painterly surface quality is NB's even
though the layout is computed).

Output: assets/buildings/road_<shape>.png — flat 1x1 ground tiles on a
200x100 canvas holding a 192x96 diamond (TILE_W=192, matching process.py)
plus a 4px/2px overscan rim so adjacent road tiles overlap a hair instead of
letting grass show through AA-thinned edges.

Canonical orientations (grid +col renders toward screen lower-right, +row
toward screen lower-left; see lib/domain/city/road_sprites.dart for the
mask -> (sprite, flip) resolver these pair with):
  cross     {+col,-col,+row,-row}
  tee       {+col,+row,-col}   (missing -row)
  straight  {+col,-col}
  curve_ud  {+col,+row}        (opens toward screen-down; V-flip = up)
  curve_lr  {+col,-row}        (opens toward screen-right; H-flip = left)
  deadend   {+col}

Usage:
  python3 tools/sprite_pipeline/compose_roads.py            # write assets
  python3 tools/sprite_pipeline/compose_roads.py --preview  # also write
      /tmp/road_tiles_preview.png contact sheet for visual QA
"""

from __future__ import annotations

import math
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets" / "buildings"
STYLE_REF = ROOT / "tools" / "sprite_pipeline" / "raw_sheets" / "road_style_ref.jpeg"

# --- Geometry constants (meters; 1 tile = 10m x 10m per §5.1) ---------------
TILE_M = 10.0
ROAD_HALF = 3.0  # 6m roadway
CURB_SHADOW_W = 0.14  # near-black expansion joint at the asphalt edge
CURB_W = 0.5  # raised curb stones outside the shadow line
GUTTER_W = 0.5  # darkened asphalt strip just inside the edge
DASH_HALF = 0.14  # lane-marking half-width
SLAB_PITCH = 1.25  # sidewalk slab joint spacing (8 slabs per tile => seamless)
SLAB_JOINT_HALF = 0.035
OVERSCAN_M = 0.4  # how far past the tile the texture bleeds (seam cover)

# --- Canvas constants (pixels; must match the Flame renderer) ---------------
TILE_W = 192  # diamond width at authoring resolution (process.py TILE_W)
CANVAS_W, CANVAS_H = 200, 100  # diamond centered => 4px/2px overscan margins
SS = 4  # supersampling factor

PX_PER_M_U = TILE_W / 2 / TILE_M  # 9.6  (u per meter of x - y)
PX_PER_M_V = TILE_W / 4 / TILE_M  # 4.8  (v per meter of x + y)

TEX_SIZE = 128
BLOCK = 12  # texture-quilt block size sampled from the style ref

DASH_COLOR = np.array([240.0, 202.0, 88.0])  # NB's yellow centerline
CURB_GAIN = 1.1  # curb stones read slightly lighter than the sidewalk
CURB_SHADOW_GAIN = 0.45
GUTTER_GAIN = 0.8  # asphalt darkens toward its edges
SLAB_JOINT_GAIN = 0.8


# --- Texture synthesis from the NB style reference ---------------------------


def _ref_masks(im: np.ndarray):
    """Region masks for the NB reference: green screen, asphalt, sidewalk."""
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    green = (g - np.maximum(r, b)) > 30
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    asphalt = ~green & (lum < 140) & (np.abs(r - b) < 30) & (g < r + 20)
    sidewalk = ~green & (lum > 160) & (r > b) & (r < 235)
    return asphalt, sidewalk


def harvest_ref_blocks(im: np.ndarray, mask: np.ndarray, max_std: float):
    """BLOCK^2 windows lying entirely inside `mask` with object-free variance
    (rejects windows touching dashes, joints, or the curb lines)."""
    blocks = []
    h, w = mask.shape
    for y in range(0, h - BLOCK, 4):
        for x in range(0, w - BLOCK, 4):
            if not mask[y : y + BLOCK, x : x + BLOCK].all():
                continue
            rgb = im[y : y + BLOCK, x : x + BLOCK]
            if rgb.std(axis=(0, 1)).mean() > max_std:
                continue
            blocks.append(rgb)
    return blocks


def quilt_texture(blocks, target, seed: int) -> np.ndarray:
    """Seamless TEX_SIZE^2 texture: blocks mean-shifted to `target` (flattens
    the ref's lighting gradient), pasted wrap-around with feathered blending."""
    if len(blocks) < 8:
        raise SystemExit(f"only {len(blocks)} texture blocks; loosen tolerances")
    rng = random.Random(seed)
    canvas = np.zeros((TEX_SIZE, TEX_SIZE, 3), dtype=np.float64)
    weight = np.zeros((TEX_SIZE, TEX_SIZE, 1), dtype=np.float64)
    edge = np.minimum(np.arange(BLOCK), np.arange(BLOCK)[::-1]) + 1.0
    feather = np.minimum.outer(edge, edge).reshape(BLOCK, BLOCK, 1)

    def paste(x0, y0):
        b = blocks[rng.randrange(len(blocks))].copy()
        if rng.random() < 0.5:
            b = b[:, ::-1]
        if rng.random() < 0.5:
            b = b[::-1]
        b = b - b.mean(axis=(0, 1)) + target
        xs = (np.arange(BLOCK) + x0) % TEX_SIZE
        ys = (np.arange(BLOCK) + y0) % TEX_SIZE
        canvas[np.ix_(ys, xs)] += b * feather
        weight[np.ix_(ys, xs)] += feather

    # One systematic pass guarantees full coverage (stride < block size)...
    for y0 in range(0, TEX_SIZE, BLOCK - 3):
        for x0 in range(0, TEX_SIZE, BLOCK - 3):
            paste(x0, y0)
    # ...then random pastes break up the grid's regularity.
    for _ in range(TEX_SIZE * TEX_SIZE // 16):
        paste(rng.randrange(TEX_SIZE), rng.randrange(TEX_SIZE))
    return (canvas / weight).clip(0, 255)


def lowfreq_field(seed: int, lattice: int = 6, amp: float = 0.05) -> np.ndarray:
    """Tileable low-frequency multiplier field (NB asphalt has soft cloudy
    tonal variation that block quilting flattens out — this restores it)."""
    rng = np.random.default_rng(seed)
    knots = rng.uniform(-1.0, 1.0, (lattice, lattice))
    t = np.arange(TEX_SIZE) * lattice / TEX_SIZE
    i0 = t.astype(int)
    f = t - i0
    f = f * f * (3 - 2 * f)  # smoothstep
    i1 = (i0 + 1) % lattice
    top = (
        knots[np.ix_(i0, i0)] * np.outer(1 - f, 1 - f)
        + knots[np.ix_(i0, i1)] * np.outer(1 - f, f)
        + knots[np.ix_(i1, i0)] * np.outer(f, 1 - f)
        + knots[np.ix_(i1, i1)] * np.outer(f, f)
    )
    return 1.0 + amp * top[..., None]


def build_textures():
    if not STYLE_REF.exists():
        raise SystemExit(f"missing style reference {STYLE_REF}")
    im = np.array(Image.open(STYLE_REF).convert("RGB"), dtype=np.float32)
    asphalt_mask, sidewalk_mask = _ref_masks(im)
    asphalt_target = np.median(im[asphalt_mask].reshape(-1, 3), axis=0)
    sidewalk_target = np.median(im[sidewalk_mask].reshape(-1, 3), axis=0)
    asphalt = quilt_texture(
        harvest_ref_blocks(im, asphalt_mask, max_std=9.0), asphalt_target, seed=11
    ) * lowfreq_field(seed=21, amp=0.06)
    sidewalk = quilt_texture(
        harvest_ref_blocks(im, sidewalk_mask, max_std=9.0), sidewalk_target, seed=12
    ) * lowfreq_field(seed=22, amp=0.03)
    return asphalt.clip(0, 255), sidewalk.clip(0, 255)


# --- Roadway signed-distance functions (top-down meter space) ----------------
# sdf <= 0 inside the asphalt. Arms reach past the tile so the overscan rim
# continues them. Directions: +x exits the screen-lower-right edge, +y the
# screen-lower-left edge (grid col/row axes).


def sd_arm(x, y, d):
    """Half-band from tile center to the edge in direction d in {px,nx,py,ny}."""
    if d == "px":
        return np.maximum(np.abs(y - 5) - ROAD_HALF, 5 - x)
    if d == "nx":
        return np.maximum(np.abs(y - 5) - ROAD_HALF, x - 5)
    if d == "py":
        return np.maximum(np.abs(x - 5) - ROAD_HALF, 5 - y)
    return np.maximum(np.abs(x - 5) - ROAD_HALF, y - 5)


def sd_arc(x, y, cx, cy):
    """Quarter annulus (radius 5 +/- ROAD_HALF) centered on tile corner."""
    r = np.hypot(x - cx, y - cy)
    return np.abs(r - 5) - ROAD_HALF


def dash_linear(t):
    """Lane-dash on/off along a tile-periodic axis: 1.2m dash / 0.8m gap,
    dash centered on each tile edge so the pattern chains across tiles."""
    return ((t + 0.6) % 2.0) < 1.2


def sd_band(t):
    """Full band through the tile: |t - 5| <= ROAD_HALF (t is x or y)."""
    return np.abs(t - 5) - ROAD_HALF


def variant_fields(name, x, y):
    """Returns (roadway_sdf, dash_mask) for one canonical tile shape.

    Through-directions use full bands, not pairs of half-arms — two opposing
    half-arms meet at sdf == 0 along the tile center, which the gutter pass
    would shade as a phantom road edge."""
    if name == "cross":
        sdf = np.minimum(sd_band(y), sd_band(x))
        dash = (
            (np.abs(y - 5) <= DASH_HALF) & dash_linear(x) & (np.abs(x - 5) > ROAD_HALF)
        ) | (
            (np.abs(x - 5) <= DASH_HALF) & dash_linear(y) & (np.abs(y - 5) > ROAD_HALF)
        )
    elif name == "tee":  # {+x, -x, +y}
        sdf = np.minimum(sd_band(y), sd_arm(x, y, "py"))
        dash = (
            (np.abs(y - 5) <= DASH_HALF) & dash_linear(x) & (np.abs(x - 5) > ROAD_HALF)
        ) | ((np.abs(x - 5) <= DASH_HALF) & dash_linear(y) & (y - 5 > ROAD_HALF))
    elif name == "straight":  # {+x, -x}
        sdf = sd_band(y)
        dash = (np.abs(y - 5) <= DASH_HALF) & dash_linear(x)
    elif name == "curve_ud":  # {+x, +y}: annulus on the (10,10) corner
        sdf = sd_arc(x, y, 10.0, 10.0)
        theta = np.arctan2(10.0 - y, 10.0 - x)  # 0 at +x edge, pi/2 at +y edge
        arc_len = np.clip(theta, 0, math.pi / 2) * 5.0
        period = (math.pi / 2 * 5.0) / round(math.pi / 2 * 5.0 / 2.0)
        dash = (np.abs(np.hypot(x - 10, y - 10) - 5) <= DASH_HALF) & (
            ((arc_len + 0.3 * period) % period) < 0.6 * period
        )
    elif name == "curve_lr":  # {+x, -y}: annulus on the (10,0) corner
        sdf = sd_arc(x, y, 10.0, 0.0)
        theta = np.arctan2(y, 10.0 - x)
        arc_len = np.clip(theta, 0, math.pi / 2) * 5.0
        period = (math.pi / 2 * 5.0) / round(math.pi / 2 * 5.0 / 2.0)
        dash = (np.abs(np.hypot(x - 10, y) - 5) <= DASH_HALF) & (
            ((arc_len + 0.3 * period) % period) < 0.6 * period
        )
    elif name == "deadend":  # {+x}: arm + rounded cap
        sdf = np.minimum(sd_arm(x, y, "px"), np.hypot(x - 5, y - 5) - ROAD_HALF)
        dash = (np.abs(y - 5) <= DASH_HALF) & dash_linear(x) & (x > 6.0)
    else:
        raise ValueError(name)
    return sdf, dash


# --- Tile compositing ---------------------------------------------------------


def compose_tile(name, asphalt_tex, sidewalk_tex):
    w, h = CANVAS_W * SS, CANVAS_H * SS
    uu, vv = np.meshgrid((np.arange(w) + 0.5) / SS, (np.arange(h) + 0.5) / SS)
    # Invert the dimetric projection back to top-down meters.
    a = (uu - CANVAS_W / 2) / PX_PER_M_U  # x - y
    b = (vv - CANVAS_H / 2) / PX_PER_M_V + TILE_M  # x + y
    x, y = (a + b) / 2, (b - a) / 2

    # Tile alpha: opaque inside the diamond, opaque-then-AA through overscan.
    outside = np.maximum.reduce([np.zeros_like(x), -x, x - TILE_M, -y, y - TILE_M])
    alpha = np.clip((OVERSCAN_M - outside) / 0.15, 0.0, 1.0)

    sdf, dash = variant_fields(name, x, y)

    # Sample the quilted textures in *final-resolution* screen space so their
    # grain matches the NB reference's brush scale.
    tex_u = (uu % TEX_SIZE).astype(int)
    tex_v = (vv % TEX_SIZE).astype(int)
    asphalt = asphalt_tex[tex_v, tex_u]
    sidewalk = sidewalk_tex[tex_v, tex_u]

    rgb = sidewalk.copy()

    # Sidewalk slab joints: a tile-periodic x/y grid (8 slabs per tile edge),
    # matching the NB ref's scored-concrete look. Kept off the curb stones.
    joint = (
        (np.abs((x % SLAB_PITCH) - SLAB_PITCH / 2) > SLAB_PITCH / 2 - SLAB_JOINT_HALF)
        | (np.abs((y % SLAB_PITCH) - SLAB_PITCH / 2) > SLAB_PITCH / 2 - SLAB_JOINT_HALF)
    ) & (sdf > CURB_SHADOW_W + CURB_W)
    rgb[joint] = sidewalk[joint] * SLAB_JOINT_GAIN

    # Curb: near-black expansion joint hugging the asphalt, then a lighter
    # stone band (the NB ref's reading of a raised curb).
    curb = (sdf > CURB_SHADOW_W) & (sdf <= CURB_SHADOW_W + CURB_W)
    rgb[curb] = np.clip(sidewalk[curb] * CURB_GAIN, 0, 255)
    shadow = (sdf > 0) & (sdf <= CURB_SHADOW_W)
    rgb[shadow] = sidewalk[shadow] * CURB_SHADOW_GAIN

    road = sdf <= 0
    rgb[road] = asphalt[road]
    gutter = road & (sdf > -GUTTER_W)
    rgb[gutter] = asphalt[gutter] * GUTTER_GAIN
    on_dash = dash & (sdf <= -GUTTER_W)
    rgb[on_dash] = rgb[on_dash] * 0.15 + DASH_COLOR * 0.85

    out = np.dstack([rgb, alpha * 255.0]).astype(np.uint8)
    return Image.fromarray(out).resize((CANVAS_W, CANVAS_H), Image.LANCZOS)


SHAPES = ["cross", "tee", "straight", "curve_ud", "curve_lr", "deadend"]


def main():
    asphalt, sidewalk = build_textures()
    tiles = {}
    for name in SHAPES:
        img = compose_tile(name, asphalt, sidewalk)
        path = ASSETS / f"road_{name}.png"
        img.save(path)
        tiles[name] = img
        print(f"wrote {path.relative_to(ROOT)}")

    if "--preview" in sys.argv:
        zoom = 3
        sheet = Image.new(
            "RGBA", (CANVAS_W * zoom * 3, CANVAS_H * zoom * 2), (124, 179, 66, 255)
        )
        for i, name in enumerate(SHAPES):
            tile = tiles[name].resize((CANVAS_W * zoom, CANVAS_H * zoom), Image.NEAREST)
            sheet.alpha_composite(
                tile, ((i % 3) * CANVAS_W * zoom, (i // 3) * CANVAS_H * zoom)
            )
        sheet.save("/tmp/road_tiles_preview.png")
        print("wrote /tmp/road_tiles_preview.png")


if __name__ == "__main__":
    main()
