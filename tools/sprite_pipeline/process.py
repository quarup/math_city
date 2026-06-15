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

import math
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

# A rectangular sprite whose drawn footprint is transposed relative to the
# requested W×H (Nano Banana frequently swaps the two — drawing a 3×2 field as
# 2×3) is corrected with a horizontal flip: in 2:1 dimetric a left-right mirror
# swaps the two ground-plane axes (+col ⇄ +row), so it turns an H×W drawing into
# the W×H we asked for without changing the south-corner anchor. Only triggered
# when the measured long axis sits on the *opposite* diagonal and the drawn
# aspect departs from square by at least this ratio (keeps near-square
# measurement noise from flipping a correctly-drawn sprite).
FLIP_MIN_RATIO = 1.15

# Affine ground-fit: Nano Banana doesn't reliably honour the requested ratio
# (it draws 3.8:1 for 4:1) or a clean 2:1 projection angle. Rather than only
# squashing vertically, we map the drawn ground plate's three visible corners
# (west / south / east tips) onto the exact dimetric footprint corners with a
# 2D affine — correcting ratio *and* angle in one warp. The fourth (north)
# corner is occluded by the building, but three points fully determine an
# affine. It's trustworthy only when those tips really are the ground corners:
# on a tall building the extreme pixels are the roof/overhang, not the base. We
# gate on the two front edges' slopes (a true 2:1 base edge has slope 0.5); if
# either falls outside this range the tips are foliage/roof and we fall back to
# the vertical-squash path. The warp is vertical-preserving (see
# [_vertical_preserving_affine]) so walls don't lean; the only residual is the
# south apex's horizontal position when the drawn apex is off-centre.
AFFINE_SLOPE_RANGE = (0.30, 0.95)

# PIL's affine transform has no area filter, so warping the large raw straight
# down to the ~hundreds-of-px canvas aliases. We instead warp at roughly source
# resolution (so the warp isn't downscaling) and then LANCZOS-resize down,
# preserving detail. This caps the larger supersampled dimension so the
# intermediate stays bounded for big footprints.
SUPERSAMPLE_MAX = 2000

# The affine only fills the footprint cleanly when the building's *drawn*
# proportions roughly match the requested footprint. When they don't (Nano
# Banana drew a near-square bakery but §3 asks for 1×2), forcing the fit
# stretches one ground axis far more than the other and the building reads as
# squished/elongated. If the two axes' scale factors differ by more than this,
# the footprint disagrees with the art — fall back to the proportion-preserving
# squash (and the §3 footprint likely wants reconciling to the sprite).
AFFINE_MAX_ANISOTROPY = 1.4

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


def _ground_tips(img: Image.Image) -> tuple[int, int, int, float, float] | None:
    """`(xmin, xmax, ymax, y_w, y_e)` of the solidly-opaque silhouette.

    `xmin`/`xmax` are the west/east tip columns, `ymax` the south tip row, and
    `y_w`/`y_e` the median opaque rows in the west/east tip columns. None if the
    silhouette is empty. Shared by [ground_squash] and [needs_horizontal_flip].
    """
    op = np.asarray(img)[..., 3] > SILHOUETTE_CUTOFF
    cols = np.where(op.any(axis=0))[0]
    rows = np.where(op.any(axis=1))[0]
    if len(cols) == 0 or len(rows) == 0:
        return None
    xmin, xmax, ymax = int(cols[0]), int(cols[-1]), int(rows[-1])
    y_w = float(np.median(np.where(op[:, xmin])[0]))
    y_e = float(np.median(np.where(op[:, xmax])[0]))
    return xmin, xmax, ymax, y_w, y_e


