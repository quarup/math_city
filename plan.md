# Math City — Implementation Plan

> Living document. Update as decisions are made and phases progress.
> Source of truth for product scope: [prd.md](prd.md).

---

## Status

- **Phase:** Phase 6 — Full Question Bank. **90 generators implemented**; three K–8 categories with broad coverage (`fractions` 26, `decimals_percent` 24, `ratios` 10 of 16). Word problems + rationals also covered. Geometry, prealgebra, and statistics still untouched.
- **Last updated:** 2026-05-17
- **Last action:** **#8 Ratios (chunk 7) — cleanup** — 5 generators appended to `ratio_generators.dart`: `unit_pricing` (G6, "3 apples cost $6. unit price?"; algorithmic despite curriculum.md tagging dataset), `convert_units_using_ratio` (G6, curated whole-factor conversions: ft→in, yd→ft, m→cm, hr→min, etc.; auto-caps quantity when factor ≥ 100 to keep answers tractable), `proportional_relationship` (G7, verbal mini-table "x: 1,2,3; y: 4,8,12. Is y proportional?"; Yes/No MC — implemented without the curriculum.md-suggested coordinate_plane diagram), `constant_of_proportionality` (G7, "y = kx, y=12 when x=3. k?" → 4), `proportional_equation` (G7, MC pick from {y=kx, y=x+k, y=k/x, y=kx+1}). Tests: +5 groups @ 300; **269 total pass**, `flutter analyze` clean.
- **Last action (prior):** **#8 Ratios (chunk 6) — entry** — 5 generators `ratio_intro`, `ratio_language`, `equivalent_ratios`, `unit_rate`, `constant_speed`. Commit `99377b7`.
- **Last action (prior):** **#7 Decimals sub-slice (chunk 3) — percent intro** — 3 new generators in a new file `percent_generators.dart` plus a new diagram widget:
  - **`PercentGridSpec` + `PercentGrid` widget** ([lib/presentation/diagrams/percent_grid.dart](lib/presentation/diagrams/percent_grid.dart)) — 10×10 grid with N cells shaded row-major. Distinct from `AreaGrid` (which is shaped as a row × col overlap rectangle for fraction × fraction). Wired into `DiagramRenderer`.
  - **`percent_intro` (G6)** — "What percent is shaded?" + grid diagram. Excludes 0/50/100 so the kid actually has to count. Misconception distractors: 100−n (swapped shaded/unshaded), n÷10 (read as out-of-10).
  - **`percent_of_quantity` (G6)** — "What is 25% of 80?" Parameters are drawn from two templates that both guarantee integer results: friendly percents {10,20,25,30,40,50,60,70,75,80,90} with quantity divisible by 100/gcd(p,100), OR any percent with quantity a multiple of 100. Misconception distractors: forgot the ÷100, swapped percent and quantity, "the rest" (quantity − answer).
  - **`find_whole_from_part_percent` (G6)** — natural inverse: "$part is $percent% of what number?" Same parameter discipline as `percent_of_quantity`.
  - **Prereq override:** `percent_intro: []` drops the unimplemented `fraction_denom_10_100` prereq — the grid widget itself visualises "N out of 100" directly, so the kid doesn't need the tenths/hundredths fraction-bar background.
  - **No keypad changes:** answers are bare integers (no `%` symbol), so the existing digit-only keypad just works.
  - **Tests:** +3 (one group per generator @ 300 iterations; 252 total). `flutter analyze` clean.
