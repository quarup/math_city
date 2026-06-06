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

from PIL import Image, ImageDraw
from rembg import remove

# Match the Flame iso renderer (lib/game/city/iso_grid.dart): world tile
# diamond is 64 wide, max camera zoom is 3, so authoring at 192 px / tile
# yields sharp output at every supported zoom level.
TILE_W = 192
TILE_H = TILE_W // 2  # 2:1 dimetric — diamond bounding box is W x W/2

# Extra height above the lot diamond, expressed as a multiplier of the
# diamond's pixel height. Covers building height + any flags/spires; the
# canvas auto-extends further if the resized sprite needs more room.
TOWER_HEADROOM = 1.5

REPO_ROOT = Path(__file__).resolve().parents[2]
CITY_BUILDER_MD = REPO_ROOT / "city_builder.md"
ASSETS_DIR = REPO_ROOT / "assets" / "buildings"
DEBUG_DIR = REPO_ROOT / "tools" / "sprite_pipeline" / "debug"

ID_RE = re.compile(r"^`(\w+)`")
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


def process(raw_path: Path, footprints: dict[str, tuple[int, int]]) -> Path:
    building_id, variant = building_id_and_variant(raw_path)
    out_name = f"{building_id}_v{variant}.png"
    if building_id not in footprints:
        raise ValueError(
            f"no footprint for {building_id!r} in city_builder.md §3 "
            f"(known: {sorted(footprints)[:5]}…)"
        )
    w_tiles, h_tiles = footprints[building_id]
    canvas_w, base_canvas_h, diamond_h = canvas_size(w_tiles, h_tiles)

    raw = Image.open(raw_path).convert("RGBA")
    cut = remove(raw)
    bbox = cut.getbbox()
    if bbox is None:
        raise ValueError(f"{raw_path.name}: no opaque pixels after rembg")
    cropped = cut.crop(bbox)

    # Resize so cropped width fills the canvas width, preserving aspect.
    new_w = canvas_w
    new_h = round(cropped.height * canvas_w / cropped.width)
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)

    # Final canvas height grows if the resized sprite is taller than headroom.
    canvas_h = max(base_canvas_h, new_h)
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    paste_x = (canvas_w - new_w) // 2
    paste_y = canvas_h - new_h
    canvas.paste(resized, (paste_x, paste_y), resized)

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
    draw = ImageDraw.Draw(img, "RGBA")
    diamond_w = (w_tiles + h_tiles) * TILE_W // 2
    diamond_h = (w_tiles + h_tiles) * TILE_H // 2
    cx = img.width // 2
    by = img.height  # canvas bottom = lot-diamond south corner
    south = (cx, by - 1)
    east = (cx + diamond_w // 2, by - diamond_h // 2)
    north = (cx, by - diamond_h)
    west = (cx - diamond_w // 2, by - diamond_h // 2)
    draw.polygon([south, east, north, west], outline=(255, 0, 0, 220), width=3)


def main() -> None:
    if len(sys.argv) < 2:
        print(f"usage: {sys.argv[0]} <raw_png_path> [...]", file=sys.stderr)
        sys.exit(1)
    footprints = parse_footprints()
    for arg in sys.argv[1:]:
        raw_path = Path(arg)
        if not raw_path.exists():
            print(f"error: {raw_path} not found", file=sys.stderr)
            sys.exit(1)
        out = process(raw_path, footprints)
        print(f"{raw_path.name} → {out.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
