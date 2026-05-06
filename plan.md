# Math Dash — Implementation Plan

> Living document. Update as decisions are made and phases progress.
> Source of truth for product scope: [prd.md](prd.md).

---

## Status

- **Phase:** Phase 4 complete. Ready for Phase 5.
- **Last updated:** 2026-05-04
- **Last action:** Completed Phase 4: DiceBear Adventurer avatar system fully implemented. Bundled SVG path constants in `adventurer_svg_data.dart` (generated via Python from DiceBear TypeScript source); `adventurer_composer.dart` assembles layers offline; slot picker UI in `player_creation_screen.dart` (hair style/color, skin, eyes, mouth, glasses, earrings, blush/freckles); `AdventurerAvatarWidget` renders via `SvgPicture.string`. Schema v3: `totalStars` split into `currentStars` + `lifetimeStarsEarned`. Avatar shown on home, spin, and creation screens. Old CustomPainter (`avatar_config.dart`, `avatar_widget.dart`) deleted. All 51 tests pass, `flutter analyze` clean.
- **Next action:** Start Phase 5 — City Builder: Foundations. Begin by sourcing isometric building art (Kenney City Kit Industrial, CC0) and defining Drift schema v4 (`City`, `CityMap`, `BuildingType`, `BuildingPlacement`).
- **Deferred:** Audio SFX + background music (CC0 assets not sourced yet — stub in place). iOS verification. Both revisit before Phase 9 at latest.

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

// --- City builder (Phase 5+) ---

City (per player, per map)
  id, playerId, mapId,
  gridWidth, gridHeight,         // grows on land expansion (Phase 6)
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

Fractions, geometry, and word problems are deferred to Phase 6.

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
math_dash/
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
│   │   ├── city/          # city-builder screen (Phase 5+)
│   │   ├── progress/
│   │   └── settings/
│   ├── game/              # Flame components
│   │   ├── spin_wheel/
│   │   ├── city/          # isometric city renderer (Phase 5+)
│   │   ├── question_view/
│   │   └── effects/
│   ├── domain/            # pure Dart: rules, no Flutter imports
│   │   ├── concepts/
│   │   ├── proficiency/
│   │   ├── questions/
│   │   ├── stars/
│   │   ├── avatar/        # AdventurerConfig + curated slot catalogs
│   │   └── city/          # buildings, growth model, population math (Phase 5+)
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
- [x] **Exit criteria (Path B — Android only):** `flutter run` launched the placeholder Math Dash app on the Android emulator (Pixel 7, API 34) successfully. iOS verification deferred to Phase 7
- [ ] iOS exit criteria — deferred until Xcode is installed (no later than Phase 7)

### Phase 1 — Vertical Slice (target: ~2–3 weeks) [the most important phase]
**Goal: prove the core loop is fun.** Hardcoded single player, two concepts, no persistence beyond runtime. Concepts and proficiency math are specified in *Domain Specs* above.
- [x] Concept registry with the two Phase 1 concepts (`add_1digit`, `sub_1digit`)
- [x] Algorithmic question generator with operand ranges per spec; distractor strategy per spec
- [x] `SpinWheel` Flame component (4 segments, tap-to-spin animation, lands on a concept)
- [x] `QuestionScreen` with 4-option multiple choice
- [x] `ResultScreen` with star award + wrong-answer explanation
- [x] Loop: home → spin → question → result → home, with star counter persisted in memory
- [ ] Basic SFX (spin, correct, wrong) and one looping background track — deferred to Phase 6 (CC0 assets not sourced; stub in place)
- [x] **Exit criteria:** Test with a real kid in the target age range — passed.

### Phase 2 — Adaptive Concept System (target: ~2–3 weeks)

**Design decisions (locked):**
- **Player:** A single default player is seeded into Drift on first launch. Full player creation / profile picker is Phase 3.
- **Numeric input UX:** Comfortable-band questions use an on-screen number pad (calculator-style) with an explicit submit button. Device keyboard not used. Text-answer question types deferred.
- **Concept expansion:** Only algorithmically generatable concepts added this phase (see *Domain Specs — Phase 2 concepts* below). Fractions, geometry, and word problems deferred to Phase 6.

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

**Goal:** Replace the Phase 3 CustomPainter chibi with a DiceBear Adventurer avatar that the player can edit anytime. Stars persist across app restarts so they're meaningful as a Phase 5 city-builder currency.

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

### Phase 5 — City Builder: Foundations (target: ~3–4 weeks)

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

### Phase 6 — City Builder: Depth (target: ~2–3 weeks)

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

### Phase 7 — Player Progress Screen (target: ~1 week)
- [ ] Concept proficiency visualization (radar chart or color grid) — rolled up to category
- [ ] Strengths and growing edges sections with positive framing
- [ ] Lifetime stats: stars earned, sessions, questions answered
- [ ] **Exit criteria:** Player can see and feel proud of their own progress

---

### Phase 8 — Sound, Polish, Engagement (target: ~2–3 weeks)
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

### Phase 9 — Cloud Save (target: ~1–2 weeks)
- [ ] Integrate `games_services` save game API
- [ ] Sign-in flow (Game Center / Play Games) — graceful skip if signed out
- [ ] Save-on-meaningful-event (round end, avatar edit, building placed, map unlocked)
- [ ] Load on app start; conflict resolution (prefer most recent)
- [ ] iOS verification (deferred from Phase 0 — `flutter run` on iOS simulator must succeed before this phase ships)
- [ ] **Exit criteria:** Install on a second device, sign in, see same player data including avatar, stars, and city state

---