- **Last action (prior):** **#7 Decimals sub-slice (chunk 2)** — 7 new generators in `decimal_generators.dart`: `decimal_to_thousandths_read` (G5), `compare_decimals_thousandths` (G5), `round_decimals` (G5, half-away-from-zero to whole/tenth/hundredth), `div_decimal_by_whole` (G5, generated as quotient × divisor for exact results), `div_by_decimal` (G6, quotient always a whole int 2..20), `decimal_to_fraction` (G5, AnswerFormat.fraction + exactString since lesson is "in lowest terms"; re-rolls to require non-trivial reduction), `fraction_to_decimal` (G6, AnswerFormat.decimal; denominators restricted to the terminating set {2, 4, 5, 8, 10, 20, 25, 50}). New helper `_wholeDistractors` for integer-answer distractor sets that need dedup-and-fallback. Commit `d8b7b20`.
- **Last action (prior x2):** **#7 Decimals sub-slice (chunk 1)** — 7 new generators in a new file `lib/domain/questions/generators/decimal_generators.dart`:
  - **Notation (G4):** `decimal_notation_tenths`, `decimal_notation_hundredths` — "Write N tenths/hundredths as a decimal." Misconception distractors include the classic "0.7 vs 0.07" shift error.
  - **Compare (G4):** `compare_decimals_hundredths` — "Which is bigger: 0.45 or 0.5?" Matches the `compare_fractions_*` shape rather than `<`/`=`/`>` (sidesteps keypad-with-comparison-symbols UX). 40% of pairs are tenths-vs-hundredths to bait the "longer = bigger" misconception.
  - **Arithmetic (G5):** `add_decimals`, `sub_decimals`, `mult_decimal_by_whole`, `mult_decimals`. Subtraction generated as `(a+b) − b` to keep results ≥ 0. Multiplication generators re-roll if a picked operand canonicalises to a whole number, so the lesson is always genuinely decimal × {whole|decimal}.
  - **New value type:** `lib/domain/questions/decimal.dart` — scaled-integer internal representation (no `double`, so `0.1 + 0.2` is exactly `0.3`). Canonical form strips trailing zeros (`0.5`, not `0.50`). Mirrors the `Fraction` pattern — `equalsByValue` instead of overriding `==`, no `meta` dep needed.
  - **AnswerFormat.decimal** added; answer-checker accepts equivalent forms via `Decimal.equalsByValue` (so a player typing `1.50` matches canonical `1.5`).
  - **Keypad:** no changes needed — the existing `_extraCharsFor(answer)` derives the `.` button automatically from the canonical answer string.
  - **DAG cleanup:** removed the `rationals_add_sub` / `rationals_multiply_divide` prereq overrides — `add_decimals` / `mult_decimals` now exist, so the rationals prereqs match curriculum.md again. Added a `decimal_notation_tenths` override that drops the unimplemented `fraction_denom_10_100` prereq (so this slice's entry point into the decimals branch reaches kids).
  - **Tests:** +20 (Decimal value-type 14 + decimal generators 6 groups @ 300 iterations each). All 259 pass; `flutter analyze` clean.
- **Next action:** Pick the next sub-slice. Easy options remaining ([curriculum.md §5.1](curriculum.md)):
  - **#12 One-/two-step equations + order of ops** — `solve_one_step_eq_addition`, `solve_one_step_eq_mult`, `solve_two_step_eq`, `evaluate_expression`, `order_of_operations_no_exp`. Pure algorithmic, no diagrams.
  - **Remaining ratio rows** (need new widgets or are tricky): `ratio_table` (tape_diagram), `double_number_line`, `ratio_to_coordinate_pairs` (coordinate plane), `multistep_ratio_word` (dataset), `scale_drawing`, `unit_rate_with_fractions` (clean integer answer setup is fiddly).
  - **#9–#11 Geometry / area / perimeter** — needs `RectangleArea`, `Polygon`, `Angle` widgets first.
  - **#12–#14 Pre-algebra / equations** — `solve_one_step_eq_addition`, `solve_one_step_eq_mult`, `solve_two_step_eq`, etc.
  - **#16 Statistics** — `mean_median_mode_range`, basic data-display reading.
- **Deferred:** Audio SFX + background music (CC0 assets not sourced yet — stub in place). iOS verification. Both revisit before Phase 11 at latest.

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
  currentStars          // spendable balance
  lifetimeStarsEarned   // never decreases — drives progressive unlocks
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

// --- City builder (Phase 7+) ---

City (per player, per map)
  id, playerId, mapId,
  gridWidth, gridHeight,         // grows on land expansion (Phase 8)
  population

CityMap (static catalog)
  id, name, theme (countryside | city | futuristic | …),
  baseGridWidth, baseGridHeight,
  starCostToUnlock (0 for the beginner map),
  terrainSeed                    // deterministic terrain layout

BuildingType (static catalog)
  id, name, category (residential | services | utilities | commercial),
  starCost,
  unlockedAtLifetimeStars,
  populationContribution,         // residents this building can house, if any
  serviceProvision,               // map of {school: N, hospital: N, power: N, …}
  maxTier, assetRefByTier

BuildingPlacement
  id, cityId, buildingTypeId, currentTier, gridX, gridY, placedAt

GameSession (in-memory only)
  startedAt, players (list), roundsPlayed
  // Streak lives on Player, not here
```

**Notes:**
- `Item`, `Milestone`, and `AvatarAccessory` from earlier sketches are removed. The only star sink is the city builder; the avatar is free to customize.
- `currentStars` vs. `lifetimeStarsEarned`: spending stars decreases `currentStars`; both correct *and* spent stars count toward `lifetimeStarsEarned` for unlock gating (so spending doesn't lock players out of progression).
- `serviceProvision` lets the city growth model use simple aggregate ratios (e.g. "1 school per 50 residents") rather than per-building dependency graphs.

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
│   │   ├── city/          # city-builder screen (Phase 7+)
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
│   │   └── city/          # buildings, growth model, population math (Phase 7+)
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

*Dataset ingestion sub-track (revisit after the generator surface is broad)*
- [ ] Dataset ingestion pipeline (build-time only) in `tools/question_generation/`. For each GREEN dataset: fetch, transform to bundled JSON format, sub-concept-tag, write to `assets/data/`:
  - DeepMind `mathematics_dataset` — generate per-module batches (arithmetic, algebra, comparison, measurement, numbers, polynomials, probability), filter to K–8 difficulty, target ~50K items
  - GSM8K — filter to grades 3–6, sub-concept-tag via operator/keyword analysis
  - MathDataset-ElementarySchool — re-tag and dedupe; preserve `source` provenance
  - MathQA — filter `category` to grade-appropriate; keep `linear_formula` for distractor generation + answer verification
  - SVAMP — provenance-audit (drop ASDiv-derived items per agent-2 license analysis)
- [ ] Create `LICENSES_THIRD_PARTY.md`: attribution to every ingested dataset, plus the (eventual) art/audio assets

*Wrap-up*
- [ ] Adaptive system tuning: refine band thresholds per-grade-band, refine `α` learning rate based on playtesting, add asymmetric reward/penalty if data supports it
- [ ] Validate the full catalog with kids in grades K, 2, 4, 6, 8 — at least one per band — and tune
- [ ] **Exit criteria:** ~85% K–8 CCSS coverage live in the app; a kid in any grade K–8 can play continuously and see appropriate-difficulty content; no "no eligible concepts" dead ends; every wrong-answer screen shows a kid-readable step-by-step explanation.

*Punted out of v1:* Hand-curated ~1500 gap-fill questions for the §7.6 dataset gaps (K–2 word problems, K–5 geometry referencing procedural diagrams, statistical-question recognition, qualitative graph descriptions, grade-7 ratio real-world scenarios, grade-8 function items). Revisit post-launch if the algorithmic + dataset coverage leaves visible gaps in real play.

---

### Phase 7 — City Builder: Foundations (target: ~3–4 weeks)

**Goal:** Each player has their own persistent isometric city. They spend stars to place buildings; population grows when the right mix is built.

- [ ] Source/curate isometric building art (start: Kenney City Kit Industrial; supplement if needed). Confirm CC0 status, log in eventual `LICENSES_THIRD_PARTY.md`
- [ ] Drift schema (v4): `City`, `CityMap`, `BuildingType`, `BuildingPlacement` tables
- [ ] One beginner `CityMap` definition: ~10×10 tile grid, fixed terrain (grass + decorative water/stone)
- [ ] Initial `BuildingType` catalog (5 types): own house, apartment, school, hospital, power plant
- [ ] Isometric tile renderer (Flame component) — render terrain + placed buildings, support pinch-zoom and pan
- [ ] Build-mode UI: building catalog at the bottom, tap building → tap free tile → placed; insufficient stars greys out the option
- [ ] Move-mode UI: pick up an existing building, tap a new free tile to drop it (no star cost)
- [ ] Auto-road generation: roads automatically connect every placed building (recompute on placement / move). Render under buildings on the road tiles
- [ ] Population counter clearly visible on the city screen
- [ ] Population growth model (pure-Dart, well unit-tested): population grows toward `sum(populationContribution)` capped by service ratios (e.g. 1 school per 50 residents, 1 hospital per 100, 1 power plant per 200). Below the lowest-satisfied ratio, growth stalls
- [ ] One feedback message when stalled (cycle through if multiple constraints fail): "Your residents need a school to keep growing"
- [ ] "My City" screen accessible from the home screen
- [ ] **Exit criteria:** Player places 5 buildings, sees population grow, hits a service-ratio cap, reads the feedback message, builds the missing service, sees population resume growth — all surviving an app restart

---

### Phase 8 — City Builder: Depth (target: ~2–3 weeks)

**Goal:** City has long-arc progression — bigger land, more building types, themed maps, events.

- [ ] Land expansion: spend stars to grow the grid symmetrically outward by 2 tiles per side. Cap at, say, 20×20 for v1
- [ ] Progressive `BuildingType` unlocks gated by `lifetimeStarsEarned` (e.g. coffee shop at 200, gas station at 400, hotel at 800)
- [ ] Expand catalog to ~12–15 building types (add: coffee shop, restaurant, gas station, hotel, waste management, office, fire station — final list set during the phase)
- [ ] Building upgrade tiers: each `BuildingType` has up to 3 tiers; upgrading costs stars; **footprint stays the same**, only the texture/style changes
- [ ] Additional `CityMap`s with themes (countryside, big-city, futuristic) — each has its own `starCostToUnlock` and its own independent placement state per player
- [ ] Map switcher UI on the city screen
- [ ] Star-funded events: "Festival" (+population for X rounds), "Marketing campaign" (boosts attractiveness), 2–3 event types
- [ ] Aggregate-needs system extended: parameterize service ratios from `serviceProvision` data, so adding a new building type is data-only
- [ ] **Exit criteria:** A returning player has unlocked at least one new building type via lifetime stars, expanded their land once, switched between two map themes, and run an event

---

### Phase 9 — Player Progress Screen (target: ~1 week)
- [ ] Concept proficiency visualization (radar chart or color grid) — rolled up to category
- [ ] Strengths and growing edges sections with positive framing
- [ ] Lifetime stats: stars earned, sessions, questions answered
- [ ] **Exit criteria:** Player can see and feel proud of their own progress

---

### Phase 10 — Sound, Polish, Engagement (target: ~2–3 weeks)
- [ ] Final SFX library (CC0/royalty-free); per-event audio (spin, correct, wrong, building-placed, level-up)
- [ ] Background music (looping, with mute toggle)
- [ ] Animation polish (character reactions on correct/wrong; screen transitions)
- [ ] Daily streak tracking + bonus stars
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

### Phase 11 — Cloud Save (target: ~1–2 weeks)
- [ ] **Prerequisite:** Replace the wipe-and-recreate Drift migration pattern (used through v3 and v4) with proper additive migrations. Once player data lives off-device, schema wipes destroy real data — this must land *before* the cloud-save round-trip is enabled
- [ ] Integrate `games_services` save game API
- [ ] Sign-in flow (Game Center / Play Games) — graceful skip if signed out
- [ ] Save-on-meaningful-event (round end, avatar edit, building placed, map unlocked)
- [ ] Load on app start; conflict resolution (prefer most recent)
- [ ] iOS verification (deferred from Phase 0 — `flutter run` on iOS simulator must succeed before this phase ships)
- [ ] **Exit criteria:** Install on a second device, sign in, see same player data including avatar, stars, and city state

---

### Phase 12 — Beta + Store Submission (ongoing)
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
- **By Phase 7:** Specific isometric-asset packs — Kenney's [City Kit Industrial](https://kenney.nl/assets/city-kit-industrial) is a strong starting point but coverage is limited. Identify supplementary packs (Kenney's other city packs, [OpenGameArt isometric tag](https://opengameart.org/art-search-advanced?keys=isometric)) before catalog work begins.
- **By Phase 8:** Specific list of building types and their service-ratio numbers (residents-per-school, etc.) — can only be tuned by play-testing.
- **By Phase 10:** Music + SFX sourcing (CC0 from Freesound.org and OpenGameArt.org).
- **By Phase 11:** Are we OK requiring the user to sign in to Game Center / Play Games for cloud save? Otherwise local-only is the only option.
- **By Phase 12:** Privacy policy text — minimal since we collect ~nothing, but COPPA considerations for under-13 audience need legal review or a template.

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Core loop isn't fun for kids | Medium | Critical | Phase 1 explicitly tested this with a real kid before any further investment — passed |
| Question dataset gap | Medium | High | Algorithmic generation handles arithmetic; for everything else, multiple datasets identified (GSM8K, MathDataset-ElementarySchool, Illustrative Mathematics) |
| ~~Avatar library doesn't cover all 8 slots~~ | — | — | Resolved: avatar accessories dropped from scope after Phase 4 spike — single star sink is the city builder |
| City UX on small screens (placement, panning, zoom on a phone) | Medium | High | Auto-roads (no precision needed); tile-snap with generous tap targets; pinch-zoom + pan; play-test on smallest target device early in Phase 7 |
| Isometric asset coverage gap | Medium | Medium | Kenney's City Kit packs are the starting point but limited; identify 1–2 supplementary CC0 packs in early Phase 7. If coverage is still sparse, narrow the v1 building catalog rather than ship inconsistent art |
| Population growth model feels arbitrary or unmotivating | Medium | Medium | Keep model simple (aggregate ratios, not per-building dependency graphs); tune via play-testing. Vague-but-themed feedback messages keep the player oriented even if numbers shift |
| City save state migration as schema evolves across phases | Medium | Medium | Drift migrations are version-checked; player's city is purely cosmetic so a wipe is a survivable last resort. Bias toward additive schema changes |
| Cloud save platform divergence | Low (single package) | Medium | `games_services` abstracts both — but test on both platforms early in Phase 11 |
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

**City builder asset candidates (Phase 7)**
- [Kenney City Kit Industrial](https://kenney.nl/assets/city-kit-industrial) — CC0 isometric
- [Kenney all assets](https://kenney.nl/assets) — search "city" / "isometric"
- [OpenGameArt isometric tag](https://opengameart.org/art-search-advanced?keys=isometric) — CC0 / CC-BY mix

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
