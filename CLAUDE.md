# CLAUDE.md

Guidance for Claude Code (and other AI agents) working in this repo.

## What this project is

**Math Dash** — a free, open, cross-platform mobile math game for kids ages 6–14.
- Product scope: see [prd.md](prd.md) — read this before suggesting any feature.
- Execution plan: see [plan.md](plan.md) — read this before suggesting any code.
- Curriculum / concept catalog: see [curriculum.md](curriculum.md) — canonical K–8 sub-concept taxonomy with prereq DAG, source strategy, and diagram needs. Read this before adding/modifying questions or generators.

## Where we are right now

The **Status block at the top of [plan.md](plan.md)** is the source of truth for current phase, last action, and next action. Read it first at the start of every session — it tells you what's in scope right now and what isn't.

## Tech stack (locked — see plan.md "Locked Decisions" for rationale)

- **Flutter** + **Flame** game engine
- **Riverpod 3** for state management
- **Drift** (SQLite) for local persistence
- **flame_audio** for sound
- **games_services** for cross-platform cloud save (Game Center / Play Games)

Do not propose alternatives unless asked, or unless one of these is shown to be unsuitable.

## Architecture

Four layers, top to bottom:
1. **Presentation** (`lib/presentation/`) — Flutter widgets
2. **Game** (`lib/game/`) — Flame components
3. **Domain** (`lib/domain/`) — pure Dart rules (no Flutter/Flame imports — this is the testable core)
4. **Data** (`lib/data/`) — Drift schema, repositories, cloud-save bridge

State flows via Riverpod providers at the boundary between presentation and domain.

## Commands

> Project skeleton not yet created — these will apply once Phase 0 is done.

```sh
flutter pub get        # install deps
flutter run            # run on connected device/simulator
flutter test           # run all tests
flutter analyze        # static analysis
dart format .          # format
```

## Conventions

- **No new dependencies without discussion.** Every package added is licensing surface area (this is a free-software project — see PRD's "Content & Licensing" section).
- **Domain layer stays pure.** No Flutter, Flame, or platform imports under `lib/domain/`. If you need to test logic, that's where it goes.
- **Tests live in `test/`, mirroring `lib/` structure.** Bias heavily toward unit-testing the domain layer; widget/integration tests are higher cost.
- **Question content is mostly algorithmic, not bundled data.** Per [curriculum.md](curriculum.md), ~85% of K–8 content comes from parameterized Dart generators in `lib/domain/questions/` with procedural diagram widgets in `lib/presentation/diagrams/`. The remaining ~10% is bundled curated dataset content in `assets/data/` (seeded into Drift on first run). **No runtime LLM calls; no offline LLM batch generation in v1.**
- **Diagrams are pure-Flutter widgets, parameterized.** `lib/domain/` emits `DiagramSpec` value types (a sealed family); `lib/presentation/diagrams/` dispatches to widgets. This preserves the "no Flutter imports under `lib/domain/`" rule.
- **Asset & content licensing.** Every art/audio/font asset must be CC0, CC-BY, or equivalent. Every math dataset must be MIT / Apache 2.0 / CC-BY / CC0 — **CC-BY-NC and CC-BY-NC-SA are excluded** because app-store distribution carries non-zero commercial-use risk. Track sources in `LICENSES_THIRD_PARTY.md` (to be created in Phase 6 alongside dataset ingestion).
- **Don't speculate features.** Stay within the current phase scope in `plan.md`. Future phases are aspirational, not a TODO list.

## Working incrementally

This is a hobby project being built in small sessions. Optimize for "next session can pick up easily":
- At end of session, update `plan.md` Status block (current phase, last action, next action).
- Check off completed phase tasks.
- If you discover something blocking, add it to "Open Questions" in `plan.md`.
- Prefer many small commits with clear messages over large ones.

## What NOT to do

- Don't add ads, analytics SDKs, or tracking. The PRD is explicit: free, no ads, no monetization.
- Don't propose Firebase / Supabase / a custom backend for save data. We use platform cloud save (`games_services`).
- Don't add complexity for hypothetical future features.
- Don't write defensive code for impossible inputs in internal APIs.
- Don't create new top-level docs without discussion. `prd.md`, `plan.md`, `curriculum.md`, and this file are the canonical set.
