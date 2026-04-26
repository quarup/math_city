# Math Dash — Implementation Plan

> Living document. Update as decisions are made and phases progress.
> Source of truth for product scope: [prd.md](prd.md).

---

## Status

- **Phase:** Phase 0 — Foundation (not yet started)
- **Last updated:** 2026-04-27
- **Next action:** Set up Flutter project skeleton

---

## Locked Decisions

| Area | Choice | Rationale |
|---|---|---|
| **Framework** | Flutter (stable channel) + [Flame](https://flame-engine.org/) game engine | Single codebase for iOS+Android; Flame actively maintained in 2026 (Flame Game Jam 2026 ran in March); BSD-licensed; provides sprite/animation/gesture primitives we need for the spin wheel and avatar |
| **Language** | Dart 3.x | Required by Flutter |
| **State management** | [Riverpod](https://riverpod.dev/) 3.x | Recommended default for new Flutter projects in 2026; compile-time safety, low boilerplate, great testability |
| **Local persistence** | [Drift](https://pub.dev/packages/drift) (SQLite + compile-time-safe queries) | Best-supported in 2026 (Hive and Isar are now community-maintained after author stepped away); SQL is great for filtering questions by skill+difficulty band; predictable migrations |
| **Audio** | [`flame_audio`](https://pub.dev/packages/flame_audio) (wrapper over `audioplayers`) | Natural fit with Flame; supports SFX pools and background music |
| **Cloud save** | [`games_services`](https://pub.dev/packages/games_services) package — Google Play Games (Android) + Game Center / iCloud (iOS) | Only solution that satisfies the PRD's "no custom server" requirement on both platforms with a single API. Last updated Dec 2025 |
| **Skill granularity** | Track proficiency at **sub-skill** level (e.g. "2-digit addition with carry"), not at category level. Roll up to category for display only | Otherwise the adaptive wheel is too coarse: a kid who's mastered single-digit addition would falsely look ready for multi-digit. See PRD's Skill System section for the category→skill taxonomy |
| **Repo plan doc** | `plan.md` at repo root | Simple, greppable, lives next to `prd.md` |
| **AI agent doc** | `CLAUDE.md` at repo root | Emerging convention; auto-loaded by Claude Code each session |

---

## Architecture Overview

Four layers, top to bottom:

1. **Presentation (Flutter widgets)** — screens, navigation, forms (player creation, shop, progress screen, settings).
2. **Game (Flame components)** — spin wheel, avatar render, question presentation, animations, audio cues.
3. **Domain (pure Dart)** — game rules: skill-band classification, proficiency updates, wheel selection logic, milestone unlocks, star math. **No Flutter or Flame imports here** — keeps it unit-testable and portable.
4. **Data (Drift + cloud-save)** — local SQLite for player profiles, proficiency records, owned items; question catalog as a read-only seeded table; cloud-save bridge for backup/restore.

State management (Riverpod) sits at the boundary between presentation and domain — providers expose domain objects to widgets reactively.

---

## Data Model (sketch — refine in Phase 1)

```
Player
  id, name, gradeLevel, createdAt
  avatarConfig (skinTone, hair, eyes, baseClothing)
  totalStars, currentStreak, lastPlayedDate
  unlockedRewardCategories (list)
  ownedItems (list of itemIds)
  equippedItems (map of slot → itemId)

SkillProficiency
  playerId, skillId, proficiency (0.0–1.0), lastUpdatedAt
  questionsAnswered, questionsCorrect

Skill (static catalog) — sub-skill granularity (e.g. "2-digit addition with carry")
  id, name, categoryId, gradeRange, description

SkillCategory (static catalog) — display grouping only (e.g. "Addition & subtraction")
  id, name, displayOrder

Question (static catalog for non-arithmetic skills; arithmetic generated at runtime)
  id, skillId, difficultyBand (comfortable | challenging),
  prompt (text or template), correctAnswer,
  distractors (for multiple-choice), explanation (for wrong-answer screen)
  source (algorithmic | curated | ai_generated), license

Item (static catalog — cosmetics)
  id, categoryId, name, starCost, assetPath, slot

Milestone (static catalog)
  index, starThreshold, unlockedAt (per-player, in PlayerProgress table)

GameSession (in-memory only)
  startedAt, players (list), roundsPlayed
  // Streak lives on Player, not here
```

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
│   │   ├── player/
│   │   ├── shop/
│   │   ├── progress/
│   │   └── settings/
│   ├── game/              # Flame components
│   │   ├── spin_wheel/
│   │   ├── avatar/
│   │   ├── question_view/
│   │   └── effects/
│   ├── domain/            # pure Dart: rules, no Flutter imports
│   │   ├── skills/
│   │   ├── proficiency/
│   │   ├── questions/
│   │   ├── milestones/
│   │   └── stars/
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

### Phase 0 — Foundation (target: ~1 week)
- [ ] Confirm Flutter SDK installed; create `flutter create math_dash` skeleton in this repo
- [ ] Add locked dependencies (`flame`, `flutter_riverpod`, `drift`, `flame_audio`, `games_services`)
- [ ] Set up linting (`flutter_lints` or `very_good_analysis`) and `dart format` defaults
- [ ] Set up GitHub Actions CI: format check, analyze, test
- [ ] Decide initial skill scope for Phase 1 (proposed: addition + subtraction at grades 1–3)
- [ ] Sketch the proficiency-update math (formula for moving 0.0→1.0 on correct/wrong)
- [ ] **Exit criteria:** `flutter run` launches an empty app with our brand color scheme on the iOS simulator AND an Android emulator; CI passes on a no-op PR

### Phase 1 — Vertical Slice (target: ~2–3 weeks) [the most important phase]
**Goal: prove the core loop is fun.** Hardcoded single player, two skills, no persistence beyond runtime.
- [ ] Skill registry with two skills (addition, subtraction)
- [ ] Algorithmic question generator for those skills (with grade-1–3 number ranges)
- [ ] `SpinWheel` Flame component (4–6 segments, tap-to-spin animation, lands on a skill)
- [ ] `QuestionScreen` with 4-option multiple choice
- [ ] `ResultScreen` with star award + simple animation + wrong-answer explanation
- [ ] Loop: home → spin → question → result → home, with star counter persisted in memory
- [ ] Basic SFX (spin, correct, wrong) and one looping background track
- [ ] **Exit criteria:** Test with a real kid in the target age range. Concrete signals to look for:
  - Did they spin at least 10 times without prompting?
  - Did they ask to play again, or come back to it the next day unprompted?
  - Did they react positively to correct-answer celebrations (smiles, "yes!")?
  - When they got a wrong answer, did they read the explanation, or just tap through?
  - **Hard gate:** if they put the device down within 5 minutes and didn't come back, stop and rethink the loop before Phase 2.

### Phase 2 — Adaptive Skill System (target: ~2–3 weeks)
- [ ] Drift schema for `Player`, `SkillProficiency`, `Question` (catalog seeding)
- [ ] Proficiency update logic (correct → up, wrong → down with floor); unit tests
- [ ] Band classifier (mastered / comfortable / challenging / not yet) with grade-aware thresholds
- [ ] Wheel selection: weighted sample of comfortable + challenging bands only
- [ ] Typed-input mode for comfortable-band skills
- [ ] Expand to ~5 skill categories (add multiplication, fractions, geometry — start with placeholder questions)
- [ ] **Exit criteria:** A returning player sees the wheel adapt — easy skills disappear, harder ones appear, typed input shows up for skills they've practiced

### Phase 3 — Player Profiles & Avatar (target: ~2 weeks)
- [ ] Player creation flow (name, grade, basic avatar)
- [ ] Profile picker on app launch
- [ ] Mid-session player switching at start of each round
- [ ] Sprite-layer-based avatar (slots: skin, hair, eyes, top, bottom — each a layer)
- [ ] **Exit criteria:** Two kids can share the device with separate stats and avatars

### Phase 4 — Stars, Milestones, Shop (target: ~2 weeks)
- [ ] Persistent star totals per player
- [ ] Milestone detection + celebration screen with category choice
- [ ] Shop / wardrobe UI with affordability filtering
- [ ] Initial cosmetic item set (pets, hats, vehicles — minimum 5 per category)
- [ ] Equip/unequip with avatar live preview
- [ ] **Exit criteria:** A kid can earn stars, hit a milestone, choose a category, buy something, and see it on their character

### Phase 5 — Player Progress Screen (target: ~1 week)
- [ ] Skill proficiency visualization (radar chart or color grid)
- [ ] Strengths and growing edges sections with positive framing
- [ ] Milestone timeline
- [ ] **Exit criteria:** Player can see and feel proud of their own progress

### Phase 6 — Sound, Polish, Engagement (target: ~2 weeks)
- [ ] Final SFX library (CC0/royalty-free); per-event audio
- [ ] Animation polish (character reactions, screen transitions)
- [ ] Daily streak tracking + bonus stars
- [ ] Daily challenge mechanic
- [ ] First-launch tutorial
- [ ] Settings screen (audio mute, reset profile, etc.)
- [ ] **Exit criteria:** It feels like a real game, not a prototype

### Phase 7 — Cloud Save (target: ~1–2 weeks)
- [ ] Integrate `games_services` save game API
- [ ] Sign-in flow (Game Center / Play Games) — graceful skip if signed out
- [ ] Save-on-meaningful-event (round end, milestone, item purchase)
- [ ] Load on app start; conflict resolution (prefer most recent)
- [ ] **Exit criteria:** Install on a second device, sign in, see same player data

### Phase 8 — Beta + Store Submission (ongoing)
- [ ] TestFlight (iOS) and Play Console internal testing channel
- [ ] Privacy policy (required by both stores even for free apps)
- [ ] App Store / Play Store listings, screenshots, icon
- [ ] Iterate on real beta feedback
- [ ] Submit to stores

---

## Open Questions / Decisions Deferred

These are not blockers for Phase 0 or 1 but need to be resolved by the phase noted:

- **By Phase 2:** What's the exact proficiency update formula? Bayesian update? Simple exponential moving average? Pick simplest that works.
- **By Phase 2:** Question dataset sourcing strategy — for arithmetic skills, algorithmic generation is fine. For word problems, do we curate from [GSM8K](https://github.com/openai/grade-school-math) (MIT license) and [MathDataset-ElementarySchool](https://github.com/RamonKaspar/MathDataset-ElementarySchool), or generate via batch LLM? Probably both — start with curation.
- **By Phase 3:** Avatar art source — commission, find on [OpenGameArt.org](https://opengameart.org/), or generate? Constrains visual style.
- **By Phase 6:** Music + SFX sourcing (CC0 from Freesound.org and OpenGameArt.org).
- **By Phase 7:** Are we OK requiring the user to sign in to Game Center / Play Games for cloud save? Otherwise local-only is the only option.
- **By Phase 8:** Privacy policy text — minimal since we collect ~nothing, but COPPA considerations for under-13 audience need legal review or a template.

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Core loop isn't fun for kids | Medium | Critical | Phase 1 explicitly tests this with a real kid before any further investment |
| Question dataset gap | Medium | High | Algorithmic generation handles arithmetic; for everything else, multiple datasets identified (GSM8K, MathDataset-ElementarySchool, Illustrative Mathematics) |
| Avatar layering complexity | Medium | Medium | Constrain to fixed slots; lean on sprite layering, not 3D |
| Cloud save platform divergence | Low (single package) | Medium | `games_services` abstracts both — but test on both platforms early in Phase 7 |
| `games_services` package abandonment | Low | Medium | If it goes stale, fall back to platform-specific packages (`cloud_kit` for iOS, `googleapis` Drive for Android) |
| Hive/Isar abandonment pattern repeats with Drift | Low | Low | Drift is built on SQLite; worst-case migration to raw `sqflite` is straightforward |
| COPPA / children's-app compliance | Medium | High (could block store submission) | No data collection; address this explicitly in Phase 8 with a minimal privacy policy and store-listing kids-category settings |
| Apple Developer Program ($99/yr) and Play Console ($25 one-time) fees | Certain | Low–Medium | Real ongoing cost for a "free hobby project." If the Apple membership lapses, the iOS build is delisted from the App Store. Budget accordingly; consider whether one platform-only launch buys more time |
| Sub-skill catalog explosion | Medium | Medium | The category→skill taxonomy in PRD lists ~40+ skills already; full K–8 could push past 100. Mitigate by defining only what's needed per phase (Phase 1: 2 skills; Phase 2: ~10; Phase 6+: full) and keeping the schema flexible |

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

- [Flame Engine docs](https://docs.flame-engine.org/)
- [Flutter Casual Games Toolkit](https://docs.flutter.dev/resources/games-toolkit)
- [Riverpod docs](https://riverpod.dev/)
- [Drift docs](https://drift.simonbinder.eu/)
- [games_services package](https://pub.dev/packages/games_services)
- [flame_audio package](https://pub.dev/packages/flame_audio)
- [GSM8K dataset](https://github.com/openai/grade-school-math) (MIT)
- [MathDataset-ElementarySchool](https://github.com/RamonKaspar/MathDataset-ElementarySchool)
- [Illustrative Mathematics](https://illustrativemathematics.org/math-curriculum/) (CC BY-NC)
- [Open Up Resources 6–8 Math](https://openupresources.org/) (CC BY-NC 4.0)
- [OpenGameArt.org](https://opengameart.org/) — CC0/CC-BY art assets
- [Freesound.org](https://freesound.org/) — CC-licensed audio
