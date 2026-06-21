#!/usr/bin/env python3
"""Emit Nano Banana prompts for every building in city_builder.md §3.

Parses the §3.x building tables, reads each building's ID and footprint,
humanises the ID into a display name, multiplies the footprint by the
fixed 10m/tile scale, and prints one prompt per line prefixed with the
per-building sprite-variant count from city_builder.md §5.4.
"""

from __future__ import annotations

import re
import sys
from math import gcd
from pathlib import Path

# 1 tile = 10m × 10m on the ground (see city_builder.md §5.1 — Scale).
TILE_METERS = 10

PROMPT_TEMPLATE = (
    "{n}x Generate an image of an isometric {name} with a {w}m x {h}m "
    "footprint (strict {rw}:{rh} ratio) "
    "matching the style of the reference image. "
    "Solid bright green background. "
    "Single 2:1 dimetric isometric projection, no perspective. "
    "No text."
)

# Only IDs whose `_`→` ` form is wrong (apostrophes, etc.) need an entry.
NAME_OVERRIDES = {
    "mayors_office": "mayor's office",
}

# Per-building sprite-variant count. Source of truth mirrored in
# city_builder.md §5.4 — keep both in sync when tuning. Missing IDs default
# to 1 (with a stderr warning) so a new row in §3 doesn't break the script.
VARIANT_COUNTS = {
    # Civic & Housing
    "mayors_office": 1,
    "town_hall": 1,
    "city_hall": 1,
    "library": 2,
    "post_office": 2,
    "single_home": 5,
    "duplex": 4,
    "townhouse_row": 3,
    "apartment": 4,
    "mid_rise_apartment": 2,
    "high_rise": 2,
    "luxury_condo": 2,
    "farmhouse": 3,
    # Services
    "power_plant": 2,
    "power_station": 1,
    "solar_farm": 1,
    "water_tower": 2,
    "water_treatment": 1,
    "waste_management": 2,
    "recycling_center": 1,
    "clinic": 2,
    "hospital": 1,
    "school": 2,
    "high_school": 1,
    "fire_station": 1,
    "police_station": 1,
    "bus_depot": 1,
    "gym": 1,
    # Commercial
    "market_stall": 3,
    "grocery": 2,
    "supermarket": 1,
    "bakery": 2,
    "coffee_shop": 4,
    "restaurant": 2,
    "farmers_market": 2,
    "bookshop": 1,
    "toy_store": 1,
    "clothing_store": 1,
    "office_building": 2,
    "shopping_mall": 1,
    "business_tower": 1,
    # Entertainment
    "park": 5,
    "playground": 3,
    "community_garden": 2,
    "fountain_plaza": 1,
    "botanical_garden": 1,
    "sports_field": 2,
    "swimming_pool": 1,
    "movie_theater": 1,
    "museum": 1,
    "stadium": 1,
    "zoo": 1,
    "aquarium": 1,
    "amusement_park": 1,
    "observation_tower": 1,
}

REPO_ROOT = Path(__file__).resolve().parents[2]
CITY_BUILDER_MD = REPO_ROOT / "city_builder.md"

# Rows gain a leading "✅ " once wired (tools/city_builder/sync_implementation_status.py).
ID_RE = re.compile(r"^(?:✅ )?`(\w+)`")
DIM_RE = re.compile(r"(\d+)×(\d+)")
SEP_CHARS = set("-:| ")


def display_name(building_id: str) -> str:
    return NAME_OVERRIDES.get(building_id, building_id.replace("_", " "))


def variant_count(building_id: str) -> int:
    if building_id not in VARIANT_COUNTS:
        print(
            f"warning: {building_id} has no VARIANT_COUNTS entry; defaulting to 1",
            file=sys.stderr,
        )
        return 1
    return VARIANT_COUNTS[building_id]


def main() -> None:
    md = CITY_BUILDER_MD.read_text(encoding="utf-8")

    in_catalog = False
    foot_col: int | None = None

    for line in md.splitlines():
        # Top-level section tracking: enter §3, leave at §4 etc.
        if line.startswith("## "):
            in_catalog = line.startswith("## 3.")
            foot_col = None
            continue
        if not in_catalog:
            continue
        # §3.5+ are commentary, not building tables — stop scanning.
        if line.startswith("### 3.5"):
            in_catalog = False
            continue

        if not line.startswith("|"):
            continue
        # Skip the `|---|---|...` separator under every table header.
        if set(line.strip()) <= SEP_CHARS:
            continue

        cells = [c.strip() for c in line.strip().strip("|").split("|")]

        # Header row resets the Foot column index for the table that follows.
        if "Building" in cells and "Foot" in cells:
            foot_col = cells.index("Foot")
            continue

        if foot_col is None or len(cells) <= foot_col:
            continue

        m_id = ID_RE.match(cells[0])
        m_dim = DIM_RE.search(cells[foot_col])
        if not (m_id and m_dim):
            continue

        building_id = m_id.group(1)
        name = display_name(building_id)
        w_tiles = int(m_dim.group(1))
        h_tiles = int(m_dim.group(2))
        w_m = w_tiles * TILE_METERS
        h_m = h_tiles * TILE_METERS
        g = gcd(w_tiles, h_tiles)
        rw, rh = w_tiles // g, h_tiles // g
        n = variant_count(building_id)
        print(PROMPT_TEMPLATE.format(n=n, name=name, w=w_m, h=h_m, rw=rw, rh=rh))


if __name__ == "__main__":
    main()
