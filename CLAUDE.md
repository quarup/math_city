# CLAUDE.md

Guidance for Claude Code (and other AI agents) working in this repo.

## What this project is

**Math City** — a free, open, cross-platform mobile math game for kids ages 6–14.
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

```sh
flutter pub get        # install deps
flutter run            # run on connected device/simulator
flutter test           # run all tests
flutter analyze        # static analysis
dart format .          # format
```

## Finding UX bugs in question content

**`/ux-sweep` is the main tool for auditing question quality.** Use it
whenever you touch generators or diagram widgets, and before calling a
content phase done. It plays real questions on the emulator and writes a
reviewed, screenshotted report.

```
/ux-sweep 3.5              # one curriculum section
/ux-sweep fractions        # a category
/ux-sweep add_within_10    # a single concept
/ux-sweep all              # the whole catalogue (~27 min, ~60 MB of PNGs)
```

Per concept it captures the question screen in **both** input modes
(multiple choice and keypad), answers it correctly and checks the green
screen, then replays the identical question from its seed, answers it
wrong, and captures the red screen with its explanation. Output lands in
`ux_reports/<date>-<scope>-<band>/report.md`, committed alongside the
code.

**Shrink the screenshots before committing a sweep.** A full-catalogue run
is ~1000 PNGs at ~86 MB; `python3 tools/ux_sweep/shrink_shots.py <report-dir>`
takes that to ~9.7 MB without renaming anything, so `report.md` and
`probe.jsonl` need no edits — then re-run `build_report.py` to confirm it
still exits `0`. The measured alternatives (WebP is worse; quantizing
without resizing is not enough) are recorded in the skill's "Shrinking the
screenshots" section so nobody re-derives them.

It found two real bugs on its first run, so treat its findings as
credible. Full workflow — including resuming an interrupted sweep — is in
[.claude/skills/ux-sweep/SKILL.md](.claude/skills/ux-sweep/SKILL.md).

**How it works, and why you can't drive the app by hand instead.** The app
runs a `kDebugMode`-only HTTP control port
([lib/services/debug_harness.dart](lib/services/debug_harness.dart)) on
`127.0.0.1:8081`, driven by [tools/ux_sweep/uxctl.py](tools/ux_sweep/uxctl.py)
over `adb forward`. The port takes a concept id and puts that question on
screen — no tapping, no navigating by screenshot — and hands back the
correct answer, the displayed choice order, and any `FlutterError`s raised
while the screen rendered. That last part means **overflows and build
exceptions arrive as data**, not as something you have to spot in pixels.
Getting the answer from the app rather than solving it from a screenshot
is the whole point: an agent doing the maths itself gets some wrong and
files bugs that aren't real.

If you add state to `QuestionScreen` or `ResultScreen`, keep the
`DebugHarness.instance.attach*` calls intact or the sweep goes blind.

`build_report.py` **validates its own coverage** and exits non-zero if
anything is missing — a probe that died partway, a concept with no note, a
note with an invalid verdict, a missing screenshot. Never present a report
that exited non-zero as finished.

## Conventions

