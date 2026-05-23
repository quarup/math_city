# Math City — Implementation Plan

> Living document. Update as decisions are made and phases progress.
> Source of truth for product scope: [prd.md](prd.md).

---

## Status

- **Phase:** Phase 6 — Full Question Bank. Broad K–8 coverage; live counts (sub-concepts / widgets / datasets) live in the Status block of [curriculum.md](curriculum.md), auto-refreshed by [tools/curriculum/sync_implementation_status.py](tools/curriculum/sync_implementation_status.py). All §6.x widgets are now implemented (Chunk 78 closed the last three polish widgets — `Polygon`, `ScatterPlot`, `ColumnArithmetic`). The word-problem framework supports multiplication contexts on top of add/sub (Chunk 79). The dataset-ingestion sub-track is well into its audit phase (Chunk 80 ingested DeepMind `arithmetic.add_or_sub`; Chunks 81–83 audited DeepMind, MD-ES, and SVAMP; Chunk 84 wired the runtime so bundled items are actually playable end-to-end; Chunk 85 audited GSM8K and Chunk 86 ingested 4 GSM8K buckets; Chunk 87 audited MathQA — verdict skip; Chunk 88 ingested the audit's top-4 DeepMind variety submodules; Chunk 89 unlocked + ingested the audit's rank-#7 gap-fills via a new `AnswerFormat.commaList` and a format-aware keypad/MC gate). All 5 §7.2 datasets are now audited; the queue is exhausted.
- **Last updated:** 2026-05-21
- **Toolchain in the web sandbox:** The repo ships a `SessionStart` hook ([.claude/hooks/session-start.sh](.claude/hooks/session-start.sh)) that installs **Flutter 3.41.7** (same pin as CI) and runs `flutter pub get` automatically at the start of every Claude-Code-on-the-web session. **`flutter`, `dart`, `flutter analyze`, and `flutter test` are available** — always verify changes locally before committing; don't push code unseen and "rely on CI" as a substitute. The hook runs in async mode, so on a cold start there's a ~1–2 minute window where Flutter is still downloading; if a `flutter` command fails immediately at session start, wait a moment and retry once. A `PostToolUse` hook on `Write|Edit` ([.claude/settings.json](.claude/settings.json)) auto-runs `dart format` on any `.dart` file Claude touches, so the CI format step can't be tripped by drift.
- **Last action:** **Chunk 89 — DeepMind ingestion: audit's rank-#7 gap-fills (4 new dataset-only buckets, 800 items, runtime unblocked by `AnswerFormat.commaList` + format-aware keypad/MC gate)** — closes the last remaining DeepMind audit recommendation (per [deepmind.md](tools/question_generation/audits/deepmind.md) §"Recommended ingestion order" #7) by adding the four new sub-concepts the audit identified as genuine gap-fills: [closest_to_target](curriculum.md), [kth_value_in_list](curriculum.md), [sort_rationals](curriculum.md) (all §3.10 rationals, G6, prereq `compare_order_rationals`) and [function_evaluate_at_point](curriculum.md) (§3.11 prealgebra, G8, prereqs `evaluate_expression` + `linear_function_construct`). All four are dataset-only — no algorithmic generators planned. **Design choices locked at chunk start:** (1) **closest / kth_biggest normalised to value-MC at ingest**, NOT a new letter-MC widget — strip `(a)/(b)/(c)/(d)` prefixes, lift the letter-referenced value into `correctAnswer`, put the remaining 3 values as `distractors`. Items with only 3 candidates (a third of DeepMind's `kth_biggest` corpus) get a single synthesised plausible distractor via the new `_synth_compare_distractor` (±1, sign-flip, fallback whole-number guess). (2) **sort uses MC-only in v1** — at ingest we generate 4 candidate orderings per item (correct + reversed + adjacent-swap + fully-shuffled fallback); the `commaList` parser exists in `checkAnswer` so a free-response keypad can be added later without re-touching the ingester. (3) **polynomials.evaluate is integer-answer with a new prompt shape**, not a new answer format — `*` between coefficient and variable is stripped (`11*h` → `11h`), `**N` becomes Unicode superscript (`b**2` → `b²`), ASCII `-` → U+2212; cubics+ are filtered; coefficients capped at |c|≤50, input |x|≤20, answer |y|≤5000. **Runtime infrastructure (the unblocking work the audit called for):** added `AnswerFormat.commaList` to [generated_question.dart](lib/domain/questions/generated_question.dart) — entry-wise comparison via `Fraction`/`Decimal` parsers (`0.5 == 1/2` cross-type equivalence works, order matters, arbitrary whitespace around commas tolerated); `checkAnswer` in [answer_check.dart](lib/domain/questions/answer_check.dart) gets a `_checkCommaList` branch + `_parseListEntry` that tries `Decimal` first (stricter parser, then converts to `Fraction` for canonical compare) then falls through to `Fraction.tryParse` for `a/b`/`a b/c`/whole shapes. **Keypad/MC gate flipped from band-only to band + format**: new public `formatSupportsKeypad(AnswerFormat)` predicate in [question_screen.dart](lib/presentation/question/question_screen.dart) returns false for `string` and `commaList`, which means dataset items with non-numeric answer shapes now force MC mode even at the comfortable proficiency band (retroactively fixes the latent risk that string-format dataset items would have hit the keypad). **Dataset row schema:** Drift bumped to v6, new `answerFormat` text column on `dataset_questions` (default `"integer"` so the 13 pre-existing JSON files seed unchanged); migration follows the existing wipe-and-recreate pattern. `DatasetQuestion` value-type gains `answerFormat` field with `answerFormatToString`/`answerFormatFromString` helpers; `QuestionSource._datasetItemToGenerated` threads it onto `GeneratedQuestion`. **Per-item JSON schema** picks up an optional `"answer_format"` field; default integer; schema doc + ingester table updated in [tools/question_generation/README.md](tools/question_generation/README.md). **Ingester** — new [ingest_deepmind_gap_fills.py](tools/question_generation/ingest_deepmind_gap_fills.py) (~660 LOC), reuses `deepmind_common.py`'s ID hash + idempotent per-source writer. Four submodules driven separately, each with its own regex parser (letter-form + value-form for closest/kth_biggest; "Sort … in {increasing|ascending|decreasing|descending} order." for sort; "Let f(x) = … . Calculate f(c)." for poly_eval). Math verification rebuilt for each: closest checks the answer truly minimises distance; kth_biggest sorts all candidates and re-indexes; sort re-derives the canonical ordering; polynomials.evaluate parses the polynomial body into `(coef, exp)` terms and re-evaluates. Content-based dedup (correct + sorted distractors) replaces stem-only dedup so different items sharing "Which is the biggest value?" don't collapse. **Yields at default cap (200/concept):** `closest_to_target` 200 (339 attempts; 139 rejected as having <4 listed choices), `kth_value_in_list` 200 (clean), `sort_rationals` 200 (clean), `function_evaluate_at_point` 200 (959 attempts; 325 rejected for degree>2, 430 for coefficient magnitude, 4 for input magnitude). **Sync script extended** — [sync_implementation_status.py](tools/curriculum/sync_implementation_status.py) now also treats concept IDs present in bundled JSON files as implemented (the existing `read_implemented_generators` only checked `generator_registry.dart`, which would have stripped ✅ marks from these 4 dataset-only concepts every time it ran). **Catalog:** 4 new rows added in [curriculum.md](curriculum.md) §3.10 + §3.11; [concept_registry.dart](lib/domain/concepts/concept_registry.dart) regenerated. **Tests:** [answer_check_test.dart](test/domain/questions/answer_check_test.dart) gains 7 `commaList` cases (canonical, whitespace-tolerated, decimal↔fraction cross-type, order-matters, length-mismatch, unparseable-entry, single-value-off); [dataset_question_loading_test.dart](test/data/dataset_question_loading_test.dart) expanded bucket set from 29 → **33** and gains two roundtrip tests (`sort_rationals` items carry `AnswerFormat.commaList`; `add_within_100` items default to `AnswerFormat.integer`); new [format_supports_keypad_test.dart](test/presentation/question/format_supports_keypad_test.dart) covers every enum value. **571 total tests pass; analyze clean (modulo the pre-existing test-file lint). 364/366 sub-concepts (99%), 32/32 widgets, 2/5 datasets (DeepMind submodule coverage expanded; new-source counter unchanged).** Practical impact: the DeepMind audit's recommended ingestion order is now fully exhausted; the 3 remaining audit ranks (#5 `numbers.gcd`/`lcm`, #6 `is_prime`/`is_factor`/`list_prime_factors`) are pure variety on top of existing G6 number-theory generators — deferred indefinitely.
- **Next action:** Coverage and widgets are done (360/362 sub-concepts, 32/32 widgets). The 2 unimplemented sub-concepts are formally deferred (`construct_triangle_given` G7, `derive_y_eq_mx_b` G8 — see curriculum.md §3). Runtime wiring landed in Chunk 84 — bundled dataset items now actually flow through the question screen alongside generators. Phase 6 remaining work is non-generator:
  - **Dataset ingestion sub-track** (1 / 5 datasets integrated; DeepMind audited in Chunk 81; MD-ES audited in Chunk 82 — verdict skip-entirely; SVAMP audited in Chunk 83 — verdict drop on licence; runtime mix policy live as of Chunk 84). Real options going forward:
    - **Audit the remaining 2 datasets** (GSM8K, MathQA). MathQA (#4) next — smaller scope (geometry coverage and algebra MC); confirm Apache 2.0 cleanness and check whether the geometry slice adds value over our procedural diagrams. After MathQA: GSM8K (#2) — the long-term highest-leverage audit because it's the only GREEN source for rich grade 3–6 word problems but also the largest (8,500 items). Same pattern as Chunks 81/82/83: an `audit_<dataset>.py` script + a hand-edited `<dataset>.md` verdict.
    - **Selective DeepMind expansion**, only the highest-ROI submodules per [deepmind.md](tools/question_generation/audits/deepmind.md): `numbers.place_value`, `measurement.time`, `arithmetic.mul` (whole-number subset), `numbers.round_number`. Each is a small Python ingest + a curriculum.md source flip for the affected concepts; runtime is already wired.
  - **Tuning the mix policy** — the `poolSaturationSize = 50` constant in [question_source.dart](lib/domain/questions/question_source.dart) is a guess; revisit after some playtime to see whether kids prefer more variety / generator polish / something asymmetric.
  - **Adaptive system tuning** — refine band thresholds per grade-band, refine α learning rate, consider asymmetric reward/penalty. Needs playtest data first.
  - **Validate full catalog with kids** in grades K, 2, 4, 6, 8 (Phase 6 exit criterion).
  - **Spoiler-aware retrofits skipped** — `unit_rate`, `unit_pricing`, `convert_units_using_ratio`, `constant_speed` (3 question shapes) would all want DoubleNumberLine but the unit-rate position **is** the answer — putting it on the diagram defeats the question. Either need a "value-hidden" tick variant or stay text-only. `equivalent_ratios` would want TapeDiagram but scaled values reach 36 — too many cells. All five deferred.
- **Deferred:** Audio SFX + background music (CC0 assets not sourced yet — stub in place). iOS verification. Both revisit before Phase 12 at latest.

- **City builder design (planning, 2026-05-21):** Phases 7–8 (city builder) were restructured into Phases 7–9 in a planning conversation. Phase 7 now ships a small "Simple DAG Proof" (~10 buildings, ~5 beats, multi-gate DAG, citizen-bubble UI); Phase 8 is a research + content-design phase that produces a new `city_builder.md` cataloging the full DAG (hundreds of buildings) and beat scripts; Phase 9 implements that content. Phases 9–12 from the old plan shifted to 10–13. PRD City Builder section rewritten accordingly. Currency model (rename `stars` → e.g. `bricks`, or multi-resource by concept family) is now an Open Question to lock at Phase 7 start.

---

## Locked Decisions

| Area | Choice | Rationale |
|---|---|---|
| **Framework** | Flutter (stable channel) + [Flame](https://flame-engine.org/) game engine | Single codebase for iOS+Android; Flame actively maintained in 2026 (Flame Game Jam 2026 ran in March); BSD-licensed; provides sprite/animation/gesture primitives we need for the spin wheel and avatar |
| **Language** | Dart 3.x | Required by Flutter |
| **State management** | [Riverpod](https://riverpod.dev/) 3.x | Recommended default for new Flutter projects in 2026; compile-time safety, low boilerplate, great testability |
| **Local persistence** | [Drift](https://pub.dev/packages/drift) (SQLite + compile-time-safe queries) | Best-supported in 2026 (Hive and Isar are now community-maintained after author stepped away); SQL is great for filtering questions by concept+difficulty band; predictable migrations |
| **Audio** | [`flame_audio`](https://pub.dev/packages/flame_audio) (wrapper over `audioplayers`) | Natural fit with Flame; supports SFX pools and background music |
| **Cloud save** | [`games_services`](https://pub.dev/packages/games_services) package — Google Play Games (Android) + Game Center / iCloud (iOS) | Only solution that satisfies the PRD's "no custom server" requirement on both platforms with a single API. Last updated Dec 2025 |
| **Concept granularity** | Track proficiency at **sub-concept** level (e.g. "2-digit addition with carry"), not at category level. Roll up to category for display only | Otherwise the adaptive wheel is too coarse: a kid who's mastered single-digit addition would falsely look ready for multi-digit. See PRD's Concept System section for the category→concept taxonomy |
| **Cosmetics economy** | Single sink for stars: **city builder only**. Avatar is free to customize and not tied to the economy | Phase 4 spike found no Flutter avatar library combines full-body rendering with rich accessory slots — building hat/costume/shoes/backpack overlays on top of a bust-only library was more work than the variety it would buy. City builder alone is plenty of long-arc motivation |
| **Avatar rendering** | **DiceBear Adventurer** style, rendered **fully offline** via local SVG composition using `flutter_svg`. The DiceBear Adventurer SVG component paths (MIT-licensed code, CC BY 4.0 design by Lisa Wischofsky) are bundled in-app as Dart string constants; the composer assembles them at runtime. Player picks from a curated subset of slots (hair style/color, skin tone, eyes, mouth, glasses, earrings, blush/freckles); free to re-edit anytime | Cleanest off-the-shelf look for kids. Fully offline — no network calls, no INTERNET permission needed. `dice_bear` pub package rejected because it calls `api.dicebear.com` at runtime — a showstopper for a kids app that must work without WiFi |
| **City rendering** | Isometric tiles, fixed grid, **auto-generated roads** between buildings | Mobile-friendly: tile-snap + auto-roads avoid fiddly placement; established CC0 isometric packs (e.g. Kenney City Kit) cover the style |
| **Milestones** | **Removed.** Replaced by per-item star prices and total-stars-earned thresholds for unlocking new building types and themed maps | Milestones were dead weight once the city builder provides natural long-arc progression — every land expansion or new building tier *is* a milestone moment |
| **Curriculum standard** | US Common Core State Standards (CCSS) for Mathematics, K–8 | Most thoroughly documented free K–8 standard; aligned to most public datasets; the resulting taxonomy stays standard-agnostic enough to work for kids on UK/IB/other systems. Full taxonomy in [curriculum.md](curriculum.md) |
| **Diagram strategy** | Mostly procedural SVG / `CustomPainter` widgets, parameterized by question params. Text-only fallback where rendering cost is prohibitive (3D nets, long-division layouts) | A small set of 8 high-ROI widgets (FractionBar, NumberLine, Clock, BarChart, RectangleArea, CoordinatePlane, Angle, Spinner) unlocks ~70% of non-arithmetic K–8 content. Cleaner than bundled images; works at any size; fits the "feels infinite" goal |
| **Question source mix** | ~85% algorithmic (with procedural diagrams) + ~10% bundled curated datasets + ~5% deferred. **No runtime LLM calls; no offline LLM batch generation in v1.** | Generators store compactly and feel limitless. Datasets fill rich-word-problem gaps where templates produce nonsense. Offline LLM batch is deferred to see how far the first two get us. See [curriculum.md §8](curriculum.md) |
| **Curriculum reference** | [curriculum.md](curriculum.md) is the canonical source of the concept catalog (taxonomy, prereq DAG, source strategy per sub-concept, diagram widget catalog, dataset inventory). plan.md only references it | Avoids duplication; keeps plan.md focused on phase execution |
| **Repo plan doc** | `plan.md` at repo root | Simple, greppable, lives next to `prd.md` |
| **AI agent doc** | `CLAUDE.md` at repo root | Emerging convention; auto-loaded by Claude Code each session |

---

## Architecture Overview

Four layers, top to bottom:

1. **Presentation (Flutter widgets)** — screens, navigation, forms (player creation, avatar editor, progress screen, settings, city screen).
2. **Game (Flame components)** — spin wheel, question presentation, animations, audio cues, isometric city renderer.
3. **Domain (pure Dart)** — game rules: concept-band classification, proficiency updates, wheel selection logic, star math, city growth model. **No Flutter or Flame imports here** — keeps it unit-testable and portable.
4. **Data (Drift + cloud-save)** — local SQLite for player profiles, proficiency records, owned items; question catalog as a read-only seeded table; cloud-save bridge for backup/restore.

State management (Riverpod) sits at the boundary between presentation and domain — providers expose domain objects to widgets reactively.

---

## Data Model (sketch — refined per phase as we go)

```
Player
  id, name, gradeLevel, createdAt
  avatarConfig          // JSON: DiceBear Adventurer slot picks (hair, skin, eyes, mouth, glasses, etc.)
  currencyBalance       // spendable balance — name and shape (single int vs. multi-resource map) decided in Phase 7
  lifetimeCurrencyEarned// never decreases — drives progressive unlocks
  currentStreak, lastPlayedDate

ConceptProficiency
  playerId, conceptId, proficiency (0.0–1.0), lastUpdatedAt
  questionsAnswered, questionsCorrect

Concept (static catalog) — sub-concept granularity (e.g. "2-digit addition with carry")
  id, name, categoryId, gradeRange, description

ConceptCategory (static catalog) — display grouping only (e.g. "Addition & subtraction")
  id, name, displayOrder

Question (static catalog for non-arithmetic concepts; arithmetic generated at runtime)
  id, conceptId, difficultyBand (comfortable | challenging),
  prompt (text or template), correctAnswer,
  distractors (for multiple-choice), explanation (for wrong-answer screen)
  source (algorithmic | curated | ai_generated), license

// --- City builder (Phase 7+; full catalog populated through Phase 9) ---

City (per player, per map)
  id, playerId, mapId,
  gridWidth, gridHeight,         // grows on land expansion (Phase 9)
  population

CityMap (static catalog)
  id, name, theme (countryside | city | futuristic | …),
  baseGridWidth, baseGridHeight,
  unlockCost,                    // 0 for the beginner map; recipe depends on currency model
  terrainSeed                    // deterministic terrain layout

BuildingType (static catalog — registry in code, mirrored in `city_builder.md §3`)
  id, name, category (civicHousing | services | commercial | entertainment),
  cost,                          // currency cost — shape depends on Phase 7 currency decision
  unlockRule,                    // typed value: AND-combination of {minLifetimeCurrency, requiredBuildingsPlaced[], minPopulation, requiredBeatsFired[]}
  populationContribution,         // residents this building houses, if any
  serviceProvision,               // map of {clinic: N, power: N, school: N, …}
  varietyContribution,            // 0/1 — whether this type counts toward its category's variety multiplier
  maxTier, assetRefByTier

BuildingPlacement
  id, cityId, buildingTypeId, currentTier, gridX, gridY, placedAt
  // placedAt enables the "building age" beat trigger

StoryBeat (static catalog — registry in code, mirrored in `city_builder.md §4`)
  id, category (demand | praise | warning),
  triggerRule,                   // typed value: AND-combination of {buildingsPresent[], buildingsAbsent[], minPopulation, minBuildingAgeForX, requiredBeatsFired[], minCurrencyEarnedSinceLastBeat}
  emoji, shortStickerLabel,
  longText,                       // shown when the bubble is tapped
  tone (silly | civic | cozy),    // for narrative-mix tuning
  cooldownAfterAck                // how many rounds before this beat can re-fire

StoryBeatState (per player, per beat)
  playerId, beatId,
  state (neverFired | onScreen | dismissed | acked),
  lastFiredAtRound,
  fireCount

GameSession (in-memory only)
  startedAt, players (list), roundsPlayed
  // Streak lives on Player, not here
```

**Notes:**
- `Item`, `Milestone`, and `AvatarAccessory` from earlier sketches are removed. The only currency sink is the city builder; the avatar is free to customize.
- **Currency naming/shape is deliberately abstract** in this sketch because the choice between a single-currency rename and a multi-resource model is an Open Question. When the decision lands in Phase 7, the `currencyBalance` / `lifetimeCurrencyEarned` / `cost` / `unlockCost` fields become either single ints or maps keyed by material.
- `currencyBalance` vs. `lifetimeCurrencyEarned`: spending decreases `currencyBalance`; both correct *and* spent currency count toward `lifetimeCurrencyEarned` for unlock gating (so spending doesn't lock players out of progression).
- `unlockRule` and `triggerRule` are AND combinations of multiple optional conditions. The shape is intentionally typed-but-extensible — Phase 7 ships with the conditions listed above; Phase 9 may add more (e.g. "season" or "time-of-day") if research surfaces a need.
- `serviceProvision` + `varietyContribution` together drive the growth model: aggregate service ratios cap population for under-served categories, and category variety bonuses encourage a balanced mix (monotone cities stall).
- The static `BuildingType` / `StoryBeat` catalogs live as Dart registries (`building_registry.dart` / `beat_registry.dart`) authored against `city_builder.md`, mirroring how `generator_registry.dart` mirrors `curriculum.md`. A sync script (Phase 9) keeps the ✅ markers in `city_builder.md` honest.

---

## Domain Specs (set during Phase 0)

### Initial concept scope for Phase 1

Phase 1 ships **two concepts**, both pure single-digit arithmetic:

| Concept ID | Description | Operand range | Result range |
|---|---|---|---|
| `add_1digit` | Single-digit addition | a, b ∈ [0, 9] | sum ∈ [0, 18] |
| `sub_1digit` | Single-digit subtraction (no negatives) | minuend ∈ [0, 18], subtrahend ∈ [0, 9], a ≥ b | diff ∈ [0, 18] |

Both are algorithmically generated at runtime (no curated dataset needed). Distractors for multiple-choice are constructed from common mistakes: off-by-one (±1), swapped operands, and a randomly-chosen value within ±5 of the correct answer.

Why these two: universally familiar across the entire 6–14 target age, trivially generatable, and two-concepts-on-the-wheel is enough to make the spin feel like a real choice without needing the full catalog.

### Phase 2 concepts

| Concept ID | Description | Operand range | Result range | Notes |
|---|---|---|---|---|
| `mul_1digit` | Single-digit multiplication | a, b ∈ [1, 9] | product ∈ [1, 81] | Skip ×0 and ×1 as trivial |
| `div_1digit` | Single-digit division (exact) | divisor ∈ [2, 9], quotient ∈ [1, 9] | quotient ∈ [1, 9] | Generated as quotient×divisor=dividend; no remainders |
| `add_2digit` | 2-digit addition | a, b ∈ [10, 99] | sum ∈ [20, 198] | |
| `sub_2digit` | 2-digit subtraction (no negatives) | minuend ∈ [10, 99], subtrahend ∈ [10, 99], a ≥ b | diff ∈ [0, 89] | |

All four are algorithmically generated at runtime. Distractors use the same strategy as Phase 1 (off-by-one, operand swap, random ±5).

Fractions, geometry, and word problems are introduced in Phase 5/6 (Curriculum & Question Bank — see [curriculum.md](curriculum.md)).

### Proficiency update formula (sketch — refine in Phase 2)

Proficiency `p` per (player, concept) lives in [0.0, 1.0]. After each answer:

```
p_new = clamp(p_old + α · (target - p_old), 0.0, 1.0)
```

where `target = 1.0` on correct, `target = 0.0` on wrong, and `α` is a learning rate. Proposed initial `α = 0.1`.

Properties of this update:
- Stable: one wrong answer can't tank a player's score
- Asymptotic toward target — quick at first, slows near 0 or 1
- O(1), no history needed
- Easy to unit-test (deterministic, monotonic)

**Band thresholds (initial, tunable in Phase 2):**

| p range | Band | Action |
|---|---|---|
| `p < 0.2` | not yet | Excluded from wheel |
| `0.2 ≤ p < 0.5` | challenging | On wheel; correct = 5 stars; multiple choice |
| `0.5 ≤ p < 0.85` | comfortable | On wheel; correct = 3 stars; typed input |
| `p ≥ 0.85` | mastered | Excluded from wheel |

**Initial value** when a player first encounters a concept:
- Concept grade ≤ player's stated grade: start at `p = 0.4` (challenging band)
- Concept grade > player's stated grade: start at `p = 0.05` (not yet, off the wheel)

Open Phase 2 knobs: tune `α`, asymmetric reward/penalty (e.g. wrong answers move p down faster than right answers move it up), threshold values, and whether to consider time-since-last-attempt (proficiency decays if not practiced).

---

## Project Structure (planned)

```
math_city/
├── prd.md
├── plan.md
├── CLAUDE.md
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── presentation/      # Flutter widgets: screens, navigation
│   │   ├── home/
│   │   ├── player/        # includes avatar editor (DiceBear slot pickers)
│   │   ├── city/          # city-builder screen + bubble overlays (Phase 7+)
│   │   ├── progress/
│   │   └── settings/
│   ├── game/              # Flame components
│   │   ├── spin_wheel/
│   │   ├── city/          # isometric city renderer (Phase 7+)
│   │   ├── question_view/
│   │   └── effects/
│   ├── domain/            # pure Dart: rules, no Flutter imports
│   │   ├── concepts/
│   │   ├── proficiency/
│   │   ├── questions/
│   │   ├── stars/
│   │   ├── avatar/        # AdventurerConfig + curated slot catalogs
│   │   └── city/          # buildings, beats, DAG unlock engine, growth model (Phase 7+)
│   │       ├── building_registry.dart   # mirrors city_builder.md §3
│   │       ├── beat_registry.dart       # mirrors city_builder.md §4
│   │       ├── beats/                   # individual hand-written beats
│   │       ├── unlock_engine.dart       # multi-gate DAG evaluation
│   │       └── growth_model.dart        # service ratios + variety multiplier
│   ├── data/              # Drift schema, repositories, cloud-save bridge
│   │   ├── database.dart
│   │   ├── repositories/
│   │   └── cloud_save/
│   └── shared/            # theme, widgets, constants
├── assets/
│   ├── images/
│   ├── audio/
│   └── data/              # bundled question catalog (JSON, loaded into Drift)
├── test/
│   └── domain/            # bulk of tests live here — pure logic
└── tools/
    └── question_generation/  # offline scripts to expand the question bank
```

---

## Phase Roadmap

Each phase ends with something demonstrable. We do **not** start a phase until the previous one is "done enough" to ship internally.

### Phase 0 — Foundation (complete)
- [x] Flutter SDK installed (3.41.7); `flutter create` scaffold for iOS+Android with org `com.quarup`
- [x] Locked dependencies installed: `flame`, `flutter_riverpod`, `riverpod_annotation`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`, `flame_audio`, `games_services`; dev deps `build_runner`, `drift_dev`, `very_good_analysis`. Skipped `riverpod_generator` + `riverpod_lint` + `custom_lint` due to a Riverpod-3 / analyzer incompatibility — revisit when ecosystem catches up
- [x] Linting (`very_good_analysis`); `dart format` clean
- [x] GitHub Actions CI: format check + analyze + test on push/PR (`.github/workflows/ci.yml`)
- [x] Initial concept scope for Phase 1 decided — see *Domain Specs* above
- [x] Proficiency-update math sketched — see *Domain Specs* above
- [x] **Exit criteria (Path B — Android only):** `flutter run` launched the placeholder Math City app on the Android emulator (Pixel 7, API 34) successfully. iOS verification deferred to Phase 11
- [ ] iOS exit criteria — deferred until Xcode is installed (no later than Phase 11)

### Phase 1 — Vertical Slice (target: ~2–3 weeks) [the most important phase]
**Goal: prove the core loop is fun.** Hardcoded single player, two concepts, no persistence beyond runtime. Concepts and proficiency math are specified in *Domain Specs* above.
- [x] Concept registry with the two Phase 1 concepts (`add_1digit`, `sub_1digit`)
- [x] Algorithmic question generator with operand ranges per spec; distractor strategy per spec
- [x] `SpinWheel` Flame component (4 segments, tap-to-spin animation, lands on a concept)
- [x] `QuestionScreen` with 4-option multiple choice
- [x] `ResultScreen` with star award + wrong-answer explanation
- [x] Loop: home → spin → question → result → home, with star counter persisted in memory
- [ ] Basic SFX (spin, correct, wrong) and one looping background track — deferred to Phase 10 (CC0 assets not sourced; stub in place)
- [x] **Exit criteria:** Test with a real kid in the target age range — passed.

### Phase 2 — Adaptive Concept System (target: ~2–3 weeks)

**Design decisions (locked):**
- **Player:** A single default player is seeded into Drift on first launch. Full player creation / profile picker is Phase 3.
- **Numeric input UX:** Comfortable-band questions use an on-screen number pad (calculator-style) with an explicit submit button. Device keyboard not used. Text-answer question types deferred.
- **Concept expansion:** Only algorithmically generatable concepts added this phase (see *Domain Specs — Phase 2 concepts* below). Fractions, geometry, and word problems deferred to Phase 5/6 (Curriculum & Question Bank).

- [x] Drift schema for `Player` and `ConceptProficiency`; seed default player on first launch
- [x] Proficiency update logic (correct → up, wrong → down with floor); unit tests
- [x] Band classifier (mastered / comfortable / challenging / not yet) with grade-aware thresholds
- [x] Wheel selection: weighted sample of comfortable + challenging bands only
- [x] Number-pad input mode for comfortable-band concepts (on-screen pad + submit button)
- [x] Add 4 new concepts: `mul_1digit`, `div_1digit`, `add_2digit`, `sub_2digit` (all algorithmic)
- [ ] **Exit criteria:** A returning player sees the wheel adapt — easy concepts disappear, harder ones appear, number-pad input shows up for concepts they've practiced

### Phase 3 — Player Profiles & Avatar (complete)
- [x] Player creation flow (name, grade, basic avatar)
- [x] Profile picker on app launch
- [x] Mid-session player switching at start of each round (SpinScreen AppBar)
- [x] CustomPainter chibi avatar (slots: skin tone, hair, eyes, shirt, pants — drawn in Flutter, no external assets)
- [x] **Exit criteria:** Two kids can share the device with separate stats and avatars

**Open question resolved:** Avatar art sourced as pure Flutter CustomPainter (no external sprites). Simple geometric "chibi" style — works at all sizes, zero asset licensing burden.

### Phase 4 — DiceBear Avatar + Persistent Stars (target: ~3–5 days)

**Goal:** Replace the Phase 3 CustomPainter chibi with a DiceBear Adventurer avatar that the player can edit anytime. Stars persist across app restarts so they're meaningful as a Phase 7 city-builder currency.

**Spike outcome (already done):** DiceBear chosen — Adventurer style. Multiavatar disqualified (identicon, not dress-up). avatar_maker rejected (no real advantage over DiceBear, same bust-only limitation). Avatar accessory shop dropped from scope — see *Locked Decisions* for rationale.

**Curated slot subset (v1 — tunable in this phase):**
- Hair style: ~8 options (mix of short + long picks from adventurer's 45)
- Hair color: ~6 options
- Skin color: 4 options (DiceBear default palette)
- Eyes: ~5 variants
- Mouth: ~5 variants
- Glasses: 5 variants + none
- Earrings: 4 variants + none
- Optional features: blush, freckles (toggles)

(Eyebrows, mustache, birthmark deliberately skipped — too granular for kids; keep the picker tight.)

**Tasks:**
- [x] Add dep: `flutter_svg` (SVG renderer for local DiceBear SVG composition). `dice_bear` pub package rejected — calls `api.dicebear.com` at runtime, requires INTERNET permission; replaced by bundled SVG path constants
- [x] `domain/avatar/AdventurerConfig` — pure Dart record of the curated slot picks; serializes to JSON for storage
- [x] `domain/avatar/adventurer_catalog.dart` — the curated lists of slot values (the "~8 hair styles, ~5 eye variants" sets)
- [x] `presentation/player/adventurer_avatar_widget.dart` — widget that renders an `AdventurerConfig` via `SvgPicture.string` (offline, no network)
- [x] Drift schema migration (v3): wipe and recreate; split `totalStars` → `currentStars` + `lifetimeStarsEarned`
- [x] Avatar editor screen: per-slot pickers (ChoiceChips + color swatches), live preview at top; reachable from profile picker (edit) and new-player creation
- [x] Star-award flow writes `currentStars` and `lifetimeStarsEarned` to Drift on each correct answer
- [x] Render the new avatar on home, spin, and creation screens; deleted old `avatar_widget.dart` + `avatar_config.dart`
- [x] Tests: `AdventurerConfig` serialization round-trip (4 cases pass); all 51 tests pass, `flutter analyze` clean
- [x] **Exit criteria:** Player creates a profile, picks an adventurer look, plays a round, sees the avatar on every screen, earns stars, kills and reopens the app — same avatar, same stars. From the profile picker they can re-open the editor and change their hair, and the new look shows up everywhere.

---

### Phase 5 — Curriculum & Generator Framework (target: one Claude Code conversation)

**Goal:** Wire the [curriculum.md](curriculum.md) catalog into the app and build the foundational architecture for question generators and diagram widgets. Throw out Phase 1–2 generators wholesale and rewrite as curriculum-aligned decompositions. Cover ~20 sub-concepts in the K–3 range broadly. Wire DAG-based drip-feed introduction with an unlock celebration.

**Research outcome (already done — see Status block):** [curriculum.md](curriculum.md) defines the 12-category, ~361-sub-concept K–8 taxonomy with per-sub-concept question-source strategy, diagram requirements, and prereq DAG.

**Locked design decisions for this phase:**
- **Generator migration: full rewrite, not rename.** The existing 6 Phase 1–2 generators (`add_1digit`, `sub_1digit`, `mul_1digit`, `div_1digit`, `add_2digit`, `sub_2digit`) are deleted from code and tests. Replaced with curriculum-aligned decompositions (e.g. `add_1digit` → `add_within_5` + `add_within_10` + `add_within_20`).
- **Catalog vs implemented: clean schema.** All ~361 concepts are seeded as plain rows; no `is_implemented` column. Wheel eligibility checks an in-memory generator registry. Known limitation: a player can in theory hit `mastered` on a leaf whose DAG children aren't yet implemented; that branch's growth pauses until Phase 6 fills the gap. Acceptable trade-off.
- **DAG drip-feed semantics.** New player starts with 2 implemented concepts (lowest grade, lowest within-category row order). One new concept is introduced per mastery event. A concept is eligible for introduction only when all its DAG prereqs are `mastered` *and* its generator is registered. **No cross-domain gating** — independently per branch. **Pick policy:**
  1. Among eligible concepts, pick the lowest `Grade` first.
  2. Tiebreak by category: prefer the category in which the player currently has the *fewest active concepts* (introduced-but-not-mastered) — keeps the wheel balanced across math domains.
  3. Within the chosen category, pick the lowest row position in the [curriculum.md](curriculum.md) §3.x table for that category. Per `curriculum.md` design principle 8, that row order is the curated within-grade difficulty signal. **No global cross-category difficulty order exists** — re-sorting one category never touches another.
- **Unlock UI moment.** A "New concept unlocked!" celebration card is shown after the result screen, but only on correct answers that triggered either a mastery event or a queue advance. Never on wrong answers — this avoids the confusing scenario where a kid gets a question wrong but sees a celebratory unlock.
- **Word-problem framework: deferred to Phase 6.** This phase already covers schema migration + framework architecture + ~12 migrated + ~10 new generators + 3 diagram widgets + DAG engine + unlock UI. The word-problem framework (name/item/verb pools + 1-step template engine) and its first dataset-tagged sub-concept moved to Phase 6.
- **Drift v4: wipe-and-recreate.** No real users yet, so the existing v3 migration pattern is fine. A proper additive-migration implementation is now a prerequisite task in Phase 11 (Cloud Save) — once player data lives off-device, wipes destroy real data.
- **Wheel segment count.** Fixed cap at 8. The wheel renders `min(introducedConceptCount, 8)` segments and never more.

**Tasks:**
- [x] Drift schema v4: `Concepts` table (catalog with `categoryId`, `primaryGrade`, `prereqIdsCsv`, `sourceStrategy`, `diagramRequirement`, `categoryRowOrder`) + `IntroducedConcepts` table. Wipe-and-recreate migration
- [x] ~~Generate `assets/data/concepts.json`~~ — **shipped as a Dart const** in `lib/domain/concepts/concept_registry.dart` (22 implemented + ancestor concepts). Drift seeds from this on first run via `_seedConceptCatalog`. Authoring the JSON pipeline + parser is queued as a Phase 6 cleanup item so the full ~361-row catalog can be ingested
- [x] `GeneratedQuestion` + `DiagramSpec` architecture in `lib/domain/questions/` (pure Dart, no Flutter imports). Sealed `DiagramSpec` family: `FractionBarSpec`, `NumberLineSpec`, `ClockSpec`
- [x] `GeneratorRegistry` — in-memory `Map<String, QuestionGenerator>` keyed by `conceptId`. Wheel-eligibility filter and DAG drip-feed both consult it
- [x] **Replaced** the existing 6 Phase 1–2 generators wholesale (old files + tests deleted):
  - `add_within_5`, `add_within_10`, `add_within_20`
  - `sub_within_5`, `sub_within_10`, `sub_within_20`
  - `mult_facts_within_100`
  - `div_facts_within_100`
  - `add_within_100`, `add_2digit_carry` (forced-carry constraint)
  - `sub_within_100`, `sub_2digit_borrow` (forced-borrow constraint)
  - Each uses the `integerDistractors` library + procedural step-by-step explanation template
- [x] DAG drip-feed engine in `lib/domain/concepts/dag_engine.dart`. On a mastery event picks the next concept whose DAG prereqs are all `mastered` and whose generator is registered, and adds it to introduced. Returns an `UnlockEvent` so the UI can react. Pick policy: lowest grade → category with fewest active concepts → row order
- [x] Starter-pack initialization: 2 easiest implemented concepts at-or-below the player's grade. Lazily populated on first read of `introducedConceptsProvider`
- [x] "New concept unlocked!" UI moment: amber card on the result screen after a correct answer that produced an `UnlockEvent`. Suppressed on wrong answers (the caller passes `unlockEvent: null` when `!isCorrect`)
- [x] First 3 high-ROI new generator families per [curriculum.md §5.1](curriculum.md):
  - **Multi-digit ± with regrouping** — `add_within_1000`, `sub_within_1000`, `add_multidigit_standard_alg`, `sub_multidigit_standard_alg`
  - **Fraction generators** — `fraction_a_over_b`, `equivalent_fractions_visual`, `compare_fractions_same_denom`, `add_fractions_like_denom` (uses `FractionBar`)
  - **Time-telling** — `time_to_hour_half`, `time_to_5_min` (uses `Clock`)
- [x] First 3 diagram widgets in `lib/presentation/diagrams/`: `FractionBar`, `NumberLine`, `Clock`, plus a `DiagramRenderer` dispatcher that switches on the sealed `DiagramSpec`. Each is parameterised; question screen places the diagram above the prompt card when `q.diagram != null`
- [x] Updated `wheelConceptsProvider`: filters to `introduced ∩ generator-registered ∩ in-band`, takes the easiest `min(n, 8)`. Sorted by difficulty so wheel layout is stable. Per-category color palette in `spin_screen.dart`
- [x] Tests (91 total, all passing):
  - Catalog invariants (unique IDs, prereq references resolve, prereq grade ≤ dependent grade, every concept's category resolves)
  - `integerDistractors` + `integerDistractorsWith` + `stringDistractorsFromPool`
  - Per-generator parameter range + answer correctness + distractor uniqueness (≥200 iterations each)
  - `add_2digit_carry` always forces ones-sum ≥ 10; `sub_2digit_borrow` always forces minuend ones < subtrahend ones
  - `DripFeedEngine` starter pack + pickNext semantics (synthetic catalog + real catalog)
  - `ProficiencyNotifier.recordAnswer` × `UnlockEvent` matrix: returns event only when correct answer crosses 0.85; null on wrong answer (even at 0.84); null on correct that doesn't cross; null on already-mastered
  - Starter pack persistence: fresh player gets `add_within_5` + `sub_within_5` introduced on first read, stored in DB
- [x] **Exit criteria:** code complete and play-tested on the Android emulator (2026-05-10). Wheel + drip-feed + unlock card all behaved as expected in-hand. Test suite verified the unlock-card flow (suppressed on wrong answers, fired only on correct mastery transitions); the 3 diagram widgets compile and analyze clean; old `add_1digit`-style generators are gone from code and tests.

---

### Phase 6 — Full Question Bank (target: ~4–6 weeks)

**Goal:** Round out coverage to the full K–8 catalog. Build the word-problem framework (deferred from Phase 5). Build remaining diagram widgets and generators. Ingest bundled datasets for word problems and conceptual judgment items.

**Approach (locked):** Generators-first within Phase 6 — extend algorithmic coverage ahead of the dataset ingestion pipeline so each landed generator immediately produces playable content. The dataset sub-track is plumbing that delivers nothing until it's all done; we come back to it after the algorithmic surface is broad. Hand-curation of ~1500 gap-fill items is **punted out of v1** — rely on algorithmic + GREEN datasets for coverage.

**Tasks (in execution order):**

*Catalog foundation*
- [x] **Pre-Phase-6 cleanup (carried over from Phase 5):** `tools/curriculum/build_catalog.dart` parses [curriculum.md](curriculum.md) §3.x tables and regenerates `lib/domain/concepts/concept_registry.dart` (Dart const). 362 concepts × 12 categories now seeded. Two override maps live in the parser: `_shortLabelOverrides` for kid-facing wheel labels, `_prereqOverrides` for transitional DAG simplifications that drop curriculum.md prereqs whose generators don't exist yet (each entry keyed for one-line removal as new generators land). Parser includes a build-time grade-DAG validator that mirrors the catalog-invariant test. Surfaced two curriculum.md inconsistencies on first run (`simplify_fraction` and `add_fractions_unlike_denom` both listed grade-6 GCF/LCM as prereqs); fixed by dropping the formal prereq, since informal simplification/common-denominator works pre-grade-6.

*Tooling*
- [x] **Debug screen for testing generators in isolation** ([lib/presentation/debug/concept_debug_screen.dart](lib/presentation/debug/concept_debug_screen.dart)). kDebugMode-only chip on the home screen → tree of implemented concepts grouped by category → tap to play one question against that generator. Top-bar segmented toggle picks Multiple-choice vs. Keypad answer mode (necessary because some bugs only manifest in one mode). Bypasses the wheel, the DAG drip-feed, the proficiency write, the star award, and the unlock card so a debug session leaves the player profile untouched. `ResultScreen` "Try another" button pops back to the picker. Both UI entry points and the screen itself are gated by Flutter's `kDebugMode` constant — tree-shaken out of release builds.

*Generators-first sub-track (priority list #5 onward, with diagram widgets interleaved as each generator family needs them)*
- [x] **Word-problem framework v1** in [lib/domain/questions/word_problems/](lib/domain/questions/word_problems/): 25 culturally-balanced names, 20 plural items (4 city-builder-themed: bricks, paint cans, traffic cones, road signs), `composeWordProblem` template helper. The `WordProblemContext` carries an `op` (add | sub) and an optional `requiresEdibleItems` flag so the `eats` context never picks bricks. Subjects referred to by repeated name (no pronouns) to sidestep gender encoding.
- [x] **`add_word_problems_within_100`** — covers both addition and subtraction (the curriculum row is `+/−`). 6 contexts total: 3 add (`collects`, `is_given`, `buys`) + 3 sub (`gives_away`, `eats`, `loses`). Quantities ≥ 2; sum ≤ 100 for add, result ≥ 2 for sub. Misconception distractor: opposite operation.
- [x] **Place-value (3 generators)**: `place_value_2digit`, `place_value_3digit`, `place_value_multidigit` (4–7 digit, comma-formatted). Single-digit answer pool; misconception bias = "wrong digit from the same number".
- [x] **Rounding (3 generators)**: `round_to_10`, `round_to_100`, `round_multidigit_any_place` (place ∈ {10, 100, 1k, 10k, 100k}). Misconception bias = "rounded the wrong direction".
- [x] **Signed-integer arithmetic (3 generators)**: `integers_add`, `integers_subtract`, `integers_multiply_divide`. Kid-textbook display (parens around trailing-operand negatives). Implemented-grade ceiling moved G5 → G7.
- [ ] Extend the word-problem framework: multiplication contexts (`builds`, `bakes/makes`, `saves`) → needs concept-ID design call (curriculum.md doesn't have `mult_word_problems_within_100` per design principle 4); then 2-step (`add_sub_2step_word_problems`) once the shape is settled.
- [ ] Remaining algorithmic generators per [curriculum.md §5.1](curriculum.md) priority list (#6 onward): signed-number arithmetic, coordinate-plane, order-of-operations / expression evaluation, percent / unit-rate / proportion, area / perimeter, one-/two-step equations, angles, Pythagorean theorem, probability, place-value / rounding / scientific notation, summary statistics
- [ ] Diagram widgets, built as their generators require them: `BarChart`, `RectangleArea`, `CoordinatePlane` (Q1 + Q4), `Angle`, `IntersectingLines`, `Spinner`, `Dice`, `Polygon`, `Shape`, `TapeDiagram`, `DoubleNumberLine`, `Circle`, `Protractor`, `Ruler`, `Money`, `BoxPlot`, `ScatterPlot`, `TwoWayTable`, `TreeDiagram`, `BaseTenBlocks`, `Box3D`, `Histogram`, `DotPlot`, `LinePlot`. Defer: `Net3D`, `ColumnArithmetic` (text-only explanations OK in v1)

*Dataset ingestion sub-track (in progress; landed `tools/question_generation/` + first DeepMind submodule in Chunk 80)*
- [x] Dataset ingestion pipeline scaffolding (build-time only) under [tools/question_generation/](tools/question_generation/) — per-item JSON schema, per-sub-concept output files under `assets/data/dataset_questions/`, distractor generation mirroring Dart's `integerDistractorsWith`, deterministic per-seed. See [tools/question_generation/README.md](tools/question_generation/README.md).
- [x] Create [LICENSES_THIRD_PARTY.md](LICENSES_THIRD_PARTY.md): attribution to every ingested dataset, plus the (eventual) art/audio assets.
- [x] Per-dataset audit framework — every priority dataset gets a sampled-and-classified audit before broad ingestion, recorded under [tools/question_generation/audits/](tools/question_generation/audits/) and linked from [curriculum.md §7.7](curriculum.md). DeepMind audited in Chunk 81; findings reshape what's worth ingesting (most of DeepMind is variety, not coverage).
- [ ] DeepMind `mathematics_dataset` — per-submodule ingestion (audit verdicts in [audits/deepmind.md](tools/question_generation/audits/deepmind.md)):
  - [x] `arithmetic.add_or_sub` → 12 add/sub sub-concepts (Chunk 80; variety)
  - [ ] Highest-ROI variety candidates: `numbers.place_value`, `measurement.time`, `arithmetic.mul` (whole-number subset), `numbers.round_number`. Worth ingesting if/when we want more phrasing variety in these concepts.
  - [ ] Medium-ROI variety: `arithmetic.div`, `numbers.gcd` / `lcm` / `is_factor` / `is_prime` / `list_prime_factors`, `numbers.div_remainder`, `comparison.pair`, `arithmetic.add_sub_multiple` / `mul_div_multiple` — all need substantial range filtering.
  - [ ] Gap-fill candidates (require runtime support for new answer-format shapes): `comparison.{closest, kth_biggest, sort}`, `polynomials.evaluate`. Letter-MC / comma-list / function-evaluation formats.
  - [ ] Skip per audit: `arithmetic.{add_or_sub_in_base, nearest_integer_root, simplify_surd, mixed}`, `algebra.{polynomial_roots, sequence_*}`, `calculus.differentiate`, `polynomials.{add, coefficient_named, collect, compose, expand, simplify_power}`, `numbers.base_conversion`, `measurement.conversion`, `probability.swr_p_*` — out of K-8 scope or too noisy.
- [x] GSM8K audit (Chunk 85) — gr-3–6 multi-step word problems; ingested in Chunk 86 (4 buckets, 1056 items). See [audits/gsm8k.md](tools/question_generation/audits/gsm8k.md).
- [x] MathDataset-ElementarySchool audit (Chunk 82) — verdict **skip dataset** (redundant re-bundling + license-blocked unique slices). See [audits/md_es.md](tools/question_generation/audits/md_es.md).
- [x] MathQA audit (Chunk 87) — verdict **skip broad ingestion** (poor text quality, unreliable formula tagger, malformed options). Narrow geometry slice (~500 items after cleanup) deferred. See [audits/mathqa.md](tools/question_generation/audits/mathqa.md).
- [x] SVAMP audit (Chunk 83) — verdict **dropped on licence grounds** (paper-confirmed derivation from CC-BY-NC ASDiv + unclear-licence MAWPS). See [audits/svamp.md](tools/question_generation/audits/svamp.md).
- [x] **Runtime wiring** (Chunk 84): Drift v5 + `dataset_questions` table lazy-seeded from `assets/data/dataset_questions/*.json` on first read; `QuestionSource` at the Domain layer mixes generator + dataset items per sub-concept using a **weighted-by-pool-size** policy (`pDataset = 0.5 * min(1, poolSize / 50)`, pool = union across all ingested datasets per concept) so thin-pool concepts aren't dominated by dataset repetition and new datasets can land without re-tuning; the wheel + result-screen flow consumes the new source unchanged. Dataset items carry a baked-in `explanation` per item (Python ingest extended), so the wrong-answer screen reads consistently regardless of source.

*Wrap-up*
- [ ] Adaptive system tuning: refine band thresholds per-grade-band, refine `α` learning rate based on playtesting, add asymmetric reward/penalty if data supports it
- [ ] Validate the full catalog with kids in grades K, 2, 4, 6, 8 — at least one per band — and tune
- [ ] **Exit criteria:** ~85% K–8 CCSS coverage live in the app; a kid in any grade K–8 can play continuously and see appropriate-difficulty content; no "no eligible concepts" dead ends; every wrong-answer screen shows a kid-readable step-by-step explanation.

*Punted out of v1:* Hand-curated ~1500 gap-fill questions for the §7.6 dataset gaps (K–2 word problems, K–5 geometry referencing procedural diagrams, statistical-question recognition, qualitative graph descriptions, grade-7 ratio real-world scenarios, grade-8 function items). Revisit post-launch if the algorithmic + dataset coverage leaves visible gaps in real play.

---

### Phase 7 — City Builder: Simple DAG Proof (target: ~3–4 weeks)

**Goal:** Ship a playable, persistent city with the *mechanics* of the full design — multi-gate DAG unlocks, citizen-bubble UI, growth that responds to building mix — but with a deliberately small content set (~10 buildings, ~5–10 hand-written beats). The point is to validate the system end-to-end before scaling content in Phase 8/9.

**Out of scope for this phase:** the full hundreds-of-buildings DAG (Phase 8), themed maps and events (Phase 9), final building art (Phase 9). Use placeholder or temporary CC0 art that's good enough to play.

**Resolve before starting:**
- [ ] **Decide the currency model** — single "bricks" rename of `stars`, or multi-resource (bricks / paint / gears / …) where different concept families yield different materials. Lock the decision and update [prd.md](prd.md) + the Data Model section here. Affects all later phases.
- [ ] **Decide the initial ~10 building catalog** — must cover all 4 categories (civic-core/housing, services, commercial, entertainment) so the variety-multiplier mechanic has something to chew on. Sketch:
  - Civic-core / housing: mayor's office, single home, apartment, school
  - Services: clinic, power plant, waste management
  - Commercial: grocery, coffee shop
  - Entertainment: park

**Build:**
- [ ] Drift schema (v6): `City`, `CityMap`, `BuildingType`, `BuildingPlacement`, `StoryBeat`, `StoryBeatState` tables (the last two new vs. earlier sketches — see Data Model section)
- [ ] One beginner `CityMap` definition: ~12×12 tile grid, fixed terrain
- [ ] Initial `BuildingType` catalog (the ~10 from the catalog decision above), each with `category`, currency cost, `populationContribution`, `serviceProvision`, and unlock rule
- [ ] **DAG unlock engine** (pure-Dart, well unit-tested) — a building's `unlockRule` is a typed value combining any of `{minLifetimeCurrency, requiredBuildingsPlaced, minPopulation, requiredBeatsFired}` with AND semantics. Engine evaluates the rule against current city + player state and returns the unlocked set; emits "newly unlocked" events on transitions
- [ ] **Story-beat engine** (pure-Dart, well unit-tested) — each beat has trigger conditions (`buildingsPresent` / `buildingsAbsent` / `minPopulation` / `minBuildingAgeForX` / `requiredBeatsFired` / `minCurrencyEarnedSinceLastBeat`), emoji + sticker payload, and short + long text. Engine maintains a `(beatId → state)` map across sessions; "rotates" unack'd bubbles by hiding them after N rounds and re-firing later
- [ ] ~5–10 hand-written beats in code (`lib/domain/city/beats/`) covering: pre-unlock demand for each Service-category building, recurring "we want more parks" praise/demand, "trash is everywhere" anti-prereq beat for waste mgmt, post-placement praise for at least one commercial
- [ ] Isometric tile renderer (Flame component) — render terrain + placed buildings, support pinch-zoom and pan; render emoji-bubble overlays at building positions, tap-to-expand for full sentence
- [ ] Build-mode UI: building catalog at the bottom, **discovery-based — locked buildings are not visible at all**; tap building → tap free tile → placed; insufficient currency greys out the option
- [ ] Move-mode UI: pick up an existing building, tap a new free tile to drop it (no currency cost)
- [ ] Auto-road generation: roads automatically connect every placed building (recompute on placement / move). Render under buildings on the road tiles
- [ ] Population counter visible on the city screen
- [ ] **Population growth model v1** (pure-Dart, well unit-tested): grows toward `sum(populationContribution)` modulated by:
  - service ratios (e.g. 1 clinic per 50 residents, 1 power plant per 200)
  - category-variety multiplier (a small bonus per distinct commercial / entertainment building type placed; a small penalty for category lopsidedness like "all entertainment, no housing")
- [ ] "My City" screen accessible from the home screen
- [ ] **Exit criteria:** Player starts empty, places the mayor's office as their first build, sees a citizen bubble demand a service that isn't unlocked yet, hits the unlock conditions (currency + prereqs + pop) for that service, places it, sees a praise bubble appear, hits a growth-stalling service-ratio cap on a different service, sees the corresponding demand bubble, builds the missing service, watches population resume growing — all surviving an app restart.

---

### Phase 8 — City Builder: Research & Rich Design (target: ~2–3 weeks)

**Goal:** Design the full DAG (target: hundreds of buildings across the 4 categories) and the rich beat catalog (target: hundreds of beats) that Phase 9 will implement. This is a content-authoring phase with **no code changes** — its primary deliverable is a new `city_builder.md` that plays the same role for the city builder that `curriculum.md` plays for the math curriculum.

**Why this is a phase, not a chunk:** the design needs to *feel infinite* without becoming a junk drawer. That requires studying what existing city-builders do well, then producing a coherent design — not improvising hundreds of buildings ad hoc.

- [ ] **Research phase** — study existing city-builders for what makes their progression feel rewarding vs. grindy. SimCity (original through *SimCity 4*) is the obvious primary reference; secondary candidates: Cities: Skylines (unlock pacing), Township / Stardew Valley (cozy progression), CivCity, Anno series. Capture findings in `city_builder.md` §1 "References & Lessons Learned"
- [ ] Author **`city_builder.md`** at the repo root, structured to mirror `curriculum.md`:
  - **Status block** — current state of the design (which sections are stable, last edited, etc.)
  - **§1 References & Lessons Learned** — what other games did, what we'll borrow / reject
  - **§2 Categories** — civic-core/housing, services, commercial, entertainment — with role definitions and growth contribution
  - **§3 Building catalog** — the full DAG. Each entry: id, name, category, currency cost (per the v1 currency decision), unlock rule (the multi-gate DAG), population contribution, service-provision profile, expected unlock arc (early / mid / late game). Group by category. Aim for a coherent progression within each category (e.g. housing arc: single home → duplex → apartment → high rise → luxury condo); avoid "random" multi-parent prereqs
  - **§4 Story beat catalog** — every beat: id, trigger conditions (buildingsPresent / buildingsAbsent / minPop / minBuildingAge / requiredBeatsFired / spacing), emoji + sticker, short text, expanded text, tone (silly / civic / praise / demand). Cross-reference back to §3 building IDs
  - **§5 Asset checklist** — for each §3 building, what art / sound assets are needed; sourcing strategy (Kenney / OpenGameArt / commission / generate). Must hit the licensing rules: CC0, CC-BY, or equivalent only; CC-BY-NC and CC-BY-NC-SA excluded (matches curriculum.md / `LICENSES_THIRD_PARTY.md`)
  - **§6 Implementation status** — ✅ markers for each §3 building & §4 beat indicating whether it's wired up in code yet. Initially all blank; Phase 9 ticks them. Auto-managed by a `tools/city_builder/sync_implementation_status.py` script (deferred until §6 has rows worth syncing)
  - **§7 Open Questions** — items that need playtesting or further research before they can be locked
- [ ] Sanity-check the DAG: no cycles, every multi-parent node makes narrative sense, every building has at least one trigger beat in §4
- [ ] Lock the design enough that Phase 9 can implement without designing as it goes — but expect to iterate during Phase 9 as content meets reality
- [ ] **Exit criteria:** `city_builder.md` exists with §1–§7 populated; the DAG is reviewed for narrative coherence; Phase 9 has a clear queue of buildings + beats to implement.

---

### Phase 9 — City Builder: Rich Implementation & Graphics (target: ~6–10 weeks)

**Goal:** Implement the full `city_builder.md` design — every building in §3 is placeable, every beat in §4 fires, every art asset in §5 is in the app. Significantly larger phase than the others.

- [ ] Stand up `tools/city_builder/sync_implementation_status.py` (mirroring `tools/curriculum/sync_implementation_status.py`) — syncs ✅ markers in `city_builder.md` §3 / §4 / §6 against `building_registry.dart` / `beat_registry.dart` / `assets/data/city/`
- [ ] **Authoring loop** — iterate building-by-building (or in small clusters):
  - Add to `building_registry.dart` with category, costs, unlock rule, population/service data
  - Add the building's triggering beats to `beat_registry.dart`
  - Source / generate the building art per §5
  - Run the sync script; tick the ✅
- [ ] **Building art pipeline** — this is the big unknown. Options to evaluate early:
  - **(a) CC0 isometric kits** — Kenney City Kit packs + supplementary OpenGameArt; sufficient for ~30–50 buildings but unlikely to scale to hundreds
  - **(b) Procedural building widgets** — analogous to curriculum.md's procedural diagram strategy: parameterized Flutter `CustomPainter` widgets driven by `BuildingType` params. Scales infinitely but takes art-direction work to make hundreds of buildings feel distinct
  - **(c) Hybrid** — kits for the "anchor" buildings, procedural for the long tail of variants. Likely choice; lock in the first 2 weeks of this phase
- [ ] Themed maps (countryside, big-city, futuristic) — each with its own `starCostToUnlock` (or equivalent in the chosen currency model) and independent placement state per player
- [ ] Map switcher UI on the city screen
- [ ] Land expansion — spend currency to grow the grid symmetrically outward by 2 tiles per side. Cap at 24×24 for v1
- [ ] Building upgrade tiers — up to 3 visual tiers per building; upgrading costs currency; footprint stays the same
- [ ] Currency-funded events: 3–5 event types (festival, marketing campaign, etc.) — temporary growth boost in exchange for spend
- [ ] **Exit criteria:** Every row in `city_builder.md` §3 and §4 is ticked. A returning player can place at least 30 distinct building types, see varied citizen reactions across both demand and praise bubbles, unlock and switch between map themes, run an event, and expand their land at least twice — all surviving an app restart.

---

### Phase 10 — Player Progress Screen (target: ~1 week)
- [ ] Concept proficiency visualization (radar chart or color grid) — rolled up to category
- [ ] Strengths and growing edges sections with positive framing
- [ ] Lifetime stats: currency earned, sessions, questions answered
- [ ] **Exit criteria:** Player can see and feel proud of their own progress

---

### Phase 11 — Sound, Polish, Engagement (target: ~2–3 weeks)
- [ ] Final SFX library (CC0/royalty-free); per-event audio (spin, correct, wrong, building-placed, level-up, bubble-pop)
- [ ] Background music (looping, with mute toggle)
- [ ] Animation polish (character reactions on correct/wrong; screen transitions; bubble float/pop)
- [ ] Daily streak tracking + bonus currency
- [ ] Daily challenge mechanic
- [ ] First-launch tutorial (skippable)
- [ ] Settings screen (audio mute, reset profile, change grade level, dyslexia-friendly font toggle if time)
- [ ] **Extra credit — animated city** (drop if time runs short, defer to post-launch):
  - [ ] Cars driving along the auto-roads
  - [ ] Pedestrians on sidewalks
  - [ ] Building lights turning on/off
  - [ ] Day/night cycle on the city screen
- [ ] **Exit criteria:** It feels like a real game, not a prototype

---

### Phase 12 — Cloud Save (target: ~1–2 weeks)
- [ ] **Prerequisite:** Replace the wipe-and-recreate Drift migration pattern (used through v3 / v4 / v6) with proper additive migrations. Once player data lives off-device, schema wipes destroy real data — this must land *before* the cloud-save round-trip is enabled
- [ ] Integrate `games_services` save game API
- [ ] Sign-in flow (Game Center / Play Games) — graceful skip if signed out
- [ ] Save-on-meaningful-event (round end, avatar edit, building placed, map unlocked, beat acked)
- [ ] Load on app start; conflict resolution (prefer most recent)
- [ ] iOS verification (deferred from Phase 0 — `flutter run` on iOS simulator must succeed before this phase ships)
- [ ] **Exit criteria:** Install on a second device, sign in, see same player data including avatar, currency balance, city state, and citizen-bubble history

---

### Phase 13 — Beta + Store Submission (ongoing)
- [ ] **Apple Developer Program** enrollment ($99/yr) — only when ready to submit; not blocking earlier work
- [ ] **Google Play Console** enrollment ($25 one-time)
- [ ] App Store Connect: register bundle ID, fill listing metadata, age rating questionnaire, kids-category settings ("Made for Kids")
- [ ] Play Console: register the app, fill listing metadata, "Designed for Families" enrollment, target-audience declaration
- [ ] Build artifacts: signed Android AAB; signed iOS archive (requires macOS + Xcode)
- [ ] App icon, screenshots (Android + iOS at multiple sizes), feature graphic, store description copy
- [ ] Privacy policy (minimal — we collect ~nothing — but COPPA-aware language; either template-based or briefly legal-reviewed)
- [ ] TestFlight (iOS) internal testing
- [ ] Play Console internal-testing channel
- [ ] Iterate on real beta feedback (1–2 cycles)
- [ ] Submit to stores; respond to reviewer feedback
- [ ] **Exit criteria:** App is live on both stores

---

## Open Questions / Decisions Deferred

These are not blockers for Phase 0 or 1 but need to be resolved by the phase noted:

- **By Phase 2 (resolved):** Proficiency update formula — using simple exponential moving average; see *Domain Specs*.
- **By Phase 4 (resolved):** Avatar library pick — DiceBear Adventurer chosen; avatar accessory shop dropped. See *Locked Decisions*.
- **By Phase 5 (resolved):** K–8 curriculum scope, taxonomy, and source strategy — see [curriculum.md](curriculum.md). 12 categories, ~361 sub-concepts; ~85% reachable algorithmically, ~10% via bundled GREEN-licensed datasets, ~5% deferred. No runtime LLM; no offline LLM batch in v1.
- **By Phase 5 (resolved):** Question dataset sourcing strategy — curate from GREEN-licensed datasets only (DeepMind `mathematics_dataset`, GSM8K, MathDataset-ElementarySchool, MathQA, SVAMP). CC-BY-NC content excluded. See [curriculum.md §7](curriculum.md).
- **By Phase 5:** Open taxonomy questions — see [curriculum.md §9](curriculum.md) (12 items needing human review during implementation: counting/place-value boundary, fluency tier modeling, geometry hierarchy duplication, word-problem axis, etc.).
- **By Phase 6 (resolved):** Hand-curation budget for the ~1500 gap-fill items — **punted out of v1**. Rely on algorithmic + GREEN datasets for coverage; revisit post-launch if real play exposes the §7.6 gaps. See Phase 6 task list for the punted scope.
- **By Phase 7 start:** **Currency model** — rename "stars" to a city-themed single currency (likely "bricks"), or move to a multi-resource scheme where different concept families yield different building materials (e.g. bricks from arithmetic, paint from geometry, gears from algebra) and each building requires a recipe. Multi-resource adds narrative depth and a natural reason to spread practice across the curriculum; single rename is simpler. Lock this before Phase 7 mechanics ship so the Drift schema + UI don't churn.
- **By Phase 7:** **Initial ~10-building catalog** for the simple DAG proof — must cover all 4 categories (civic-core/housing, services, commercial, entertainment) so the variety-multiplier mechanic has something to chew on.
- **By Phase 7:** **Placeholder art for ~10 buildings** — Kenney's [City Kit Industrial](https://kenney.nl/assets/city-kit-industrial) covers some of these but not all. Settle on "good-enough" temporary art for Phase 7; the full art pipeline decision moves to Phase 9.
- **By Phase 8:** **References research** — which existing city-builders to study (SimCity series, Cities: Skylines, Township, etc.) and what to capture from each. Lives in `city_builder.md §1`.
- **By Phase 8:** **Full DAG design** — hundreds of buildings across 4 categories, with coherent within-category progressions and narratively-sensible multi-parent prereqs. Lives in `city_builder.md §3`.
- **By Phase 8:** **Beat catalog & tone calibration** — hundreds of citizen requests / praise items, mixing kid-friendly silly with civic. Lives in `city_builder.md §4`.
- **By Phase 9:** **Building art pipeline** — pure CC0 isometric kits (won't scale to hundreds of buildings), procedural Flutter `CustomPainter` widgets analogous to the diagram-widget strategy in curriculum.md, or a hybrid (kits for anchors, procedural for the long tail). Lock in the first 2 weeks of Phase 9.
- **By Phase 9:** **Building service-ratio numbers** (residents per clinic, per power plant, etc.) and **variety-multiplier curves** — can only be tuned by play-testing.
- **By Phase 11:** Music + SFX sourcing (CC0 from Freesound.org and OpenGameArt.org).
- **By Phase 12:** Are we OK requiring the user to sign in to Game Center / Play Games for cloud save? Otherwise local-only is the only option.
- **By Phase 13:** Privacy policy text — minimal since we collect ~nothing, but COPPA considerations for under-13 audience need legal review or a template.

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Core loop isn't fun for kids | Medium | Critical | Phase 1 explicitly tested this with a real kid before any further investment — passed |
| Question dataset gap | Medium | High | Algorithmic generation handles arithmetic; for everything else, multiple datasets identified (GSM8K, MathDataset-ElementarySchool, Illustrative Mathematics) |
| ~~Avatar library doesn't cover all 8 slots~~ | — | — | Resolved: avatar accessories dropped from scope after Phase 4 spike — single star sink is the city builder |
| City UX on small screens (placement, panning, zoom, bubble tap targets on a phone) | Medium | High | Auto-roads (no precision needed); tile-snap with generous tap targets; pinch-zoom + pan; cap on-screen citizen bubbles at ~5 to keep tap targets large; play-test on smallest target device early in Phase 7 |
| Building art coverage at "hundreds of buildings" scale | High | High | Phase 9 evaluates the hybrid art pipeline (CC0 isometric kits for anchors + procedural `CustomPainter` widgets for the long tail) in its first 2 weeks. If procedural can't carry the long tail, narrow the v1 building catalog to what kits + a small art-direction effort can actually cover. Phase 7's placeholder art is explicit so the kit gap doesn't block mechanics work |
| DAG design becomes a junk drawer (hundreds of buildings without coherent progression) | Medium | High | Phase 8 is a dedicated research-and-design phase whose deliverable is `city_builder.md` with within-category arcs and narratively-sensible multi-parent prereqs. Phase 9 implements against that doc, not ad hoc. Sanity-check before Phase 9: no cycles, every multi-parent prereq makes sense, every building has at least one triggering beat |
| Citizen-bubble system becomes annoying / nags the player | Medium | Medium | Cap at ~5 bubbles on-screen; unack'd bubbles auto-rotate; mix demand bubbles with praise bubbles (positive feedback) so the channel isn't pure pressure; per-beat spacing rules pace requests by currency-earned-since-last-beat. Validate in Phase 7 playtest before scaling content in Phase 9 |
| Population growth model feels arbitrary or unmotivating | Medium | Medium | Keep model simple (aggregate service ratios + variety-multiplier, not per-building dependency graphs); tune via play-testing. Vague-but-themed bubble feedback keeps the player oriented even if numbers shift |
| City save state migration as schema evolves across phases | Medium | Medium | Drift migrations are version-checked; player's city is purely cosmetic so a wipe is a survivable last resort. Bias toward additive schema changes. Phase 7 ships schema v6 including the new `StoryBeat` / `StoryBeatState` tables — additive on v5 |
| Cloud save platform divergence | Low (single package) | Medium | `games_services` abstracts both — but test on both platforms early in Phase 12 |
| `games_services` package abandonment | Low | Medium | If it goes stale, fall back to platform-specific packages (`cloud_kit` for iOS, `googleapis` Drive for Android) |
| Hive/Isar abandonment pattern repeats with Drift | Low | Low | Drift is built on SQLite; worst-case migration to raw `sqflite` is straightforward |
| COPPA / children's-app compliance | Medium | High (could block store submission) | No data collection; address this explicitly in Phase 12 with a minimal privacy policy and store-listing kids-category settings |
| Apple Developer Program ($99/yr) and Play Console ($25 one-time) fees | Certain | Low–Medium | Real ongoing cost for a "free hobby project." If the Apple membership lapses, the iOS build is delisted from the App Store. Budget accordingly; consider whether one platform-only launch buys more time |
| Sub-concept catalog explosion | Medium | Low (mitigated) | Mitigated as of Phase 5: the full ~361-sub-concept K–8 catalog is now defined in [curriculum.md](curriculum.md) with prereq DAG. The progressive rollout is: Phase 1: 2 concepts; Phase 2: 6 concepts; Phase 5: ~20 concepts (K–3 broad — 12 from Phase 1–2 decomposition + ~8 new across multi-digit ±, fractions, time); Phase 6: full K–8 catalog (~85% coverage live). Schema seeds the full catalog from Phase 5 onward — no further schema migrations needed for catalog growth |

---

## How We Work (AI-Assisted Conventions)

Since this is a two-person project (you + Claude), some norms to keep us efficient:

- **PRD is product scope, plan.md is execution.** Don't conflate. If product scope changes, update [prd.md](prd.md). If execution approach changes, update this file.
- **Update `Status` section** at the top of this file at the end of each work session — current phase, last action, next action. Keeps the next session cold-startable.
- **Check off phase task boxes as we go** so we always know where we are.
- **Open questions go in the "Open Questions" section above** — don't let them get buried in chat. When answered, move the answer into the relevant phase or "Locked Decisions."
- **Bugs and concrete enhancements go to [GitHub Issues](https://github.com/quarup/math_city/issues)**, not plan.md. plan.md is for strategy + phase scope; Issues are for tactical backlog. Label set: type (`bug`, `enhancement`, `content`, `polish`), area (`wheel`, `question-screen`, `result-screen`, `generator`, `diagram`, `debug-tools`, `accessibility`, `city-builder`), priority (`p1`/`p2`/`p3`). When starting a sub-slice, pull relevant issues by label.
- **After landing a generator, widget, or dataset, run `python3 tools/curriculum/sync_implementation_status.py`** to refresh the ✅ markers and rollup counts in [curriculum.md](curriculum.md). Commit the curriculum.md change alongside the code change. See [CLAUDE.md](CLAUDE.md) "Keeping curriculum.md status in sync" for details.
- **Risks: revisit at start of each phase** — drop ones that no longer apply, add new ones surfaced by the work.
- **Code style:** see [CLAUDE.md](CLAUDE.md) for conventions, build/test commands, and architecture notes the AI should follow.

---

## References

**Engine / framework**
- [Flame Engine docs](https://docs.flame-engine.org/)
- [Flutter Casual Games Toolkit](https://docs.flutter.dev/resources/games-toolkit)
- [Riverpod docs](https://riverpod.dev/)
- [Drift docs](https://drift.simonbinder.eu/)
- [games_services package](https://pub.dev/packages/games_services)
- [flame_audio package](https://pub.dev/packages/flame_audio)

**Avatar library (chosen)**
- [DiceBear Adventurer style](https://www.dicebear.com/styles/adventurer/) — CC0 designs, MIT code
- [`dice_bear` Flutter package](https://pub.dev/packages/dice_bear) — Dart wrapper for the DiceBear API; renders SVG locally or via URL
- [`flutter_svg` package](https://pub.dev/packages/flutter_svg) — required to render the SVG output

**City builder asset candidates (Phase 7 placeholder + Phase 9 anchor kits)**
- [Kenney City Kit Industrial](https://kenney.nl/assets/city-kit-industrial) — CC0 isometric
- [Kenney all assets](https://kenney.nl/assets) — search "city" / "isometric"
- [OpenGameArt isometric tag](https://opengameart.org/art-search-advanced?keys=isometric) — CC0 / CC-BY mix

**City-builder reference games (Phase 8 research targets)**
- SimCity series (the original through *SimCity 4*) — for the unlock-by-population / unlock-by-need pattern
- Cities: Skylines — for milestone unlock pacing
- Township / Stardew Valley — for cozy progression and citizen-request tone
- Anno series / CivCity — for category-balance ("need housing + food + entertainment") feedback loops

**Curriculum & math content** (full inventory + licensing in [curriculum.md](curriculum.md) §7)
- [curriculum.md](curriculum.md) — canonical K–8 taxonomy, generator priority, diagram widget catalog, dataset inventory
- [Common Core State Standards — Mathematics](https://www.thecorestandards.org/Math/) — primary curriculum source
- [DeepMind `mathematics_dataset`](https://github.com/google-deepmind/mathematics_dataset) — Apache 2.0; procedurally generated arithmetic/algebra
- [GSM8K](https://github.com/openai/grade-school-math) — MIT; grade-school word problems with rationales
- [MathDataset-ElementarySchool](https://github.com/RamonKaspar/MathDataset-ElementarySchool) — MIT; pre-aggregated K–5 catalog
- [MathQA](https://math-qa.github.io/) — Apache 2.0; cleaned algebra MC for grades 6–8
- [SVAMP](https://github.com/arkilpatel/SVAMP) — MIT; curated grades 2–4 word problems
- [Open Up Resources 6–8 Math (1st/2nd ed)](https://openupresources.org/) — CC-BY 4.0; the only OER curriculum that's app-store-distribution-safe (the newer California editions are CC-BY-NC = excluded)

**Audio / general assets**
- [OpenGameArt.org](https://opengameart.org/) — CC0/CC-BY art assets
- [Freesound.org](https://freesound.org/) — CC-licensed audio