def needs_horizontal_flip(
    img: Image.Image, w_tiles: int, h_tiles: int
) -> tuple[bool, float | None]:
    """Whether to mirror the sprite so its drawn footprint matches `w×h`.

    Returns `(flip, drawn_ratio)`. Measures the drawn ground plate's two edges
    from the south tip: south→west runs along the +col axis (∝ drawn width),
    south→east along the +row axis (∝ drawn depth). The ratio of their lengths
    is the drawn W:H — squash-independent, since both axes share the same
    vertical rise per tile. If the requested footprint's long axis is on the
    *opposite* diagonal (one ratio >1, the other <1) by at least
    [FLIP_MIN_RATIO], Nano Banana drew it transposed and a horizontal flip
    fixes it. Square footprints (`w == h`) are never flipped — the orientation
    is unobservable and a flip would be a no-op on the seating anyway.
    """
    if w_tiles == h_tiles:
        return False, None
    tips = _ground_tips(img)
    if tips is None:
        return False, None
    xmin, xmax, ymax, y_w, y_e = tips
    op = np.asarray(img)[..., 3] > SILHOUETTE_CUTOFF
    south_cols = np.where(op[ymax])[0]
    if len(south_cols) == 0:
        return False, None
    x_s = float(np.median(south_cols))
    d_w = math.hypot(x_s - xmin, ymax - y_w)  # south→west tip, ∝ drawn width
    d_h = math.hypot(xmax - x_s, ymax - y_e)  # south→east tip, ∝ drawn depth
    if d_w <= 1 or d_h <= 1:
        return False, None
    drawn = d_w / d_h
    requested = w_tiles / h_tiles
    if (requested > 1) == (drawn > 1):
        return False, drawn  # same diagonal already — nothing to fix
    return max(drawn, 1 / drawn) >= FLIP_MIN_RATIO, drawn


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
    tips = _ground_tips(img)
    if tips is None:
        return DEFAULT_SQUASH, None
    xmin, xmax, ymax, y_w, y_e = tips
    width = xmax - xmin
    rise = ymax - (y_w + y_e) / 2
    if rise <= 1 or width <= 1:
        return DEFAULT_SQUASH, None
    aspect = width / (2 * rise)
    lo, hi = PLAUSIBLE_ASPECT
    if not (lo <= aspect <= hi):
        return DEFAULT_SQUASH, aspect
    return max(MIN_SQUASH, min(1.0, aspect / TARGET_GROUND_ASPECT)), aspect


# Cached seamless sidewalk texture (the same NB-quilted concrete the road tiles
# use), so the gap fill blends into adjacent sidewalks instead of smearing the
# nearest building pixel. None once we've found it unbuildable (missing style
# ref) — then we fall back to the nearest-pixel bleed.
_SIDEWALK_TEX: np.ndarray | None = None
_SIDEWALK_TRIED = False


def _sidewalk_texture() -> np.ndarray | None:
    """The road sidewalk texture as a `TEX×TEX×3` uint8 array, or None."""
    global _SIDEWALK_TEX, _SIDEWALK_TRIED
    if _SIDEWALK_TRIED:
        return _SIDEWALK_TEX
    _SIDEWALK_TRIED = True
    try:
        import compose_roads  # sibling module; sys.path[0] is this dir

        _, sidewalk = compose_roads.build_textures()
        _SIDEWALK_TEX = sidewalk.clip(0, 255).astype(np.uint8)
    except Exception as e:  # noqa: BLE001 - any failure → graceful fallback
        print(
            f"warning: sidewalk texture unavailable ({e}); "
            "filling footprint gaps by nearest-pixel bleed",
            file=sys.stderr,
        )
        _SIDEWALK_TEX = None
    return _SIDEWALK_TEX


