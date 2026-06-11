#!/usr/bin/env python3
"""Process a raw Nano Banana sprite into a game-ready building asset.

Usage:
  python3 tools/sprite_pipeline/process.py <raw_png_path> [<raw_png_path> ...]

Reads tools/sprite_pipeline/raw/<id>_v<n>.png, removes the green
background with rembg, crops to the non-transparent bounding box,
resizes to fit the building's per-footprint canvas (footprint looked up
from city_builder.md §3), and saves the result to
assets/buildings/<id>_v<n>.png. Also emits a debug overlay PNG with the
tile-diamond outlined over the sprite for visual QA at
tools/sprite_pipeline/debug/<id>_v<n>.png.

Requires: Pillow, rembg, and pngquant on PATH (pngquant optional — a
warning is printed and the uncompressed PNG is kept if it's missing).
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from rembg import remove
from scipy import ndimage

# Match the Flame iso renderer (lib/game/city/iso_grid.dart): world tile
# diamond is 64 wide, max camera zoom is 3, so authoring at 192 px / tile
# yields sharp output at every supported zoom level.
TILE_W = 192
TILE_H = TILE_W // 2  # 2:1 dimetric — diamond bounding box is W x W/2

# Extra height above the lot diamond, expressed as a multiplier of the
# diamond's pixel height. Covers building height + any flags/spires; the
# canvas auto-extends further if the resized sprite needs more room.
TOWER_HEADROOM = 1.5

# The grid is a true 2:1 dimetric diamond. Nano Banana draws a slightly
# steeper isometric (its ground diamonds measure ~1.8:1), so a sprite scaled
# to fill the footprint width ends up ~10% too tall and its base edges cross
# the tile edges instead of running along them. We measure each sprite's own
# ground-diamond aspect (from its south/east/west opaque tips) and squash it
# vertically to land a true 2:1 base on the tile. Clamped so a stray pixel
# (a flag, an overhanging branch) can't produce a wild correction.
# A pixel counts as Nano Banana backdrop-green when its green channel exceeds
# both red and blue by this margin. Shade-independent (works whatever exact
# green the export used); cleanly excludes gray plaza / tan stone / brick,
# which have G ≈ R ≈ B.
GREEN_MARGIN = 30

# A pixel this opaque counts as solid ground/building when bleeding the base
# out to the footprint edges (everything less opaque inside the footprint gets
# filled from the nearest solid pixel).
FILL_SOLID_ALPHA = 250

# Disconnected opaque islands smaller than this fraction of the largest one
# are dropped as noise: when a raw export's backdrop is noisy/textured, the
# non-green protection in remove_green_bg keeps the not-green-enough flecks,
# leaving speckles floating around the building. Real detached props are
# orders of magnitude larger than flecks.
DESPECKLE_MIN_FRACTION = 0.03

TARGET_GROUND_ASPECT = 2.0
# Use only solidly-opaque pixels when locating the ground tips, so a faint
# rembg halo / drop shadow doesn't get mistaken for the plaza corner.
SILHOUETTE_CUTOFF = 128
# Only trust a measured aspect that lands in a plausible isometric range;
# outside it the tip detection has almost certainly latched onto a tree or
# overhang, so fall back to the measured-typical NB projection (~1.8:1 → 0.9).
PLAUSIBLE_ASPECT = (1.6, 2.0)
DEFAULT_SQUASH = 0.90
MIN_SQUASH = 0.80

REPO_ROOT = Path(__file__).resolve().parents[2]
CITY_BUILDER_MD = REPO_ROOT / "city_builder.md"
ASSETS_DIR = REPO_ROOT / "assets" / "buildings"
DEBUG_DIR = REPO_ROOT / "tools" / "sprite_pipeline" / "debug"

# Rows gain a leading "✅ " once wired (tools/city_builder/sync_implementation_status.py).
ID_RE = re.compile(r"^(?:✅ )?`(\w+)`")
DIM_RE = re.compile(r"(\d+)×(\d+)")
SEP_CHARS = set("-:| ")
# Accept raw outputs as <id>.<ext>, <id>_<n>.<ext>, or <id>_v<n>.<ext> with
# ext in {png, jpg, jpeg}. A bare singleton (no number) is variant 1. The
# building id is matched greedily against the known §3 ids in
# building_id_and_variant(), so multi-underscore ids like `coffee_shop`
# aren't split on their internal underscore.
FILENAME_RE = re.compile(r"^(?P<stem>\w+?)(?:_v?(?P<n>\d+))?\.(?:png|jpe?g)$", re.IGNORECASE)


def parse_footprints() -> dict[str, tuple[int, int]]:
    """Parse city_builder.md §3.x tables → {building_id: (w_tiles, h_tiles)}."""
    md = CITY_BUILDER_MD.read_text(encoding="utf-8")
    out: dict[str, tuple[int, int]] = {}
    in_catalog = False
    foot_col: int | None = None

    for line in md.splitlines():
        if line.startswith("## "):
            in_catalog = line.startswith("## 3.")
            foot_col = None
            continue
        if not in_catalog:
            continue
        if line.startswith("### 3.5"):
            in_catalog = False
            continue
        if not line.startswith("|"):
            continue
        if set(line.strip()) <= SEP_CHARS:
            continue

        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if "Building" in cells and "Foot" in cells:
            foot_col = cells.index("Foot")
            continue
        if foot_col is None or len(cells) <= foot_col:
            continue

        m_id = ID_RE.match(cells[0])
        m_dim = DIM_RE.search(cells[foot_col])
        if not (m_id and m_dim):
            continue
        out[m_id.group(1)] = (int(m_dim.group(1)), int(m_dim.group(2)))

    return out


def building_id_and_variant(path: Path) -> tuple[str, int]:
    """(<id>, <variant>) from a raw filename. Bare singleton → variant 1."""
    m = FILENAME_RE.match(path.name)
    if not m:
        raise ValueError(
            f"filename {path.name!r} does not match <id>[_<n>].(png|jpg|jpeg)"
        )
    return m.group("stem"), int(m.group("n")) if m.group("n") else 1


def canvas_size(w_tiles: int, h_tiles: int) -> tuple[int, int, int]:
    """Return (canvas_w, base_canvas_h, diamond_h) for a footprint."""
    canvas_w = (w_tiles + h_tiles) * TILE_W // 2
    diamond_h = (w_tiles + h_tiles) * TILE_H // 2
    canvas_h = diamond_h + int(diamond_h * TOWER_HEADROOM)
    return canvas_w, canvas_h, diamond_h


def remove_green_bg(raw: Image.Image) -> Image.Image:
    """Matte out the green Nano Banana backdrop, protecting non-green ground.

    rembg's ML matte is the only thing that reliably separates *green*
    foreground (trees, lawn, hedges) from the matching green backdrop — a
    plain colour key can't, since foliage and screen are the same green. But
    rembg sometimes over-removes a building's flat gray plaza as 'ground'.
    Since the only true background here is the green screen, any pixel that
    isn't backdrop-green is foreground by definition, so we force it opaque;
    green pixels are left to rembg (backdrop dropped, foliage kept).
    """
    cut = np.asarray(remove(raw))  # rembg RGBA, soft alpha
    rgb = np.asarray(raw.convert("RGB")).astype(np.int16)
    greenish = (rgb[..., 1] - np.maximum(rgb[..., 0], rgb[..., 2])) > GREEN_MARGIN
    alpha = cut[..., 3].copy()
    alpha[~greenish] = 255  # non-green is never the green screen → keep it
    out = np.dstack([rgb.astype(np.uint8), alpha.astype(np.uint8)])
    return Image.fromarray(out, "RGBA")


def despeckle(img: Image.Image) -> Image.Image:
    """Drop tiny disconnected opaque islands (noisy-backdrop residue).

    Speckles also inflate the bounding-box crop and pull the ground-tip
    detection off the real silhouette, so this must run before either.
    """
    arr = np.array(img)
    labels, n = ndimage.label(arr[..., 3] > 0, structure=np.ones((3, 3)))
    if n <= 1:
        return img
    sizes = np.bincount(labels.ravel())
    sizes[0] = 0
    keep = sizes >= sizes.max() * DESPECKLE_MIN_FRACTION
    keep[0] = False
    arr[..., 3][~keep[labels]] = 0
    return Image.fromarray(arr, "RGBA")


def ground_squash(img: Image.Image) -> tuple[float, float | None]:
    """Vertical squash to bring this sprite's ground diamond to a true 2:1.

    Returns `(squash, measured_aspect)` (`measured_aspect` is None if the
    silhouette was empty). The ground diamond is read from the solidly-opaque
    silhouette's south (lowest), west (leftmost) and east (rightmost) tips:
    `aspect = width / (2 · south→E/W rise)`. When that lands in a plausible
    isometric range we squash by `aspect / 2.0`; otherwise the detection has
    latched onto a tree/overhang and we fall back to [DEFAULT_SQUASH]. Applied
    as a height multiplier on top of the uniform width fit.
    """
    op = np.asarray(img)[..., 3] > SILHOUETTE_CUTOFF
    cols = np.where(op.any(axis=0))[0]
    rows = np.where(op.any(axis=1))[0]
    if len(cols) == 0 or len(rows) == 0:
        return DEFAULT_SQUASH, None
    xmin, xmax, ymax = int(cols[0]), int(cols[-1]), int(rows[-1])
    y_w = float(np.median(np.where(op[:, xmin])[0]))
    y_e = float(np.median(np.where(op[:, xmax])[0]))
    width = xmax - xmin
    rise = ymax - (y_w + y_e) / 2
    if rise <= 1 or width <= 1:
        return DEFAULT_SQUASH, None
    aspect = width / (2 * rise)
    lo, hi = PLAUSIBLE_ASPECT
    if not (lo <= aspect <= hi):
        return DEFAULT_SQUASH, aspect
    return max(MIN_SQUASH, min(1.0, aspect / TARGET_GROUND_ASPECT)), aspect


def fill_footprint_gaps(
    img: Image.Image, w_tiles: int, h_tiles: int
) -> Image.Image:
    """Bleed the building's ground out to the footprint-diamond edges.

    After the squash the painted plaza nearly fills its 2:1 footprint, but the
    base outline is irregular (entrance recesses, planters, the lawn edge), so
    thin transparent wedges remain *inside* the tile and the terrain shows
    through. For every not-fully-opaque pixel inside the footprint diamond, copy
    the colour of the nearest solid pixel and set alpha to 255, so the ground
    meets the tile edges with no seam. Mirrors [_draw_diamond]'s geometry: a
    full-width 2:1 diamond with its south corner at the canvas bottom-centre.
    """
    arr = np.array(img)
    h, w = arr.shape[:2]
    alpha = arr[..., 3]

    # The footprint is a w_tiles x h_tiles iso parallelogram (a diamond only
    # when square — issue #90). Inverse-project each pixel into footprint
    # tile coordinates and test the rectangle there. North corner sits at
    # x = h_tiles * TILE_W/2 from the canvas left, diamond top edge at the
    # bottom of the canvas's diamond band.
    diamond_h = (w_tiles + h_tiles) * TILE_H // 2
    nx = h_tiles * TILE_W / 2
    ny = h - diamond_h
    ys, xs = np.mgrid[0:h, 0:w]
    dx = (xs - nx) / (TILE_W / 2)
    dy = (ys - ny) / (TILE_H / 2)
    c = (dx + dy) / 2  # tile-space col axis (screen lower-right)
    r = (dy - dx) / 2  # tile-space row axis (screen lower-left)
    inside = (c >= 0) & (c <= w_tiles) & (r >= 0) & (r <= h_tiles)

    solid = alpha >= FILL_SOLID_ALPHA
    gap = inside & ~solid
    if not gap.any() or not solid.any():
        return img
    _, (iy, ix) = ndimage.distance_transform_edt(~solid, return_indices=True)
    arr[..., :3][gap] = arr[..., :3][iy[gap], ix[gap]]
    arr[..., 3][gap] = 255
    return Image.fromarray(arr, "RGBA")


def process(
    raw_path: Path,
    footprints: dict[str, tuple[int, int]],
    squash_override: float | None = None,
    footprint_override: tuple[int, int] | None = None,
) -> Path:
    building_id, variant = building_id_and_variant(raw_path)
    out_name = f"{building_id}_v{variant}.png"
    if footprint_override is not None:
        w_tiles, h_tiles = footprint_override
    elif building_id in footprints:
        w_tiles, h_tiles = footprints[building_id]
    else:
        raise ValueError(
            f"no footprint for {building_id!r} in city_builder.md §3 "
            f"(known: {sorted(footprints)[:5]}…)"
        )
    canvas_w, base_canvas_h, diamond_h = canvas_size(w_tiles, h_tiles)

    raw = Image.open(raw_path).convert("RGBA")
    cut = despeckle(remove_green_bg(raw))
    bbox = cut.getbbox()
    if bbox is None:
        raise ValueError(f"{raw_path.name}: no opaque pixels after rembg")
    cropped = cut.crop(bbox)

    # Resize so cropped width fills the canvas width, then squash vertically so
    # the building's ground diamond is a true 2:1 that sits on the tile.
    squash, aspect = ground_squash(cropped)
    if squash_override is not None:
        squash = squash_override
    new_w = canvas_w
    new_h = round(cropped.height * canvas_w / cropped.width * squash)
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    lo, hi = PLAUSIBLE_ASPECT
    measured = "n/a" if aspect is None else f"{aspect:.2f}:1"
    note = "" if (aspect is not None and lo <= aspect <= hi) else "  [default]"
    print(
        f"  {raw_path.name}: ground aspect {measured} → squash ×{squash:.3f}{note}",
        file=sys.stderr,
    )

    # Final canvas height grows if the resized sprite is taller than headroom.
    canvas_h = max(base_canvas_h, new_h)
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    paste_x = (canvas_w - new_w) // 2
    paste_y = canvas_h - new_h
    canvas.paste(resized, (paste_x, paste_y), resized)
    canvas = fill_footprint_gaps(canvas, w_tiles, h_tiles)

    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    out_path = ASSETS_DIR / out_name
    canvas.save(out_path, "PNG", optimize=True)
    _maybe_pngquant(out_path)

    DEBUG_DIR.mkdir(parents=True, exist_ok=True)
    debug = canvas.copy()
    _draw_diamond(debug, w_tiles, h_tiles)
    debug.save(DEBUG_DIR / out_name, "PNG")

    return out_path


def _maybe_pngquant(path: Path) -> None:
    try:
        subprocess.run(
            [
                "pngquant",
                "--quality=70-95",
                "--force",
                "--ext=.png",
                "--skip-if-larger",
                str(path),
            ],
            check=True,
            capture_output=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError) as e:
        msg = e.stderr.decode().strip() if hasattr(e, "stderr") and e.stderr else str(e)
        print(f"warning: pngquant skipped for {path.name}: {msg}", file=sys.stderr)


def _draw_diamond(img: Image.Image, w_tiles: int, h_tiles: int) -> None:
    # True iso footprint quad: a parallelogram-cornered diamond when the
    # footprint is rectangular (issue #90), the familiar diamond when square.
    draw = ImageDraw.Draw(img, "RGBA")
    diamond_h = (w_tiles + h_tiles) * TILE_H // 2
    ny = img.height - diamond_h
    north = (h_tiles * TILE_W // 2, ny)
    # Corners via the +col (TILE_W/2, TILE_H/2) and +row (-TILE_W/2, TILE_H/2)
    # tile axes from the north corner.
    east = (north[0] + w_tiles * TILE_W // 2, ny + w_tiles * TILE_H // 2)
    south = (
        north[0] + (w_tiles - h_tiles) * TILE_W // 2,
        ny + (w_tiles + h_tiles) * TILE_H // 2 - 1,
    )
    west = (north[0] - h_tiles * TILE_W // 2, ny + h_tiles * TILE_H // 2)
    draw.polygon([south, east, north, west], outline=(255, 0, 0, 220), width=3)


def main() -> None:
    args = sys.argv[1:]
    squash_override: float | None = None
    footprint_override: tuple[int, int] | None = None
    paths: list[Path] = []
    for arg in args:
        # Manual overrides for outlier raws (e.g. NB drew a flat ground object
        # near-top-down instead of 2:1 dimetric): --squash=0.6 --footprint=4x4
        if arg.startswith("--squash="):
            squash_override = float(arg.split("=", 1)[1])
        elif arg.startswith("--footprint="):
            w, h = arg.split("=", 1)[1].lower().split("x")
            footprint_override = (int(w), int(h))
        else:
            paths.append(Path(arg))
    if not paths:
        print(
            f"usage: {sys.argv[0]} [--squash=F] [--footprint=WxH] <raw_png> [...]",
            file=sys.stderr,
        )
        sys.exit(1)
    footprints = parse_footprints()
    for raw_path in paths:
        if not raw_path.exists():
            print(f"error: {raw_path} not found", file=sys.stderr)
            sys.exit(1)
        out = process(raw_path, footprints, squash_override, footprint_override)
        print(f"{raw_path.name} → {out.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
