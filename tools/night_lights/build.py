#!/usr/bin/env python3
"""Bake the chosen light regions into the assets the app draws at night.

    candidates.json   what detect.py found (with a default on / off)
  + overrides.json    what a person changed in the review page
  = assets/buildings/lights.json        polygons + kind, per sprite
    assets/buildings/lit/<sprite>.png   the lit pixels of those regions

    tools/sprite_pipeline/.venv/bin/python tools/night_lights/build.py
    tools/sprite_pipeline/.venv/bin/python tools/night_lights/build.py school_v1
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import nl_common as nl  # noqa: E402


def all_regions(name: str, candidates: dict, overrides: dict) -> list[dict]:
    """Every region of a sprite — detected and hand-added — each with its
    effective `on` and kind after the overrides."""
    entry = candidates.get(name, {"regions": []})
    over = overrides.get(name, {})
    switch = over.get("set", {})
    kinds = over.get("kind", {})
    shapes = over.get("shape", {})
    out = []
    for region in entry["regions"]:
        out.append(
            {
                "id": region["id"],
                "k": kinds.get(region["id"], region["k"]),
                "on": bool(switch.get(region["id"], region["on"])),
                # A polygon someone reshaped by hand wins over the detector's.
                "p": shapes.get(region["id"], region["p"]),
                "edited": region["id"] in shapes,
                "added": False,
            }
        )
    for region in over.get("added", []):
        out.append(
            {
                "id": region["id"],
                "k": kinds.get(region["id"], region.get("k", "w")),
                "on": bool(switch.get(region["id"], True)),
                "p": region["p"],
                "edited": False,
                "added": True,
            }
        )
    return out


def build_sprite(name: str, candidates: dict, overrides: dict, lights: dict) -> int:
    """Bakes one sprite; updates [lights] in place. Returns its region count."""
    regions = [r for r in all_regions(name, candidates, overrides) if r["on"]]
    target = nl.LIT_DIR / f"{name}.png"
    if not regions:
        lights.pop(name, None)
        if target.exists():
            target.unlink()
        return 0
    rgba = nl.load_rgba(name)
    lit = nl.bake_lit(rgba, regions, name)
    nl.LIT_DIR.mkdir(parents=True, exist_ok=True)
    Image.fromarray(lit).save(target, optimize=True)
    h, w = rgba.shape[:2]
    lights[name] = {
        "s": [w, h],
        "r": [{"k": r["k"], "p": r["p"]} for r in regions],
    }
    return len(regions)


def main() -> None:
    names = sys.argv[1:] or nl.sprite_names()
    candidates = nl.read_json(nl.CANDIDATES_JSON, {})
    overrides = nl.read_json(nl.OVERRIDES_JSON, {})
    lights = nl.read_json(nl.LIGHTS_JSON, {})
    total = 0
    for name in names:
        total += build_sprite(name, candidates, overrides, lights)
    nl.write_json(nl.LIGHTS_JSON, dict(sorted(lights.items())), compact=True)
    print(
        f"baked {len(names)} sprites, {total} regions → "
        f"{nl.LIGHTS_JSON.relative_to(nl.ROOT)}, {nl.LIT_DIR.relative_to(nl.ROOT)}/"
    )


if __name__ == "__main__":
    main()
