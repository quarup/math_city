#!/usr/bin/env python3
"""Bake the hand-drawn light regions into the assets the app draws at night.

    regions.json      what a person drew in the review page
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


# Region kind → the kind the app reads from lights.json.
APP_KIND = {"s": "g"}


def build_sprite(name: str, saved: dict, lights: dict) -> int:
    """Bakes one sprite; updates [lights] in place. Returns its region count.
    A sprite with no regions has no entry and no lit image."""
    regions = nl.regions_of(name, saved)
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
        # The app only needs the hours: a sign burns all night like a glow,
        # and its colour is already in the lit image.
        "r": [{"k": APP_KIND.get(r["k"], r["k"]), "p": r["p"]} for r in regions],
    }
    return len(regions)


def main() -> None:
    names = sys.argv[1:] or nl.sprite_names()
    saved = nl.read_json(nl.REGIONS_JSON, {})
    lights = nl.read_json(nl.LIGHTS_JSON, {})
    total = 0
    for name in names:
        total += build_sprite(name, saved, lights)
    nl.write_json(nl.LIGHTS_JSON, dict(sorted(lights.items())), compact=True)
    print(
        f"baked {len(names)} sprites, {total} regions → "
        f"{nl.LIGHTS_JSON.relative_to(nl.ROOT)}, {nl.LIT_DIR.relative_to(nl.ROOT)}/"
    )


if __name__ == "__main__":
    main()
