# Building-art bake-off (Phase 6.5 spike)

Three approaches to Phase-7 isometric building art, rendered side-by-side in
one PNG so we can pick by eye instead of by argument.

## Approaches

| | Approach | Coherence story | Scaling story | Licensing |
|---|---|---|---|---|
| A | **Kenney bundles** (City Kit Industrial + Commercial + Suburban + Roads) | Same artist hand within Kenney's family | ~30–40 buildings before mixing artists | CC0 |
| B | **Procedural CustomPainter** | One renderer, every building. Coherence is automatic | Infinite — every building is a function of `BuildingSpec` | n/a (we own it) |
| C | **GenAI sprites** (Flux / SDXL with fixed seed + LoRA) | Hardest. Needs prompt + LoRA discipline | Generate-on-demand, but per-sprite curation cost | Depends on base model (Flux Schnell = Apache 2.0) |

## The 5 starter buildings (matches Phase 7 plan)

`house`, `apartment`, `school` (2×1), `hospital` (2×1), `power_plant`, plus a
`road` tile for context. Defined once in [building_specs.dart](building_specs.dart).

## How to regenerate the comparison PNG

```sh
flutter test test/spike/building_bakeoff_golden_test.dart --update-goldens
```

The output lives at `test/spike/goldens/comparison.png`. Commit it alongside
any code change to this spike — the PNG **is** the deliverable.

## Populating Options A and C

Option B (procedural) is fully wired. Options A and C currently render
**slot placeholders** so the comparison layout is meaningful. To populate:

### Option A — Kenney bundles

1. Download from <https://kenney.nl/assets/city-kit-suburban>,
   <https://kenney.nl/assets/city-kit-commercial>,
   <https://kenney.nl/assets/city-kit-roads>. All CC0.
2. Pick one PNG per building id and save to:
   - `assets/spike/option_a_kenney/house.png`
   - `assets/spike/option_a_kenney/apartment.png`
   - `assets/spike/option_a_kenney/school.png`
   - `assets/spike/option_a_kenney/hospital.png`
   - `assets/spike/option_a_kenney/power_plant.png`
3. Add `assets/spike/option_a_kenney/` to `pubspec.yaml`'s asset list.
4. Swap `paintAssetPlaceholder(...)` for an `Image.asset(...)` rendered into
   the canvas at the same iso anchor in [comparison_view.dart](comparison_view.dart).

### Option C — GenAI sprites

1. Use **Flux Schnell** (Apache 2.0) or **SDXL** with a fixed seed and a
   pinned prompt template, e.g.:
   ```
   isometric building, {type}, 2:1 isometric projection, viewed from
   southeast, clean kid-friendly cartoon style, soft pastel palette,
   transparent background, 256x256, --seed 42 --steps 4
   ```
2. Generate 5 sprites (one per building id) and save under
   `assets/spike/option_c_genai/<id>.png`.
3. Same pubspec + wiring change as Option A.

## Evaluation criteria (look at the PNG and score)

1. **Cohesion when adjacent.** Do the five buildings + road look like they
   belong to one city, or one of them looks "off"?
2. **Distinguishability at thumbnail size.** Can a kid tell house vs apartment
   vs school at a glance?
3. **Tier-upgrade plausibility.** Phase 8 wants 3 tiers per building with the
   same footprint, different textures. Does the approach support that?
4. **Time to produce 1 building.** Including curation.
5. **Projected effort for 40 buildings** (Phase 7 + 8 catalog).
6. **Licensing safety** for app-store distribution.

## Why we bothered

Phase 7 risk in [plan.md](../../../plan.md):
> *Isometric asset coverage gap — Kenney's City Kit packs are the starting
> point but limited; identify 1-2 supplementary CC0 packs in early Phase 7.
> If coverage is still sparse, narrow the v1 building catalog rather than
> ship inconsistent art.*

This spike is the cheapest experiment that lets us not narrow the catalog
later.
