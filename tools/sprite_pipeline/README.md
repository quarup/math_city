# Sprite pipeline

End-to-end tooling for the Phase 9 building art per
[city_builder.md §5.1](../../city_builder.md). Two stages: emit a
Nano Banana prompt per building, then post-process each raw output
into a game-ready sprite.

## Files

- `generate_prompts.py` — parse `city_builder.md §3` and emit one prompt
  per building (with the `Nx` variant-count prefix from §5.4).
- `prompts.txt` — generated output (committed; regenerate after §3 edits).
- `process.py` — turn a raw Nano Banana PNG into a game-ready asset
  (background removal → despeckle → bbox crop → resize to per-footprint
  canvas → vertical squash to a true 2:1 ground diamond → bottom-center
  anchor → pngquant compress, plus a debug overlay for visual QA).
- `raw/` — raw Nano Banana outputs, named `<id>_v<n>.{png,jpg,jpeg}` (`n`
  1-based; a bare `<id>.<ext>` singleton is treated as `v1`). Committed
  (source of truth; lets us re-run `process.py` if the resolver changes).
- `debug/` — QA overlays with the tile diamond drawn over each sprite.
  Gitignored — regenerate by re-running `process.py`.

Final sprites land in `assets/buildings/<id>_v<n>.png` and are loaded
by the Flame renderer at runtime.

## Workflow

### 1. Generate prompts

```sh
python3 tools/sprite_pipeline/generate_prompts.py > tools/sprite_pipeline/prompts.txt
```

Each line is one Nano Banana prompt prefixed with the number of variants to
generate (e.g. `5x …` for `single_home`).

### 2. Generate sprites in Nano Banana

Run each prompt in Nano Banana (we use Google Flow). Save each output as
`tools/sprite_pipeline/raw/<id>_v<n>.png` (a `.jpg` / `.jpeg` export is fine
too — `process.py` accepts either), where `<id>` is the building ID from
`city_builder.md §3` and `<n>` is a 1-based variant number. Regardless of
the input extension, the processed sprite is always emitted as
`assets/buildings/<id>_v<n>.png`.

### 3. Process

One-time setup:

```sh
pip install Pillow numpy "rembg[cpu]"
# pngquant binary: apt-get install pngquant (Linux) or brew install pngquant (macOS)
```

Background removal is a **hybrid**: rembg's ML matte (the only thing that can
separate green foreground — trees, lawn — from the matching green Nano Banana
backdrop) plus a **non-green protection** pass. The raw exports use a solid
green backdrop, so the only true background is green; any pixel that isn't
backdrop-green (gray plaza, stone, brick) is forced opaque, which stops rembg
from occasionally eating a building's flat gray plaza as "ground." "Green" is
judged by greenness (G exceeding R and B by `GREEN_MARGIN`), so it's
shade-independent.

A **despeckle** pass then drops tiny disconnected opaque islands: when a raw
export's backdrop is noisy (hospital_v1 was the first case), the non-green
protection keeps the not-green-enough flecks, leaving speckles floating around
the building that would also skew the bbox crop and the ground-tip detection.
Components smaller than `DESPECKLE_MIN_FRACTION` of the largest one are noise.

Per-sprite:

```sh
python3 tools/sprite_pipeline/process.py tools/sprite_pipeline/raw/coffee_shop_v1.png
```

Or batch:

```sh
python3 tools/sprite_pipeline/process.py tools/sprite_pipeline/raw/*.png
```

Outputs:

- `assets/buildings/<id>_v<n>.png` — the final compressed sprite.
- `tools/sprite_pipeline/debug/<id>_v<n>.png` — debug overlay with the
  tile diamond drawn at the lot footprint, for visual QA. Open these,
  scan for cases where the sprite's south corner clearly doesn't sit on
  the diamond's south corner, and re-roll (or hand-nudge) those.

## Vehicles (city_builder.md §9, A2)

