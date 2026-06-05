#!/usr/bin/env python3
"""Emit Nano Banana prompts for every building in city_builder.md §3.

Parses the §3.x building tables, reads each building's ID and footprint,
humanises the ID into a display name, and prints one prompt per line.
"""

from __future__ import annotations

import re
from pathlib import Path

PROMPT_TEMPLATE = (
    "Generate an image of an isometric {name} with a {dim} footprint "
    "matching the style of the reference image. "
    "Solid bright green background. "
    "Single 2:1 dimetric isometric projection, no perspective."
)

# Only IDs whose `_`→` ` form is wrong (apostrophes, etc.) need an entry.
NAME_OVERRIDES = {
    "mayors_office": "mayor's office",
}

REPO_ROOT = Path(__file__).resolve().parents[2]
CITY_BUILDER_MD = REPO_ROOT / "city_builder.md"

ID_RE = re.compile(r"^`(\w+)`")
DIM_RE = re.compile(r"(\d+)×(\d+)")
SEP_CHARS = set("-:| ")


def display_name(building_id: str) -> str:
    return NAME_OVERRIDES.get(building_id, building_id.replace("_", " "))


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

        name = display_name(m_id.group(1))
        dim = f"{m_dim.group(1)}x{m_dim.group(2)}"
        print(PROMPT_TEMPLATE.format(name=name, dim=dim))


if __name__ == "__main__":
    main()