### Phase 10 — Beta + Store Submission (ongoing)
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
- **By Phase 2:** Question dataset sourcing strategy for non-arithmetic concepts — curate from [GSM8K](https://github.com/openai/grade-school-math) (MIT license) and [MathDataset-ElementarySchool](https://github.com/RamonKaspar/MathDataset-ElementarySchool), or generate via batch LLM? Probably both — start with curation. Defer to Phase 6+ when fractions/word problems are added.
- **By Phase 4 (resolved):** Avatar library pick — DiceBear Adventurer chosen; avatar accessory shop dropped. See *Locked Decisions*.
- **By Phase 5:** Specific isometric-asset packs — Kenney's [City Kit Industrial](https://kenney.nl/assets/city-kit-industrial) is a strong starting point but coverage is limited. Identify supplementary packs (Kenney's other city packs, [OpenGameArt isometric tag](https://opengameart.org/art-search-advanced?keys=isometric)) before catalog work begins.
- **By Phase 6:** Specific list of building types and their service-ratio numbers (residents-per-school, etc.) — can only be tuned by play-testing.
- **By Phase 8:** Music + SFX sourcing (CC0 from Freesound.org and OpenGameArt.org).
- **By Phase 9:** Are we OK requiring the user to sign in to Game Center / Play Games for cloud save? Otherwise local-only is the only option.
- **By Phase 10:** Privacy policy text — minimal since we collect ~nothing, but COPPA considerations for under-13 audience need legal review or a template.

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Core loop isn't fun for kids | Medium | Critical | Phase 1 explicitly tested this with a real kid before any further investment — passed |
| Question dataset gap | Medium | High | Algorithmic generation handles arithmetic; for everything else, multiple datasets identified (GSM8K, MathDataset-ElementarySchool, Illustrative Mathematics) |
| ~~Avatar library doesn't cover all 8 slots~~ | — | — | Resolved: avatar accessories dropped from scope after Phase 4 spike — single star sink is the city builder |
| City UX on small screens (placement, panning, zoom on a phone) | Medium | High | Auto-roads (no precision needed); tile-snap with generous tap targets; pinch-zoom + pan; play-test on smallest target device early in Phase 5 |
| Isometric asset coverage gap | Medium | Medium | Kenney's City Kit packs are the starting point but limited; identify 1–2 supplementary CC0 packs in early Phase 5. If coverage is still sparse, narrow the v1 building catalog rather than ship inconsistent art |
| Population growth model feels arbitrary or unmotivating | Medium | Medium | Keep model simple (aggregate ratios, not per-building dependency graphs); tune via play-testing. Vague-but-themed feedback messages keep the player oriented even if numbers shift |
| City save state migration as schema evolves across phases | Medium | Medium | Drift migrations are version-checked; player's city is purely cosmetic so a wipe is a survivable last resort. Bias toward additive schema changes |
| Cloud save platform divergence | Low (single package) | Medium | `games_services` abstracts both — but test on both platforms early in Phase 9 |
| `games_services` package abandonment | Low | Medium | If it goes stale, fall back to platform-specific packages (`cloud_kit` for iOS, `googleapis` Drive for Android) |
| Hive/Isar abandonment pattern repeats with Drift | Low | Low | Drift is built on SQLite; worst-case migration to raw `sqflite` is straightforward |
| COPPA / children's-app compliance | Medium | High (could block store submission) | No data collection; address this explicitly in Phase 10 with a minimal privacy policy and store-listing kids-category settings |
| Apple Developer Program ($99/yr) and Play Console ($25 one-time) fees | Certain | Low–Medium | Real ongoing cost for a "free hobby project." If the Apple membership lapses, the iOS build is delisted from the App Store. Budget accordingly; consider whether one platform-only launch buys more time |
| Sub-concept catalog explosion | Medium | Medium | The category→concept taxonomy in PRD lists ~40+ concepts already; full K–8 could push past 100. Mitigate by defining only what's needed per phase (Phase 1: 2 concepts; Phase 2: ~10; Phase 8+: full) and keeping the schema flexible |

---

## How We Work (AI-Assisted Conventions)

Since this is a two-person project (you + Claude), some norms to keep us efficient:

- **PRD is product scope, plan.md is execution.** Don't conflate. If product scope changes, update [prd.md](prd.md). If execution approach changes, update this file.
- **Update `Status` section** at the top of this file at the end of each work session — current phase, last action, next action. Keeps the next session cold-startable.
- **Check off phase task boxes as we go** so we always know where we are.
- **Open questions go in the "Open Questions" section above** — don't let them get buried in chat. When answered, move the answer into the relevant phase or "Locked Decisions."
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

**City builder asset candidates (Phase 5)**
- [Kenney City Kit Industrial](https://kenney.nl/assets/city-kit-industrial) — CC0 isometric
- [Kenney all assets](https://kenney.nl/assets) — search "city" / "isometric"
- [OpenGameArt isometric tag](https://opengameart.org/art-search-advanced?keys=isometric) — CC0 / CC-BY mix

**Math content sources**
- [GSM8K dataset](https://github.com/openai/grade-school-math) (MIT)
- [MathDataset-ElementarySchool](https://github.com/RamonKaspar/MathDataset-ElementarySchool)
- [Illustrative Mathematics](https://illustrativemathematics.org/math-curriculum/) (CC BY-NC)
- [Open Up Resources 6–8 Math](https://openupresources.org/) (CC BY-NC 4.0)

**Audio / general assets**
- [OpenGameArt.org](https://opengameart.org/) — CC0/CC-BY art assets
- [Freesound.org](https://freesound.org/) — CC-licensed audio
