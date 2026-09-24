#!/usr/bin/env python3
"""Cut a Nano Banana vehicle turnaround sheet into eight heading sprites.

Per city_builder.md §9 (idea A2), each vehicle is one NB image: the same car
drawn eight times in a ring on a solid green backdrop, one per 45° heading,
no shadows (the game draws the ground shadow itself so every mover's shadow
matches). NB does not reliably point each car where the prompt asks, so the
heading of each ring position is given on the command line after a glance
at the sheet.

Ring positions are named clockwise from the top: N NE E SE S SW W NW.
Headings are named by where the car's nose points **on screen**:

    dr  down-right   (grid east,  +col)      h0
    d   down                                 h1
    dl  down-left    (grid south, +row)      h2
    l   left                                 h3
    ul  up-left      (grid west,  -col)      h4
    u   up                                   h5
    ur  up-right     (grid north, -row)      h6
    r   right                                h7

so `h = 2 * dir` for the four grid directions and the odd indices sit
between them (see lib/domain/city/traffic.dart).

Scale comes from the car's real length, not from NB: the two side views
(l, r) show the car's full length along the screen x axis, where one tile
unit is TILE_W / sqrt(2) px, so `--length` (in tiles) fixes one uniform
scale for all eight cuts. The nearest tyre of a car sits *below* its
ground-contact centre on screen, so each cut is padded at the top until
that centre is the **exact centre of its canvas**; the renderer anchors
every heading with Anchor.center at the car's position on the road.

Usage:
  .venv/bin/python tools/sprite_pipeline/process_vehicles.py \
      tools/sprite_pipeline/raw_sheets/car.jpg --id hatchback \
      --headings d,dr,l,ur,u,ul,r,dl --length 0.42

Outputs assets/vehicles/<id>_h<k>.png for k in 0..7 and a QA sheet at
tools/sprite_pipeline/debug/vehicle_<id>.png showing each heading on a
road tile at authoring scale.
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import subprocess

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

# Mirrors process.py (not imported: that module pulls in rembg, which this
# script does not need and which is slow to load).
TILE_W = 192
TILE_H = TILE_W // 2
GREEN_MARGIN = 30

REPO_ROOT = Path(__file__).resolve().parents[2]
ASSETS_DIR = REPO_ROOT / "assets" / "vehicles"
DEBUG_DIR = REPO_ROOT / "tools" / "sprite_pipeline" / "debug"
ROAD_STRAIGHT = REPO_ROOT / "assets" / "buildings" / "road_straight.png"

RING = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
HEADINGS = ["dr", "d", "dl", "l", "ul", "u", "ur", "r"]

# Screen px per tile unit at authoring scale, along each kind of axis.
GRID_AXIS_X = TILE_W / 2  # +col moves (96, 48); +row moves (-96, 48)
GRID_AXIS_Y = TILE_H / 2
DIAG_X = TILE_W / math.sqrt(2)  # along (col - row): horizontal on screen
DIAG_Y = TILE_H / math.sqrt(2)  # along (col + row): vertical on screen

# Smallest component kept, as a fraction of the largest (JPEG crumbs).
MIN_COMPONENT_FRACTION = 0.05
# Soft edge: alpha ramps over this many greenness units past the margin.
EDGE_SOFTNESS = 25


def key_green(raw: Image.Image, bg: str = "green") -> Image.Image:
    """Chroma-key the backdrop with a soft edge and despill.

    Vehicles never contain backdrop-green, so no ML matte is needed; a plain
    key with a short alpha ramp gives clean anti-aliased edges. Edge pixels
    get the backdrop channel clamped so the JPEG fringe does not glow. A
    green vehicle is generated on a **magenta** backdrop instead (`bg`), keyed
    on how much red and blue exceed green.
    """
    rgb = np.asarray(raw.convert("RGB")).astype(np.int16)
    if bg == "green":
        keyness = rgb[..., 1] - np.maximum(rgb[..., 0], rgb[..., 2])
    elif bg == "magenta":
        keyness = np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1]
    else:
        sys.exit(f"error: unknown --bg {bg}")
    alpha = np.clip((GREEN_MARGIN + EDGE_SOFTNESS - keyness) / EDGE_SOFTNESS, 0, 1)
    edge = (alpha > 0) & (alpha < 1)
    out = rgb.copy()
    if bg == "green":
        out[..., 1][edge] = np.minimum(out[..., 1][edge], np.maximum(out[..., 0], out[..., 2])[edge])
    else:
        cap = out[..., 1][edge]
        out[..., 0][edge] = np.minimum(out[..., 0][edge], cap)
        out[..., 2][edge] = np.minimum(out[..., 2][edge], cap)
    a8 = (alpha * 255).astype(np.uint8)
    return Image.fromarray(np.dstack([out.astype(np.uint8), a8]))


def split_ring(img: Image.Image) -> list[tuple[str, Image.Image]]:
    """Connected components of the keyed sheet, labelled by ring position."""
    arr = np.array(img)
    solid = arr[..., 3] > 128
    labels, n = ndimage.label(solid, structure=np.ones((3, 3)))
    sizes = np.bincount(labels.ravel())
    sizes[0] = 0
    keep = [i for i in range(1, n + 1) if sizes[i] >= sizes.max() * MIN_COMPONENT_FRACTION]
    if len(keep) != 8:
        sys.exit(
            f"error: expected 8 cars on the sheet, found {len(keep)} "
            f"(component sizes: {sorted((int(sizes[i]) for i in keep), reverse=True)})"
        )
    cx0, cy0 = arr.shape[1] / 2, arr.shape[0] / 2
    cuts = []
    for i in keep:
        ys, xs = np.nonzero(labels == i)
        # Clockwise from the top: N is angle 0, E is 90°, S 180°, W 270°.
        ang = (math.degrees(math.atan2(xs.mean() - cx0, cy0 - ys.mean())) + 360) % 360
        slot = int(round(ang / 45)) % 8
        mask = labels == i
        sub = arr.copy()
        sub[..., 3][~mask] = 0
        crop = Image.fromarray(sub).crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        cuts.append((slot, ang, crop))
    slots = sorted(c[0] for c in cuts)
    if slots != list(range(8)):
        sys.exit(f"error: cars are not on distinct ring positions: {[(RING[s], round(a)) for s, a, _ in cuts]}")
    return [(RING[s], crop) for s, _, crop in sorted(cuts, key=lambda c: c[0])]


def ground_offset(heading: str, length: float, width: float) -> float:
    """Px from the cut's bottom edge up to its ground-contact centre.

    The car's ground rectangle is length × width in tile units. Its lowest
    screen point is the corner nearest the camera; how far the rectangle's
    centre sits above that depends on which axes the car spans. Each case
    equals a quarter of a projected width (see expected_width), which is
    what main() uses with the *measured* widths.
    """
    if heading in ("dr", "dl", "ul", "ur"):  # both grid axes contribute
        return (length + width) / 2 * GRID_AXIS_Y
    if heading in ("l", "r"):  # length is horizontal; width is the (col+row) diagonal
        return width / 2 * DIAG_Y
    return length / 2 * DIAG_Y  # u, d: length runs along the vertical diagonal


def expected_width(heading: str, length: float, width: float) -> float:
    if heading in ("dr", "dl", "ul", "ur"):
        return (length + width) * GRID_AXIS_X
    if heading in ("l", "r"):
        return length * DIAG_X
    return width * DIAG_X


def _maybe_pngquant(path: Path) -> None:
    try:
        subprocess.run(
            ["pngquant", "--quality=70-95", "--force", "--ext=.png", "--skip-if-larger", str(path)],
            check=True,
            capture_output=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError) as e:
        msg = e.stderr.decode().strip() if hasattr(e, "stderr") and e.stderr else str(e)
        print(f"warning: pngquant skipped for {path.name}: {msg}", file=sys.stderr)


def build_debug_sheet(cuts: dict[str, Image.Image], vid: str) -> None:
    """Each heading on a straight road tile at authoring scale, for QA."""
    road = Image.open(ROAD_STRAIGHT).convert("RGBA")
    cell_w, cell_h = 260, 240
    sheet = Image.new("RGBA", (cell_w * 4, cell_h * 2), (60, 140, 60, 255))
    draw = ImageDraw.Draw(sheet)
    for k, heading in enumerate(HEADINGS):
        ox, oy = (k % 4) * cell_w, (k // 4) * cell_h
        # Tile centre at the cell centre; the road png is 200x100 with a 4/2 px rim.
        tcx, tcy = ox + cell_w // 2, oy + cell_h // 2 + 20
        sheet.alpha_composite(road, (tcx - road.width // 2, tcy - road.height // 2))
        cut = cuts[heading]
        sheet.alpha_composite(cut, (tcx - cut.width // 2, tcy - cut.height // 2))
        draw.ellipse((tcx - 3, tcy - 3, tcx + 3, tcy + 3), fill=(255, 40, 40, 255))
        draw.text((ox + 6, oy + 6), f"h{k} {heading}", fill=(255, 255, 255, 255))
    DEBUG_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(DEBUG_DIR / f"vehicle_{vid}.png")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("sheet", type=Path)
    ap.add_argument("--id", required=True, help="vehicle id, e.g. hatchback")
    ap.add_argument(
        "--headings",
        required=True,
        help="comma list of 8 headings for ring positions N,NE,E,SE,S,SW,W,NW",
    )
    ap.add_argument("--length", type=float, default=0.5, help="car length in tiles")
    ap.add_argument("--bg", default="green", help="backdrop colour: green (default) or magenta")
    ap.add_argument(
        "--mirror",
        default="",
        help="fill a heading NB left out from the horizontal flip of its twin, "
        "e.g. ur=ul or r=l (comma list). The lit side flips, so re-roll when you can.",
    )
    ap.add_argument(
        "--copy",
        default="",
        help="fill a missing straight-up/down view (u, d — they have no mirror twin) with a "
        "neighbouring heading as-is, e.g. d=dr,u=ul. The bend then shows two sprites instead "
        "of three for this vehicle; re-roll when you can.",
    )
    args = ap.parse_args()

    headings = args.headings.split(",")
    if len(headings) != 8 or any(h not in HEADINGS for h in headings):
        sys.exit(f"error: --headings needs 8 entries from {','.join(HEADINGS)}")
    mirrors = dict(m.split("=") for m in args.mirror.split(",") if m)
    copies = dict(m.split("=") for m in args.copy.split(",") if m)
    if set(headings) | set(mirrors) | set(copies) != set(HEADINGS):
        missing = sorted(set(HEADINGS) - set(headings) - set(mirrors) - set(copies))
        sys.exit(f"error: headings missing from the sheet and not mirrored/copied: {missing}")

    raw = Image.open(args.sheet)
    keyed = key_green(raw, args.bg)
    by_heading: dict[str, Image.Image] = {}
    for pos, crop in split_ring(keyed):
        h = headings[RING.index(pos)]
        if h in by_heading:
            continue  # NB drew this heading twice; keep the first
        by_heading[h] = crop
    for dst, src in mirrors.items():
        by_heading[dst] = by_heading[src].transpose(Image.FLIP_LEFT_RIGHT)
        print(f"warning: {dst} is a mirror of {src} (lit side flipped) — re-roll the sheet when you can")
    for dst, src in copies.items():
        by_heading[dst] = by_heading[src].copy()
        print(f"warning: {dst} reuses {src} as-is — re-roll the sheet when you can")

    # One uniform scale for all eight cuts, fixed by the side views (they
    # show the full length along screen x). NB draws the diagonal views
    # from a slightly different azimuth than a true 2:1 projection (about
    # 20 % narrower), but rescaling them to the projection made the car
    # visibly swell on every bend, so the artist's proportions are kept and
    # the deviation is only reported.
    side_px = (by_heading["l"].width + by_heading["r"].width) / 2
    front_px = (by_heading["u"].width + by_heading["d"].width) / 2
    scale = args.length * DIAG_X / side_px
    width = front_px * scale / DIAG_X
    print(f"{args.id}: length {args.length:.2f} tiles, drawn width {width:.2f} tiles (scale {scale:.3f})")

    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    finals: dict[str, Image.Image] = {}
    for k, heading in enumerate(HEADINGS):
        crop = by_heading[heading]
        w = max(1, round(crop.width * scale))
        h = max(1, round(crop.height * scale))
        small = crop.resize((w, h), Image.LANCZOS)
        # Ground-contact centre sits `lift` px above the lowest tyre. For
        # every view that is a quarter of some measured width (see
        # ground_offset): the view's own width for the diagonal headings,
        # the front view's for the side views, the side view's for the
        # front/rear views. Using measured widths keeps the anchor right
        # even where NB's proportions stray from the projection.
        if heading in ("dr", "dl", "ul", "ur"):
            lift = round(w / 4)
        elif heading in ("l", "r"):
            lift = round(front_px * scale / 4)
        else:
            lift = round(side_px * scale / 4)
        # With the car at the top of the canvas its ground centre is at
        # y = h - lift, so a canvas twice that tall puts it dead centre.
        canvas_h = 2 * (h - lift)
        canvas = Image.new("RGBA", (w, canvas_h), (0, 0, 0, 0))
        canvas.alpha_composite(small, (0, 0))
        exp = expected_width(heading, args.length, width)
        off = w / exp - 1
        flag = "" if abs(off) < 0.35 else "   <-- far off the 2:1 projection; re-roll the sheet"
        print(f"  h{k} {heading:>2}: {w}x{h} on {w}x{canvas_h} (NB drew it {off:+.0%} vs projection){flag}")
        out = ASSETS_DIR / f"{args.id}_h{k}.png"
        canvas.save(out)
        _maybe_pngquant(out)
        finals[heading] = canvas
    build_debug_sheet(finals, args.id)
    print(f"wrote {ASSETS_DIR}/{args.id}_h0..7.png and {DEBUG_DIR}/vehicle_{args.id}.png")


if __name__ == "__main__":
    main()