def fill_footprint_gaps(
    img: Image.Image, w_tiles: int, h_tiles: int
) -> Image.Image:
    """Fill the footprint-diamond gaps around the building with sidewalk.

    The affine/squash fit lands the building's base on its 2:1 footprint, but
    the base outline is irregular (entrance recesses, planters, the lawn edge),
    so thin transparent wedges remain *inside* the tile and the terrain shows
    through. We fill them with the same NB-quilted sidewalk texture the road
    tiles use — sampled in screen space so its grain lines up with adjacent
    sidewalks — and composite the building's anti-aliased edge *over* it so
    there's no hard seam. Falls back to a nearest-solid-pixel bleed if the
    texture can't be built. Mirrors [_draw_diamond]'s geometry: a full-width
    2:1 diamond with its south corner at the canvas bottom-centre.
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

    tex = _sidewalk_texture()
    gy, gx = np.where(gap)
    if tex is not None:
        th, tw = tex.shape[:2]
        swk = tex[gy % th, gx % tw].astype(np.float32)
        # Composite the building's own (partial) pixel over the sidewalk so the
        # AA edge feathers into the pavement; fully-transparent gaps → pure
        # sidewalk (their garbage RGB is multiplied out by a≈0).
        a = (alpha[gy, gx].astype(np.float32) / 255.0)[:, None]
        bld = arr[gy, gx, :3].astype(np.float32)
        arr[gy, gx, :3] = (bld * a + swk * (1 - a)).astype(np.uint8)
        arr[gy, gx, 3] = 255
    else:
        _, (iy, ix) = ndimage.distance_transform_edt(~solid, return_indices=True)
        arr[..., :3][gap] = arr[..., :3][iy[gap], ix[gap]]
        arr[..., 3][gap] = 255
    return Image.fromarray(arr, "RGBA")


def _diamond_corners(
    canvas_h: float, w_tiles: int, h_tiles: int
) -> dict[str, tuple[float, float]]:
    """W/S/E/N corners of the footprint diamond in canvas coords.

    Same geometry as [_draw_diamond]: a 2:1 dimetric parallelogram whose south
    corner sits at the canvas bottom, north at `h·TILE_W/2` from the left.
    """
    diamond_h = (w_tiles + h_tiles) * TILE_H / 2
    ny = canvas_h - diamond_h
    nx = h_tiles * TILE_W / 2
    return {
        "n": (nx, ny),
        "e": (nx + w_tiles * TILE_W / 2, ny + w_tiles * TILE_H / 2),
        "s": (
            nx + (w_tiles - h_tiles) * TILE_W / 2,
            ny + (w_tiles + h_tiles) * TILE_H / 2,
        ),
        "w": (nx - h_tiles * TILE_W / 2, ny + h_tiles * TILE_H / 2),
    }


def ground_corners(
    img: Image.Image,
) -> dict[str, tuple[float, float]] | None:
    """Drawn W/S/E ground tips of the silhouette, or None if implausible.

    W = west tip `(xmin, y_w)`, E = east tip `(xmax, y_e)`, S = south tip
    `(x_s, ymax)`. Returns None unless they form a downward "V" (S strictly
    below and between W and E) whose two front edges have slopes in
    [AFFINE_SLOPE_RANGE] — the signature of a real 2:1 ground plate rather than
    a roof/overhang the affine can't trust.
    """
    tips = _ground_tips(img)
    if tips is None:
        return None
    xmin, xmax, ymax, y_w, y_e = tips
    op = np.asarray(img)[..., 3] > SILHOUETTE_CUTOFF
    south_cols = np.where(op[ymax])[0]
    if len(south_cols) == 0:
        return None
    x_s = float(np.median(south_cols))
    if not (xmin < x_s < xmax and ymax > y_w and ymax > y_e):
        return None
    lo, hi = AFFINE_SLOPE_RANGE
    m_left = (ymax - y_w) / (x_s - xmin)
    m_right = (ymax - y_e) / (xmax - x_s)
    if not (lo <= m_left <= hi and lo <= m_right <= hi):
        return None
    return {
        "w": (float(xmin), y_w),
        "s": (x_s, float(ymax)),
        "e": (float(xmax), y_e),
        "_slopes": (m_left, m_right),
    }


def _affine_anisotropy(
    corners: dict[str, tuple[float, float]], w_tiles: int, h_tiles: int
) -> float:
    """How unevenly the affine would scale the two ground axes (≥ 1.0).

    The drawn front-edge lengths are S→W (∝ drawn width) and S→E (∝ drawn
    depth); the target lengths are proportional to `w_tiles` and `h_tiles`. The
    ratio of the two per-axis scale factors (folded to ≥ 1) measures how much
    the footprint stretches the building out of its drawn proportions.
    """
    xw, yw = corners["w"]
    xs, ys = corners["s"]
    xe, ye = corners["e"]
    d_left = math.hypot(xs - xw, ys - yw)
    d_right = math.hypot(xe - xs, ye - ys)
    if d_left <= 0 or d_right <= 0:
        return 1.0
    # scale_left ∝ w/d_left, scale_right ∝ h/d_right → ratio = (w·d_right)/(h·d_left)
    ratio = (w_tiles * d_right) / (h_tiles * d_left)
    return max(ratio, 1 / ratio)


def _vertical_preserving_affine(
    src: list[tuple[float, float]], dst: list[tuple[float, float]]
) -> tuple[
    tuple[float, float, float, float, float, float],
    tuple[float, float, float, float, float],
]:
    """PIL AFFINE coeffs (output→input) that fit the ground without shearing.

    `src`/`dst` are the drawn and target `[W, S, E]` ground tips. A full
    3-point affine would land all three exactly but shear the building's
    vertical walls when the drawn ground angle/ratio is off. Instead:

    - **Horizontal** — a pure scale `xout = p·xin + r` pinned to the W/E tips
      (correct width and side-corner positions). No `y` term, so input vertical
      lines stay vertical (walls don't lean).
    - **Vertical** — `yout = s·xin + t·yin + u` solved to hit all three
      corners' heights exactly, giving the ground its correct 2:1 edge slopes
      and depth.

    With only 2 horizontal DOF you can pin the width + one x-position; we pin
    the W/E side tips (so the footprint's left/right corners sit exactly). When
    the drawn ground's apex sits at a different horizontal fraction than the
    footprint wants (Nano Banana draws a near-symmetric base but a non-square
    footprint's apex is off-centre), the residual shows as the south apex
    shifting a little — subtler than mislanded side corners or sheared walls.
    Returns the PIL coeffs and the forward `(p, r, s, t, u)`.
    """
    (x_w, y_w), (x_s, y_s), (x_e, y_e) = src
    (xw_t, yw_t), (xs_t, ys_t), (xe_t, ye_t) = dst
    p = (xe_t - xw_t) / (x_e - x_w)
    r = xw_t - p * x_w
    m = np.array([[x_w, y_w, 1.0], [x_s, y_s, 1.0], [x_e, y_e, 1.0]])
    s, t, u = (float(v) for v in np.linalg.solve(m, np.array([yw_t, ys_t, ye_t])))
    # Invert the forward map (xout = p·xin+r, yout = s·xin+t·yin+u) for PIL's
    # output→input sampling: xin = a·xout+b·yout+c, yin = d·xout+e·yout+f.
    coeffs = (
        1.0 / p,
        0.0,
        -r / p,
        -s / (t * p),
        1.0 / t,
        (s * r) / (t * p) - u / t,
    )
    return coeffs, (p, r, s, t, u)


def place_via_affine(
    cropped: Image.Image,
    corners: dict[str, tuple[float, float]],
    w_tiles: int,
    h_tiles: int,
    base_canvas_h: int,
    canvas_w: int,
) -> Image.Image:
    """Warp `cropped` so its ground tips land on the footprint (verticals kept).

    Grows the canvas upward first so a tall building's top isn't clipped (the
    south corner stays pinned to the canvas bottom, where the renderer expects
    it). The forward map's translation rises with `canvas_h`, so one recompute
    converges.
    """
    src = [corners["w"], corners["s"], corners["e"]]
    w, h = cropped.size
    in_corners = [(0.0, 0.0), (w, 0.0), (0.0, h), (w, h)]

    canvas_h = float(base_canvas_h)
    for _ in range(3):
        tgt = _diamond_corners(canvas_h, w_tiles, h_tiles)
        dst = [tgt["w"], tgt["s"], tgt["e"]]
        _, (_p, _r, s, t, u) = _vertical_preserving_affine(src, dst)
        top = min(s * x + t * y + u for x, y in in_corners)  # input→output y
        need = base_canvas_h + max(0.0, -top) + 4
        if abs(need - canvas_h) < 1:
            break
        canvas_h = need

    canvas_h_i = int(math.ceil(canvas_h))
    tgt = _diamond_corners(canvas_h_i, w_tiles, h_tiles)
    dst = [tgt["w"], tgt["s"], tgt["e"]]

    # Supersample the warp to ~source resolution, then LANCZOS down (PIL's
    # affine aliases when downscaling — see SUPERSAMPLE_MAX). ss is chosen so
    # neither axis is being downscaled during the warp, capped for memory.
    cap = max(1, SUPERSAMPLE_MAX // max(canvas_w, canvas_h_i))
    ss = max(
        1,
        min(
            math.ceil(
                max(cropped.width / canvas_w, cropped.height / canvas_h_i)
            ),
            cap,
        ),
    )
    dst_ss = [(x * ss, y * ss) for x, y in dst]
    coeffs, _ = _vertical_preserving_affine(src, dst_ss)
    warped = cropped.transform(
        (canvas_w * ss, canvas_h_i * ss),
        Image.AFFINE,
        coeffs,
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )
    if ss == 1:
        return warped
    return warped.resize(
        (canvas_w, canvas_h_i), Image.Resampling.LANCZOS
    )


def process(
    raw_path: Path,
    footprints: dict[str, tuple[int, int]],
    squash_override: float | None = None,
    footprint_override: tuple[int, int] | None = None,
    flip_override: bool | None = None,
    affine_override: bool | None = None,
) -> tuple[Path, str | None, str | None]:
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

    # Nano Banana frequently returns a rectangular building transposed (a 3×2
    # drawn as 2×3); a horizontal mirror swaps the dimetric ground axes and
    # restores the requested W×H. Auto-detected from the drawn footprint, with a
    # --flip / --no-flip override for the cases the heuristic gets wrong.
    flip, drawn_ratio = needs_horizontal_flip(cropped, w_tiles, h_tiles)
    if flip_override is not None:
        flip = flip_override
    if flip:
        cropped = cropped.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if flip or (flip_override is None and drawn_ratio is not None):
        drawn = "n/a" if drawn_ratio is None else f"{drawn_ratio:.2f}"
        forced = "" if flip_override is None else "  [forced]"
        print(
            f"  {raw_path.name}: drawn W:H {drawn} vs {w_tiles}:{h_tiles} → "
            f"horizontal flip {'applied' if flip else 'not needed'}{forced}",
            file=sys.stderr,
        )

    # Source-resolution check: every NB raw is ~1024px regardless of footprint,
    # so a bigger footprint spreads the same detail over more tiles. If the
    # building's cropped pixels are fewer than the target canvas width, the warp
    # upscales it and the sprite is soft on screen — flag for higher-res
    # regeneration (process.py can't invent detail the source doesn't have).
    lowres: str | None = None
    if cropped.width < canvas_w:
        lowres = (
            f"source {cropped.width}px → {canvas_w}px canvas "
            f"({w_tiles}×{h_tiles}); regenerate in NB at "
            f"≥{round(canvas_w * 1.3 / 64) * 64}px for full sharpness"
        )
        print(f"  {raw_path.name}: ⚠ low-res ({lowres})", file=sys.stderr)

    # Primary path: affine-fit the drawn ground plate onto the exact footprint
    # corners (corrects ratio + projection angle). Disabled by an explicit
    # --squash / --no-affine; skipped when the ground tips look untrustworthy
    # (tall building → roof/foliage tips), falling back to the vertical squash.
    use_affine = (
        squash_override is None
        and affine_override is not False
    )
    corners = ground_corners(cropped) if use_affine else None
    mismatch: str | None = None
    if corners is not None and affine_override is not True:
        anis = _affine_anisotropy(corners, w_tiles, h_tiles)
        if anis > AFFINE_MAX_ANISOTROPY:
            # A clean ground plate was detected, but its width:depth doesn't
            # match the requested footprint — Nano Banana returned the wrong
            # dimensions. Report it so it can be regenerated; squash meanwhile
            # so the build still has an asset.
            xw, _ = corners["w"]
            xs, ys = corners["s"]
            xe, _ = corners["e"]
            d_left = math.hypot(xs - xw, ys - corners["w"][1])
            d_right = math.hypot(xe - xs, ys - corners["e"][1])
            drawn_ratio = d_left / d_right if d_right else 0.0
            mismatch = (
                f"drawn ground ~{drawn_ratio:.2f}:1 but footprint is "
                f"{w_tiles}×{h_tiles} ({w_tiles / h_tiles:.2f}:1) "
                f"— anisotropy {anis:.2f}; regenerate in NB at "
                f"{w_tiles}×{h_tiles} proportions"
            )
            corners = None
    if affine_override is True and corners is None and mismatch is None:
        print(
            f"  {raw_path.name}: --affine forced but ground tips implausible; "
            "using squash fallback",
            file=sys.stderr,
        )
    canvas: Image.Image
    if corners is not None:
        canvas = place_via_affine(
            cropped, corners, w_tiles, h_tiles, base_canvas_h, canvas_w
        )
        ml, mr = corners["_slopes"]  # type: ignore[misc]
        print(
            f"  {raw_path.name}: affine ground-fit (front-edge slopes "
            f"{ml:.2f}/{mr:.2f})",
            file=sys.stderr,
        )
    else:
        # Fallback: resize so cropped width fills the canvas, then squash
        # vertically so the ground diamond is a true 2:1 that sits on the tile.
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
            f"  {raw_path.name}: ground aspect {measured} → "
            f"squash ×{squash:.3f}{note}",
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

    return out_path, mismatch, lowres


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
    flip_override: bool | None = None
    affine_override: bool | None = None
    paths: list[Path] = []
    for arg in args:
        # Manual overrides for outlier raws (e.g. NB drew a flat ground object
        # near-top-down instead of 2:1 dimetric): --squash=0.6 --footprint=4x4.
        # --flip / --no-flip force the horizontal-mirror decision the auto
        # transposed-footprint detector otherwise makes.
        if arg.startswith("--squash="):
            squash_override = float(arg.split("=", 1)[1])
        elif arg.startswith("--footprint="):
            w, h = arg.split("=", 1)[1].lower().split("x")
            footprint_override = (int(w), int(h))
        elif arg == "--flip":
            flip_override = True
        elif arg == "--no-flip":
            flip_override = False
        elif arg == "--affine":
            affine_override = True
        elif arg == "--no-affine":
            affine_override = False
        else:
            paths.append(Path(arg))
    if not paths:
        print(
            f"usage: {sys.argv[0]} [--squash=F] [--footprint=WxH] "
            "[--flip|--no-flip] [--affine|--no-affine] <raw_png> [...]",
            file=sys.stderr,
        )
        sys.exit(1)
    footprints = parse_footprints()
    mismatches: list[tuple[str, str]] = []
    lowres: list[tuple[str, str]] = []
    for raw_path in paths:
        if not raw_path.exists():
            print(f"error: {raw_path} not found", file=sys.stderr)
            sys.exit(1)
        out, mismatch, low = process(
            raw_path,
            footprints,
            squash_override,
            footprint_override,
            flip_override,
            affine_override,
        )
        print(f"{raw_path.name} → {out.relative_to(REPO_ROOT)}")
        if mismatch is not None:
            mismatches.append((raw_path.name, mismatch))
        if low is not None:
            lowres.append((raw_path.name, low))

    if lowres:
        print(
            f"\nℹ {len(lowres)} sprite(s) are source-limited (the ~1024px raw "
            "is upscaled to a larger canvas) — regenerate at higher resolution "
            "for full sharpness:",
            file=sys.stderr,
        )
        for name, reason in lowres:
            print(f"  · {name}: {reason}", file=sys.stderr)

    if mismatches:
        print(
            f"\n⚠ {len(mismatches)} sprite(s) have the wrong dimensions for "
            "their footprint — regenerate these in Nano Banana:",
            file=sys.stderr,
        )
        for name, reason in mismatches:
            print(f"  ✗ {name}: {reason}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