- **No new dependencies without discussion.** Every package added is licensing surface area (this is a free-software project — see PRD's "Content & Licensing" section).
- **Domain layer stays pure.** No Flutter, Flame, or platform imports under `lib/domain/`. If you need to test logic, that's where it goes.
- **Tests live in `test/`, mirroring `lib/` structure.** Bias heavily toward unit-testing the domain layer; widget/integration tests are higher cost.
- **Question content is mostly algorithmic, not bundled data.** Per [curriculum.md](curriculum.md), ~85% of K–8 content comes from parameterized Dart generators in `lib/domain/questions/` with procedural diagram widgets in `lib/presentation/diagrams/`. The remaining ~10% is bundled curated dataset content in `assets/data/` (seeded into Drift on first run). **No runtime LLM calls; no offline LLM batch generation in v1.**
- **Diagrams are pure-Flutter widgets, parameterized.** `lib/domain/` emits `DiagramSpec` value types (a sealed family); `lib/presentation/diagrams/` dispatches to widgets. This preserves the "no Flutter imports under `lib/domain/`" rule.
- **Asset & content licensing.** Every art/audio/font asset must be CC0, CC-BY, or equivalent. Every math dataset must be MIT / Apache 2.0 / CC-BY / CC0 — **CC-BY-NC and CC-BY-NC-SA are excluded** because app-store distribution carries non-zero commercial-use risk. Track sources in `LICENSES_THIRD_PARTY.md` (to be created in Phase 6 alongside dataset ingestion).
- **Don't speculate features.** Stay within the current phase scope in `plan.md`. Future phases are aspirational, not a TODO list.

## Preserving player data across updates

Kids now play on real iPads, so **an app update must never wipe a
player's progress.** The schema history (v9, v11, v14, v16) wiped
everything on upgrade under a "pre-launch, no real users" rule. That rule
is over. Expect some disruption when content changes (a retired building
refunded, the wheel reshuffled); never a reset.

- **Database upgrades are additive.** In `onUpgrade` in
  [lib/data/database.dart](lib/data/database.dart), add tables and
  columns; never `DROP TABLE` a table that holds player data. To rename or
  drop a column, use Drift's table rebuild (`TableMigration`), which
  copies the rows across. Caches of bundled assets (`dataset_questions`)
  are the exception: they are rebuilt from the assets anyway.
- **IDs are permanent.** Saved rows refer to concepts, buildings, beats,
  maps and events by string ID (`single_home`, `add_within_10`). Change
  art, prices, footprints, names, prereqs and triggers freely — they are
  looked up by ID at runtime. Renaming or deleting an ID silently orphans
  that progress, so don't, unless the same change maps the old ID to its
  replacement (or retires it with a refund) during the upgrade.
- **Save facts, recompute the rest.** Store what the player did (answers
  and proficiency per concept, concepts introduced, buildings placed,
  coins paid, beats read) and derive everything else — what's unlocked,
  the wheel, the next beat, population capacity — from the current DAGs
  and catalogs at runtime. Then reshaping the question DAG or the beat
  chain needs no migration. A stored *position* in a scripted sequence
  (`Players.guideStep`) is the exception, and inserting or reordering
  steps needs an upgrade step (see v20).
- **Code tolerates unknown IDs.** A saved ID the current code no longer
  knows is skipped, never force-unwrapped. The city and beats code already
  does this (`findBuildingTypeById` / `findBeatById` return null).

Known gaps against these rules are tracked in plan.md under Phase 13
(*Preserving player data*). Check them before changing the schema or
renaming content.

## App icon, launch screens and the home-screen tile art

The launcher icon, the Android/iOS launch-screen images and the six tile
SVGs the home-screen intro animates all come from one script:

```sh
tools/sprite_pipeline/.venv/bin/python tools/app_icon/build_icon.py
```

Never hand-edit the PNGs under `android/app/src/main/res/mipmap-*/`,
`ios/Runner/Assets.xcassets/`, or `assets/images/tiles/` — change the
drawing in the script and re-run it. The home screen's first frame is
designed to be pixel-identical to the OS launch screen (flat sky, the
icon's house on a 288 dp canvas), so the geometry constants in
[tile_patch.dart](lib/presentation/home/tile_patch.dart) and
[home_screen.dart](lib/presentation/home/home_screen.dart) must stay in
step with the script's.

## Keeping curriculum.md status in sync

[curriculum.md](curriculum.md) carries `✅` markers in §3 (sub-concepts) and §6 (widgets) plus rollup counts in its Status block. These are auto-managed by [tools/curriculum/sync_implementation_status.py](tools/curriculum/sync_implementation_status.py).

**Run it whenever you:**
- add or remove an entry in [lib/domain/questions/generator_registry.dart](lib/domain/questions/generator_registry.dart),
- add or remove a file under [lib/presentation/diagrams/](lib/presentation/diagrams/),
- add or remove anything under `assets/data/`.

```sh
python3 tools/curriculum/sync_implementation_status.py
```

The script is idempotent. It prints a summary (`+N added, -M removed`) and warns if it spots drift — e.g. a registry ID with no matching row in curriculum.md, or a new widget file not yet catalogued in §6 / not yet in the script's `WIDGET_TO_FILE` dict. Resolve any warnings, then commit the curriculum.md changes alongside the code change that caused them.

## Working incrementally

This is a hobby project being built in small sessions. Optimize for "next session can pick up easily":
- At end of session, update `plan.md` Status block (current phase, last action, next action).
- Check off completed phase tasks.
- If you discover something blocking, add it to "Open Questions" in `plan.md`.
- Prefer many small commits with clear messages over large ones.
- **Always push directly to `main` on GitHub.** Once a change is done and `flutter analyze` / `flutter test` pass, commit it and push it to `main` without asking — whatever its size or how many layers it touches. No feature branches, no PRs; the `main` history is fully linear and direct-push is the project's normal flow. The only exception is when the user explicitly asks for a PR or a review.
  - **In Claude Code on the web, `git push origin main` is blocked by the platform's GitHub proxy** (it restricts pushes to the current working branch for safety — see [docs](https://code.claude.com/docs/en/claude-code-on-the-web#github-proxy)). The proxy can't be turned off. Use the GitHub MCP API instead — it isn't proxy-restricted:
    - **Single file or small batch → `mcp__github__push_files`** (commits straight to `main`, no branch, no PR).
    - **Wants local `flutter analyze` / `flutter test` first → commit on the auto-assigned feature branch, then `mcp__github__merge_pull_request` with `merge_method: "rebase"`** (preserves linear history). PR creation via `mcp__github__create_pull_request` is a 1-call step.
  - In a local terminal session there's no proxy, so a plain `git push origin main` works fine — same policy, simpler mechanism.
  - **Gotcha:** `mcp__github__push_files` writes to the remote via GitHub's API; the local working tree never sees it. After pushing direct-to-`main` from a feature branch, your local repo will still show the file as "modified" against the feature branch HEAD, even though that content is now on `origin/main`. The Stop hook flags this as uncommitted changes. Clean it up with:
    ```sh
    git restore <file>           # local edit is already on origin/main
    git checkout main
    git pull --ff-only origin main
    ```

## What NOT to do

- Don't add ads, analytics SDKs, or tracking. The PRD is explicit: free, no ads, no monetization.
- Don't propose Firebase / Supabase / a custom backend for save data. We use platform cloud save (`games_services`).
- Don't add complexity for hypothetical future features.
- Don't write defensive code for impossible inputs in internal APIs.
- Don't create new top-level docs without discussion. `prd.md`, `plan.md`, `curriculum.md`, and this file are the canonical set.
