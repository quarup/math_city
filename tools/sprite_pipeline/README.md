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

## Constants worth knowing

- `TILE_W = 192px` in `process.py` matches the Flame iso renderer
  (`lib/game/city/iso_grid.dart`: world tile width 64 × max camera zoom 3),
  so authored sprites are sharp at every supported zoom level.
- `TOWER_HEADROOM = 1.5` extra diamond-heights above the lot for towers /
  flags / spires. The canvas auto-extends further if the resized sprite
  needs more room.