Cars are not buildings: one Nano Banana image gives **one vehicle in all
eight headings**, and `process_vehicles.py` cuts it up. Same green backdrop,
same reference images as the buildings (`raw/bus_depot_v1.jpeg` and
`raw/fire_station_v1.jpeg` already show vehicles in the house style, plus
`raw/single_home_v1.jpeg` for scale). **Model: Nano Banana 2
(`gemini-3.1-flash-image`)**, aspect 1:1, 1024 px, thinking high, default
temperature — the settings every checked-in sheet was made with. Never ask
for a green vehicle: the backdrop is keyed on greenness. The prompt that produced
`raw_sheets/car.jpg` is below; every planned vehicle's prompt (same body,
different noun / colour / `--length`, plus the building that unlocks it —
see city_builder.md §9.5) is one copy-pasteable line in
[raw_sheets/vehicle_prompts.txt](raw_sheets/vehicle_prompts.txt):

> Turnaround sheet of one isometric blue hatchback, shown eight times on a
> single solid bright green background, matching the style, lighting
> direction and 2:1 dimetric projection of the reference images. The eight
> cars are arranged in a ring around an empty centre like a compass rose,
> one at each of the eight compass points (N, NE, E, SE, S, SW, W, NW), and
> each car's nose points directly away from the centre of the image, so the
> eight views are 45 degree rotations of the same car. Every car is
> identical in colour, shape, size and details, and lit identically from the
> upper left. The cars do not overlap and are evenly spaced. No shadow of any
> kind: no cast shadow, no contact shadow, no ground plane, no reflection.
> No text, no arrows, no labels, no grid lines.

NB does **not** obey the "nose away from the centre" rule, and about one
sheet in three comes back with a heading drawn twice and another missing
(it likes fronts). Look at the sheet and list the heading of each
ring position clockwise from the top (`N,NE,E,SE,S,SW,W,NW`), naming
headings by where the nose points on screen — `dr d dl l ul u ur r`:

```sh
tools/sprite_pipeline/.venv/bin/python tools/sprite_pipeline/process_vehicles.py \
    tools/sprite_pipeline/raw_sheets/car.jpg --id hatchback \
    --headings d,dr,l,ur,u,ul,r,dl --length 0.42
```

If exactly one heading is missing, `--mirror ur=ul` (or `r=l`, `dl=dr`)
fills it with the horizontal flip of its twin; the lit side flips, so
treat it as a stopgap and re-roll. The straight up/down views (`u`, `d`)
have no twin: `--copy d=dr,u=ul` reuses a neighbour as-is, and that
vehicle then shows two sprites through a bend instead of three. More
missing than that: re-roll.

`--length` is the car's length in tiles (10 m): 0.42 for a hatchback keeps
it inside one 0.3-wide lane; a bus would be ~0.9. The script chroma-keys
the green (no rembg — a car has no green in it), splits the ring into
components, scales all eight uniformly from the side views (the report
prints how far each view strays from a true 2:1 projection; NB draws the
diagonal views ~20 % narrow, which is left alone because correcting it
made the car swell on bends), and pads the top so the car's ground-contact
centre is the exact centre of the PNG — the renderer anchors every heading
with `Anchor.center`. Output: `assets/vehicles/<id>_h0..7.png` (h0 = nose
down-right = grid east, then every 45° clockwise) plus a QA sheet at
`debug/vehicle_<id>.png` with each heading on a road tile. Add the new
`<id>` to `TrafficSystem.kinds` and it spawns.

## Constants worth knowing

- `TILE_W = 192px` in `process.py` matches the Flame iso renderer
  (`lib/game/city/iso_grid.dart`: world tile width 64 × max camera zoom 3),
  so authored sprites are sharp at every supported zoom level.
- `TOWER_HEADROOM = 1.5` extra diamond-heights above the lot for towers /
  flags / spires. The canvas auto-extends further if the resized sprite
  needs more room.
