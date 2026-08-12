# Math City

A free, open, cross-platform math practice game for kids ages 6–14. No ads,
no tracking, no monetization.

Flutter + Flame, Riverpod 3 for state, Drift (SQLite) for local persistence,
platform cloud save via `games_services`.

## Documentation

Four canonical docs — read the one that matches what you're doing:

| doc | what it's for |
|---|---|
| [prd.md](prd.md) | product scope. Read before proposing a feature. |
| [plan.md](plan.md) | execution plan. **The Status block at the top is the source of truth for what's in scope right now.** |
| [curriculum.md](curriculum.md) | the K–8 sub-concept catalog, prereq DAG, and diagram needs. Read before touching questions. |
| [CLAUDE.md](CLAUDE.md) | conventions and architecture, for humans and AI agents alike. |

## Getting started

```sh
flutter pub get        # install deps
flutter run            # run on a connected device/simulator
flutter test           # run all tests
flutter analyze        # static analysis
dart format .          # format
```

## Architecture

Four layers, top to bottom:

1. **Presentation** (`lib/presentation/`) — Flutter widgets
2. **Game** (`lib/game/`) — Flame components
3. **Domain** (`lib/domain/`) — pure Dart rules, no Flutter/Flame imports. This is the testable core, and where the bias for unit tests lives.
4. **Data** (`lib/data/`) — Drift schema, repositories, cloud-save bridge

Question content is mostly *algorithmic*: 360 parameterized generators in
`lib/domain/questions/` paired with procedural diagram widgets in
`lib/presentation/diagrams/`, plus a small bundled dataset in `assets/data/`
that backs 33 concepts (4 of them dataset-only). **364 concepts are playable
in total** — the union, which is what any coverage tooling must count. There
are no runtime LLM calls.

## Auditing question quality

Because the questions are generated rather than authored, the way to find
content bugs is to *look at them*. The **`/ux-sweep`** skill does that at
scale: it plays a real question for each concept on the Android emulator,
screenshots it in both the multiple-choice and keypad interfaces, answers it
right (checking the green screen) and then wrong (capturing the red screen
and its explanation), and writes a reviewed report to
`ux_reports/<date>-<scope>-<band>/report.md`.

```
/ux-sweep 3.5           # one curriculum section
/ux-sweep fractions     # a category
/ux-sweep all           # the whole catalogue — ~27 min
```

It's driven by a `kDebugMode`-only HTTP control port in the app
([lib/services/debug_harness.dart](lib/services/debug_harness.dart)), so it
never navigates by tapping at screenshot coordinates and never has to guess
a question's answer. Flutter render errors are captured as data. The report
builder validates its own coverage and fails loudly if any concept went
unprobed or unreviewed.

Details: [.claude/skills/ux-sweep/SKILL.md](.claude/skills/ux-sweep/SKILL.md).

## Licensing

Every art/audio/font asset is CC0, CC-BY, or equivalent; every math dataset
is MIT / Apache 2.0 / CC-BY / CC0. `CC-BY-NC` and `CC-BY-NC-SA` are excluded
because app-store distribution carries non-zero commercial-use risk. Sources
are tracked in [LICENSES_THIRD_PARTY.md](LICENSES_THIRD_PARTY.md).
