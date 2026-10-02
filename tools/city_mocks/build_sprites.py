#!/usr/bin/env python3
"""Regenerate tools/city_mocks/sprites.js from assets/buildings/*.png.

The mock pages embed the real building and road sprites as data URIs so they
run from a plain file:// URL with no server. The bundle is ~1.6 MB and is
gitignored; run this once after cloning (or after changing a sprite).

    python3 tools/city_mocks/build_sprites.py
    open tools/city_mocks/city_alive.html
"""
import base64
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets" / "buildings"
OUT = Path(__file__).with_name("sprites.js")

# Every sprite the mock pages reference (see FOOT in engine.js + the road set).
NAMES = [
    "apartment_v1", "park_v1", "coffee_shop_v1", "high_rise_v1", "amusement_park_v1",
    "fountain_plaza_v1", "power_plant_v1", "fire_station_v1", "observation_tower_v1",
    "duplex_v1", "playground_v1", "hospital_v1", "bakery_v1", "farmhouse_v1",
    "police_station_v1", "mayors_office_v1", "school_v1", "single_home_v1", "road_cross", "road_straight", "road_curve_lr", "road_curve_ud",
    "road_deadend", "road_tee",
]

# The night-lights page (night_lights.html) also needs the real vehicle
# sprites (eight headings each), the lit-window images and their regions.
VEHICLES = ["hatchback", "sedan", "taxi", "pickup", "bus", "police_car"]
LIT = [
    "apartment_v1", "duplex_v1", "bakery_v1", "single_home_v1",
    "coffee_shop_v1", "park_v1", "hospital_v1",
]


def data_uri(path: Path) -> str:
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode()


lines = ["const SPRITES = {"]
for n in NAMES:
    lines.append(f'  {n}: "{data_uri(ASSETS / f"{n}.png")}",')
count = len(NAMES)
for kind in VEHICLES:
    for h in range(8):
        file = ROOT / "assets" / "vehicles" / f"{kind}_h{h}.png"
        lines.append(f'  veh_{kind}_h{h}: "{data_uri(file)}",')
        count += 1
lights = json.loads((ASSETS / "lights.json").read_text()) if (ASSETS / "lights.json").exists() else {}
for n in LIT:
    file = ASSETS / "lit" / f"{n}.png"
    if file.exists():
        lines.append(f'  lit_{n}: "{data_uri(file)}",')
        count += 1
lines.append("};")
lines.append(
    "const NIGHT_LIGHTS = "
    + json.dumps({n: lights[n] for n in LIT if n in lights}, separators=(",", ":"))
    + ";"
)
OUT.write_text("\n".join(lines) + "\n")
print(f"wrote {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB, {count} sprites)")
