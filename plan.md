# Math City — Implementation Plan

> Living document. Update as decisions are made and phases progress.
> Source of truth for product scope: [prd.md](prd.md).

---

## Status

- **Phase:** Phase 9 — City Builder: Rich Implementation & Graphics (in progress). Implementing the [city_builder.md](city_builder.md) catalog: **all 55 §3 buildings wired and sprite-backed** (added `gym` — services, 2×2, unlocked by `sports_field`, single variant) (71/73 beats — the 2 missing are the ratio-warning beats needing the §7 TriggerRule extension), `train_station` dropped (the rail can't be drawn coherently). Road-tile sprites done, non-square footprints fixed (#90), **land expansion shipped (device-verified)**, ✅-marker sync script live. **All sprites now affine-fit their footprints** — the original 16 dimension-mismatch flags are all cleared (15 by NB regeneration, `clinic` by re-footprinting 2×1); no squash placeholders remain. Phase 8 (the city_builder.md design doc) is complete. Phase 7's headless work is complete; the remaining device-verification sweep is owed — now doable on the local Android emulator (the web-sandbox no-emulator blocker no longer applies). Phase 6 left two deliberately-deferred sub-tracks: (a) selective DeepMind expansion (variety only, optional); (b) adaptive-system + mix-policy tuning (needs playtest data first). Live counts for the curriculum are in [curriculum.md](curriculum.md).
- **Last updated:** 2026-09-16
- **Next action:** **tune the coin prices by playtest** (PR #110 merged to `main` 2026-09-11) — the building table, land ladder (600 × ring), lifetime gates (1–4 h) and `expected_seconds.dart` are all first-draft numbers in one place each. Follow-ups noted while building it: (a) ~~the drip-feed still picks lowest-grade-first, so a grade-2 player's first unlock was `count_to_10` (K, auto-mastered at p = 0.95)~~ — **fixed 2026-09-16** (it was not harmless: it drained a grade-2+ player's wheel to zero; see *Wheel composition* below); (b) `AudioService` hooks for coin collection / band bonus are still stubs (prd.md lists both sounds); (c) emoji → sprite pass app-wide (Nano Banana batch) is separate. Phase 7's device-verification sweep is still owed; Phase 6's deferred sub-tracks stand.
- **Last action (2026-09-16, PR #111 merged + two follow-up commits on `main`):** **Wheel always 8, rotates every spin, mastered concepts come back as review.** Diagnosed with the real engine: the wheel was pinned at 4 because the starter pack was 4 and each mastery removed one concept and introduced exactly one (net zero), and for grade-2+ players every unlock went to a K concept that started auto-mastered (p = 0.95) → the wheel drained to 0 and the fallback pinned the 4 mastered starters forever. Spec agreed and implemented as *Wheel composition* below: new pure-domain [wheel_selection.dart](lib/domain/concepts/wheel_selection.dart) (tiers + slot rules + rotation), `DripFeedEngine.topUp` keeps 12 frontier concepts active, `pickNext` skips concepts that would start mastered, `startingProficiency` gives an introduced above-grade concept the challenging floor instead of a dead `notYet`, `AnswerReward.unlock` → `unlocks` list, `lastWheelProvider` remembers the last shown wheel. UI: "NEW" sticker on never-played segments, first-landing celebration overlay on the wheel (auto-advances in 2.4 s so the emulator flow never stalls), block summary shows a one-line "N new topics are on the wheel!" teaser with category-coloured placeholder badges (per-concept wheel icons are a later pass). `flutter analyze` clean, **862 tests pass** (+~25 new: tier/slot/rotation, top-up, auto-mastered skip, review slots, rotation against the last wheel). **Device-verified on the emulator** (fresh grade-3 player): 8 segments from the first spin, every unplayed segment stickered NEW, first-landing celebration → 4-question block → summary → "Spin again" gave a wheel with 4 of 8 segments swapped and the played concept's sticker gone. *Not* seen live: the summary's new-topics teaser (needs a mastery; the deterministic fling wouldn't land the same concept twice, so it is unit-tested only).
- **Prior action (2026-09-08..11, PR #110, merged):** **Single-currency coin economy shipped end-to-end** — the spec below implemented as specified, plus the band-crossing coin bonus (2 × expectedSeconds, once per concept per threshold, reusing `ConceptBandMilestones`; replaces the old +1 🔬). New pure-domain `lib/domain/economy/` (expected_seconds for all 366 concepts, coin_economy tunables + rules, band_crossings, question_block); schema **v14** (coin columns + `streakCount`, research + `BuildingTypesResearched` dropped, wipe-and-recreate); research flow deleted everywhere (catalog = every building whose rule passes, bought on placement); all 55 buildings, the land ladder and lifetime gates re-denominated in minutes of study (city_builder.md §3/§3.5 updated, table in the PR); question blocks (spin → N questions → coin flight into the AppBar counter → red screen mid-block → `BlockSummaryScreen` → wheel), with a bigger in-place celebration + second flight for band crossings; wheel retirement (≥2 grades below + comfortable); `CoinIcon`/`CoinAmount` CustomPainter replacing every 🧱/🔬. `DebugHarness` / `ConceptDebugScreen` keep single-question semantics so `/ux-sweep` is unchanged. `flutter analyze` clean, **841 tests pass** (+~60 new: reward/streak/block/bonus/coverage/retirement/catalog/coin-reward). **Device-verified on the emulator** — [ux_reports/2026-09-09-coins-economy/report.md](ux_reports/2026-09-09-coins-economy/report.md): spin → 4-question block → coin flight → wrong-answer red screen mid-block → summary (coins, streak, "Mastered!" bonus, unlock) → wheel; bonus burst captured live; single home bought instantly for 60 coins after reading its demand; home card / city bar / debug sheet all coins-only. `/ux-sweep 3.3` smoke on the final build proves the harness still works: [ux_reports/2026-09-09-3.3-both](ux_reports/2026-09-09-3.3-both/report.md) → 30 probed/reviewed, 16 clean, 14 could-improve, 0 bugs. The improves are all explanation-wording / diagram notes on content this branch doesn't touch (10 of the 14 were rated clean by the 2026-09-05 reviewer — stricter reviewer, not regressions), `build_report.py` exit 0. One-off Riverpod debug assertion on `activeCityProvider` during the first `/open` after a long manual session, not reproducible — filed as a GitHub issue. Retirement was verified by unit test only (a fresh profile's outgrown concepts start mastered, so they never reach the wheel to begin with).
  - **The spec as implemented (agreed 2026-09-08):**
    - **Earning.** A correct answer pays `round(expectedSeconds(concept) × formatMult × 0.2 × streakCount)`, min 1 coin. `formatMult` = 1.0 for multiple choice, **1.5 for keypad** (free-form genuinely takes longer). A wrong answer pays nothing and resets `streakCount` to 0; each correct answer increments it, capped at **5** (so pay ramps 0.2 → 1.0 over five consecutive corrects, chess.com-puzzle style). The streak is **global per player and persists across sessions** (Drift column). Fresh profiles start at level 0 — the opening ramp doubles as a tutorial. **Delete `bricksForBand` and the "bands below comfortable earn 0" rule entirely** — the band's only remaining job is choosing MC vs keypad. No speed floor, no consolation pay: a determined MC guess-spammer roughly matches honest earnings and learns nothing; accepted.
    - **`expectedSeconds` per concept.** New pure-domain map `conceptId → int` (own file, not 364 constructor edits) with a coverage test. Estimate by hand per concept — a grade-band formula as the starting draft (K–1 ≈ 5s, G2–3 ≈ 10s, G4–5 ≈ 20s, G6–8 ≈ 35s), then walk every concept and adjust the outliers individually (long division, multi-digit algorithms, multi-step word problems run 2–3×). These are guesses to be tuned later; never reward *actual* time taken (idling would farm).
    - **Question blocks.** A wheel spin now yields `ceil(25s / expectedSeconds)` questions of that concept, clamped to [1, 6] — five quick K questions or one long-division problem per spin. Correct → **no green screen**: counter-only payout animation (revised 2026-09-18: nothing appears at the answer; the AppBar coin counter flashes bright and grow-settles as it changes to the new balance, then a 600 ms beat), straight to the next question. Wrong → the red explanation screen **stays** (it's the teaching moment) and counts as one of the block's questions. Block ends on a **summary screen** (coins earned, streak state, any drip-feed unlocks that fired mid-block — this replaces the green screen's unlock-announcement job) → back to the wheel. Keep `DebugHarness` single-question semantics intact (debug/ux-sweep path bypasses blocks) or the sweep goes blind.
    - **Wheel filter.** Retire a concept from the wheel once it is **≥2 grades below the player's grade AND at the comfortable band** — mastered baby-steps disappear, shaky old material still resurfaces.
    - **Research is deleted.** Drop `researchBalance`, the `BuildingTypesResearched` table, `researchCost`, the research UI flow, and the 🔬 display everywhere; reword the story beats that prompt researching. A building whose unlock rule is met is **immediately buyable** with coins. `minLifetimeBricks` gates become `minLifetimeCoins` — now literally "total seconds studied," reprice accordingly.
    - **Repricing.** Re-denominate all 55 building costs, the land ladder (60/150/300), and lifetime gates (300–1000) in minutes-of-study (draft: starter ≈ 1–2 min, median ≈ 10 min, landmark ≈ 1–2 h; propose a full table for user tuning). Update city_builder.md's §3 cost columns to match.
    - **Coin art.** No emoji (platform-inconsistent, and "coins" collides with the money-curriculum's realistic US coins). Paint the game coin with a `CustomPainter` (gold, star-stamped, deliberately un-currency-like), like the Money diagram widget paints its coins. Longer-term the user wants emoji replaced by sprites app-wide (Nano Banana pipeline) — separate batch, not this rework.
    - **Mechanics.** Schema **v14** (pre-launch wipe per precedent), `brickBalance → coinBalance`, `lifetimeBricksEarned → lifetimeCoinsEarned`, + `streakCount`. Multi-layer + schema migration → build on a branch and land as a **PR** per CLAUDE.md. Unit-test the reward function, streak transitions, block sizing, and the wheel filter in the domain layer.
- **Last action (2026-08-30..09-06):** **UX-sweep follow-up remediation — all 77 could-improve rows from the 2026-08-19 baseline worked through, verified by a fresh full sweep: [ux_reports/2026-09-05-all-both](ux_reports/2026-09-05-all-both/report.md) → 364 probed/reviewed, 317 clean, 47 could-improve, 0 bugs.** Seven themes, each its own commit(s) on `main`: (1) **Question layout** — diagram and prompt card now lay out sequentially via a `MultiChildLayoutDelegate` (diagram natural height capped at 45%, card gets the true remainder and scrolls only on real overflow; with a diagram the card steps down to the smaller font at >90 chars). This went through two iterations: the first (fixed 45%/240px reservation) fixed the crushed-diagram specks but clipped cards under short diagrams — the verification sweep caught that as 3 of its 4 bugs, all fixed and re-probed clean. Plus: base-ten blocks 13px cells/darker fill, double-number-line 14px labels, dot-plot stacks keep a visible gap, bar-chart category labels wrap to two lines. (2) **Counting prompts** show two leading terms ("8, 9, ___") so direction is in the sequence. (3) **Explanations teach** instead of restating across ~25 generators (inverse ops for missing addend/factor, rounding digit rule, worked money sums, full linear-eq walkthrough, place-value comparison hints, named groups/objects, protractor wrong-scale warning…). (4) **Impossible choices removed** — binary questions get binary choices (repeating-decimal, function-check, shape-hierarchy), `describe_distribution` drops 'Symmetric' when uniform, compare_3digit is pair-only MC. (5) **Content fixes**: protractor no longer prints its answer; `fraction_a_over_b` uses the `___/d` blank-numerator template; `equivalent_fractions_visual` shows the refined partition (`FractionBarSpec.subdivideAll`); equal-groups/sharing grids separate rows (`AreaGridSpec.separateRows`); positional scenes draw emoji objects (with the `inside` case keeping the bordered container as the box — the fourth sweep bug); am/pm hours match their context; order-of-operations always samples the precedence-trap ordering; coordinate points stay off plot edges; NBSP in line-plot mixed numbers; concept renames ("How many solutions?", "Parentheses first"); scatter-construct distractors come from the listed pairs; realistic measurement values; + ~10 more. **Real bug found on the way: comma-formatted canonical answers ("100,000") were unanswerable in keypad mode** (no comma key, parser didn't strip) — `answer_check` now strips separators. (6) **Bundled datasets refreshed** via new deterministic [tools/question_generation/refresh_bundled_datasets.py](tools/question_generation/refresh_bundled_datasets.py) (idempotent; re-run after any re-ingestion): strategy explanations for all 12 add/sub buckets (counting on/back, make-ten/take-from-ten, carry/borrow columns, place-value expansion, counting-up), '×' in every mult prompt, `mult_1digit_by_multiple_of_10` drops its 15 ×1 items and gets real distractors + the ×10 strategy, rounding files get the digit rule (multidigit also commas + multiple-of-factor distractors), `function_evaluate_at_point` gets substitution arithmetic. (7) **Dataset versioning (schema v13)** — the seeder fingerprints the bundled JSONs (FNV-1a, one pass shared with the parse) and drops-and-reseeds `dataset_questions` on mismatch, so dataset fixes now reach existing installs without schema bumps; `AppSettings.datasetFingerprint` stores the stamp, checked once per session. Deliberately NOT done: no transversal/L-shape diagram widgets (parallel_lines_transversal stays text-only — top remaining improve), no real nesting for nested_grouping (renamed instead), plot_four_quadrants label-overlap between near-miss points kept (the near-misses are the pedagogy). `flutter analyze` clean, **810 tests pass** (answer-check commas, fingerprint re-seed, blank-numerator + binary-choice contracts).
- **Toolchain in the web sandbox:** The repo ships a `SessionStart` hook ([.claude/hooks/session-start.sh](.claude/hooks/session-start.sh)) that installs **Flutter 3.41.7** (same pin as CI) and runs `flutter pub get` automatically at the start of every Claude-Code-on-the-web session. **`flutter`, `dart`, `flutter analyze`, and `flutter test` are available** — always verify changes locally before committing; don't push code unseen and "rely on CI" as a substitute. The hook runs in async mode, so on a cold start there's a ~1–2 minute window where Flutter is still downloading; if a `flutter` command fails immediately at session start, wait a moment and retry once. A `PostToolUse` hook on `Write|Edit` ([.claude/settings.json](.claude/settings.json)) auto-runs `dart format` on any `.dart` file Claude touches, so the CI format step can't be tripped by drift.
- **Prior action (2026-08-18..29):** **UX-sweep remediation executed end-to-end — all 58 baseline bugs fixed, verified by a fresh full sweep: [ux_reports/2026-08-19-all-both](ux_reports/2026-08-19-all-both/report.md) → 364 probed/reviewed, 287 clean, 77 could-improve, 0 bugs.** Work landed as ~20 small commits on `main`, cluster by cluster per the baseline report's §7: (1) prompt-card layout — with a diagram the card is never flexed and the diagram FittedBox-shrinks into the remainder; without one, long word problems step down a text size and scroll (fixed ~30 clipped/invisible-prompt bugs). (2) Value-based grading — integer answers compare by parsed value (`+18`≡`18`, typeset minus accepted by all parsers); probability concepts dropped `exactString`; `equivalent_fractions_compute` and `fraction_denom_10_100` ask for the bare numerator their blank points at. (3) Label thinning in NumberLine (whole-number-only, collision-stepped), DotPlot (thinned + dot radius scales), Protractor (5° ticks, 20° labels, 300px). (4) MC forced on list-dependent concepts (compare_* families incl. decimals with genuine ties now possible, read-numerals family, dataset closest_to_target/kth_value_in_list); keypad symbol keys now derive from the union of all four choices so the pad never leaks sign/fraction-ness. (5) Also-correct/duplicate distractors killed (classify_quadrilaterals asks the MOST specific name; array_repeated_addition asks what adds up the rows; ordered coin-flip phrasing; dedup in two-step inequality). (6) Content/template fixes (per-pair conversion verbs, per-theme chart prompts, exterior-angle `?` on the exterior wedge, Box3D no longer clips its back corner, positional scenes stopped stating the answer). (7) Observations §1–§6: gapped-sequence prompts (`16, 18, ___, 22`), stacked property-of-operations with plain-English titles, fraction-division diagrams that show the operation (FractionBarSpec subdivideShaded/bars), metric alongside imperial in the nine imperial-only concepts. Transformations no longer pre-draw their answer image; congruence/similarity grids fit both figures; ScatterPlot gained an independent y-scale (50-unit ranges were four screens tall); charts stopped ellipsising titles; coins print their name instead of their value. **Dataset repair:** `kth_value_in_list` had 57 mathematically wrong answers (ingestion kept DeepMind's answer but sampled fresh distractors) and 24 unanswerable fifth/sixth/seventh-of-four items — answers recomputed from each item's own choices, bad items dropped. `flutter analyze` clean, 808 tests pass (16 new).
- **Prior action (2026-08-13):** **First `/ux-sweep all` triage — the ten Addition & Subtraction findings fixed (report: [ux_reports/2026-08-13-all-both](ux_reports/2026-08-13-all-both/report.md)).** Three threads. (1) **Multi-digit ± is now set out in stacked columns.** New [column_form.dart](lib/domain/questions/column_form.dart) rewrites a bare `358 + 274 = ?` into a `ColumnArithmeticSpec` diagram with the result left blank and the prompt shrunk to `Add.` / `Subtract.` — lining the place values up is half the work of the standard algorithm, and inline notation makes the kid do it in their head. `ColumnArithmeticSpec.result` went nullable to carry the question form (blank under the rule, worksheet-style); the widget renders it larger than the explanation form. Applied to `add_up_to_4_2digit`, `add_within_1000`, `sub_within_1000`, `add_multidigit_standard_alg`, `sub_multidigit_standard_alg`; the last four also gained a filled-in column on the wrong-answer screen, and `add_up_to_4_2digit` an explanation that walks the running total instead of restating the chain. The two 1000-level concepts are half dataset-sourced, so `QuestionSource` runs bundled items through the same transform (`columnFormConcepts`) — a kid shouldn't get a different layout depending on which side of the mix served the question. (2) **Bundled add/sub prompts re-canonicalised to `43 − 7 = ?`.** DeepMind phrases the same sum a dozen ways ("Work out 60 + 4.", "What is the distance between 55 and 6?") — reading load without maths, vocabulary a G2 reader hasn't met, and unlike the algorithmic items in the same concept. `ingest_deepmind_arithmetic.py` now rebuilds the equation from the oriented operands it already recovered, and dedups on that rather than on DeepMind's wording (12 files, 1083→1064 items). Schema **v12** drops and re-seeds `dataset_questions`, which is only a cache of the asset files. A new guard test walks every bundled add/sub item, not just the one a sweep samples. (3) **Three G1 prompts split onto two lines** — `equal_sign_meaning` (also cut to True/False; "Cannot tell" and "It's missing a number" were never live options), `commutative_add`, `associative_add`. Verified on the emulator with a targeted `uxctl probe` — no render errors, screenshots reviewed. Filed #107 for a sketch layer so kids can write carry digits on the column the way they would on paper.
- **Prior action (2026-08-12, later):** **UX-sweep harness + `/ux-sweep` skill — walk every implemented concept on the emulator and produce a dated screenshot report.** Motivation: reviewing all 360 implemented concepts by tap-and-screenshot would cost ~7 screenshots each (~2,500 total) and would force the reviewing agent to *solve* each question from pixels — which manufactures false bug reports whenever it gets the maths wrong. Instead: (1) new kDebugMode-only HTTP control port [debug_harness.dart](lib/services/debug_harness.dart) on `127.0.0.1:8081` (debug AndroidManifest already grants INTERNET; never started in release) exposing `/ping` `/concepts` `/open` `/answer` `/back`. `/open` resets the navigator and pushes a question, returning the prompt, the displayed choice order, `correctAnswer`, the diagram spec type, and any `FlutterError`s raised while it rendered — so overflow/build exceptions come back as *data* rather than needing to be eyeballed. `MaterialApp` gained a `navigatorKey`; `HomeScreen.initState` calls `markHomeReady()` so a pushed question can't be clobbered by the splash screen's `pushReplacement`. (2) `QuestionScreen` gained an optional **`seed`** — one `Random(seed)` drives both `source.generate` and the choice shuffle, so the same seed replays the identical screen; that's what lets the sweep show one question answered right *and* wrong. Keypad-eligibility logic hoisted out of `build` into `_keypadEligible` (behaviour-preserving) so the harness can report the input mode. (3) [uxctl.py](tools/ux_sweep/uxctl.py) drives the port over `adb forward`: one subprocess call probes a concept end-to-end and prints one JSON line. **Defaults to `--band both`**: the question screen is captured in *both* MC and keypad (different answer areas; the pad's extra-chars row is answer-derived), but the **red screen only once** — the band never reaches `ResultScreen` (same seed → same question → same distractor, and debug mode zeroes bricks/unlock), verified on device where only the status-bar clock differed. Concepts that force MC (`multipleChoiceOnly` or a text-shaped format) are detected via the returned `inputMode` and skip the duplicate keypad shot. **4.4 s and ≤3 screenshots per concept**; a full 360-concept both-band pass is ~27 min and ~60 MB of PNGs. Scope terms accept `all`, a section number (`3.3`), a category id, a name substring, or a bare concept id. `--resume` makes it restartable. (4) [build_report.py](tools/ux_sweep/build_report.py) joins `probe.jsonl` with per-batch `notes/*.jsonl` into `report.md` — findings table first, then per-category tables in curriculum.md order; idempotent, so partial reports are readable. **Coverage is gated**: it exits `2` and prints the missing ids if any probed concept has no note (a reviewer subagent that dies partway or silently drops ids is otherwise invisible), `--list-unreviewed` emits them for a follow-up batch, and the report carries a `> [!WARNING] This report is incomplete` banner until the gap closes. Six checks in all: scope-vs-probed (via a `scope.json` manifest written before probing — `probe.jsonl` alone always looks complete, so a probe pass that dies halfway is otherwise invisible), probed-vs-reviewed, notes referencing unknown ids, invalid verdicts, `bug`/`improve` notes with no text, and referenced screenshots missing from disk. **Coverage bug caught by this: `/concepts` was listing `GeneratorRegistry.implementedConceptIds` (360) instead of `QuestionSource.implementedConceptIds` (364, the registry ∪ dataset union the app actually plays from)** — `closest_to_target`, `function_evaluate_at_point`, `kth_value_in_list` and `sort_rationals` are dataset-only and would have been silently absent from every sweep. The harness now reaches the `ProviderContainer` via `ProviderScope.containerOf(navigatorKey.currentContext)` and reports each concept's `datasetPool` size so reviewers know when one probe isn't representative. (5) **Docs**: [README.md](README.md) rewritten from Flutter boilerplate into a real entry point (doc map, architecture, how to audit question quality); [CLAUDE.md](CLAUDE.md) gained a "Finding UX bugs in question content" section (and its stale "Phase 0 skeleton not yet created" note above the command list was removed); [curriculum.md](curriculum.md) Status block now points at the sweep from beside the ✅ counts, since counts prove a generator *exists*, not that its question reads well. (5) [.claude/skills/ux-sweep/SKILL.md](.claude/skills/ux-sweep/SKILL.md) drives it: one serial probe pass (no images, no emulator contention), then parallel review subagents that only read files from disk. Reports land in `ux_reports/<date>-<scope>-<band>/` (committed; ~70 MB of PNGs for a full sweep, `--max-dim` tunes it). **Two real bugs found while validating the harness itself:** (a) *fixed* — `QuestionScreen.dispose` and `ResultScreen.dispose` both called `ref.read(ttsServiceProvider)` after deactivation, which Riverpod 3 throws on, so **TTS never stopped when leaving a question**; both now cache the `TtsService` in `initState`. (b) *filed as [#106](https://github.com/quarup/math_city/issues/106)* — `number_line.dart`'s `_formatValue` rounds every non-integer tick to 1 dp, so `fraction_on_number_line` shows decimal ticks (0, 0.3, 0.7, 1) on a question answered `1/3`, and `decimal_on_number_line` at 20 divisions renders *duplicate* labels (0.1, 0.1, 0.2, 0.2 …) while expecting a 2-dp answer that appears nowhere on the line. `flutter analyze` clean, **780 tests pass**, both bands device-verified on the emulator.
- **Prior action (2026-08-12, earlier):** **Math-notation rendering fixed — real superscript exponents + drawn radicals (issues #98–#102).** Two-part mechanism, chosen over full math-markup prompts (which would have forced a schema change through `GeneratedQuestion`, the answer checker, and every render site): (1) new pure-domain `sup()` helper in [superscripts.dart](lib/domain/questions/superscripts.dart) renders every exponent as Unicode superscripts (`10^5` → `10⁵`, symbolic `aᵐ⁺ⁿ` too) across prompts/choices/explanations in `powers_of_10`, `exponents_whole_number`, `order_of_operations_with_exp`, `scientific_notation_read/write/ops`, `integer_exponent_props` — settling the codebase on the style `pythagorean_apply_3d` already used (safe because string-format answers always force MC, so superscripts are never typed); (2) new [MathText](lib/presentation/widgets/math_text.dart) widget — a drop-in `Text` replacement used by the prompt card, MC choice buttons, and result-screen explanation/nudge texts — parses `√16` / `∛27` / `√(l² + w² + h²)` out of the plain prompt strings (domain stays string-typed and pure) and paints the radical with a `CustomPainter`: hook, vinculum joined to it and spanning the radicand, small index 3 tucked in for cube roots. `flutter analyze` clean, **780 tests pass** (11 new: `sup()` + `parseMathSegments`); all six cases device-verified on the emulator (√49 prompt + explanation, ∛64, 5⁵ × 5² with superscript choices, aᵐ × aⁿ = aᵐ⁺ⁿ, √(1² + 4² + 8²)). Opened as a PR (touches domain + presentation).
- **Prior action (2026-08-05, branch `infinite-land-blocks`):** **Land buying reworked to match building placement — select-then-confirm, no modal.** Tapping a pale frontier block no longer pops an `AlertDialog`; it **selects** the block, washing its 16 tiles yellow (new `buyingTiles` set on [city_board_component.dart](lib/game/city/city_board_component.dart) + `setBuyingTiles` on [iso_city_game.dart](lib/game/city/iso_city_game.dart), same tint as a picked-up building) and swapping the bottom catalog for a non-modal `_BuyLandBar` in [city_screen.dart](lib/presentation/city/city_screen.dart). Because the bar isn't a dialog, the city stays visible and tappable — the player can move the selection to a different block, or tap owned land / re-tap the block / Cancel to drop it, before confirming. **Affordability no longer blocks selection:** a player who can't pay still gets the highlight, and the bar reads "This land costs 🧱 80 — earn 🧱 71 more to buy it!" with Buy disabled (previously a toast refused the tap outright). Kid-facing copy de-jargoned: "Spend 🧱 N to claim a new 4×4 block" → "Buy this land for 🧱 N?". `flutter analyze` clean, **761 tests pass**. **Device-verified on the emulator:** select → move selection to another block → Buy (525→445 🧱, block turns owned grass) → and the 9-🧱 player's can't-afford path. No domain or schema change; new logic is presentational state only, so no new tests (`blockCost` / `purchasableBlocks` were already covered).
- **Prior action (2026-06-21, later):** **City UX follow-ups — road rendering, debug-sheet dismissal, player-card overflow.** (1) **Fewer crossroads in open gaps:** a 2-wide road band (the strip paved between two building rows two tiles apart) used to autotile into a ladder of tee/cross junctions. New pure-domain `roadSpriteAt` in [road_sprites.dart](lib/domain/city/road_sprites.dart) applies *parallel-lane suppression* — it drops the seam link to a neighbouring parallel through-lane so the band renders as separate parallel straight roads, while leaving genuine single-road crosses/tees intact (a connection is dropped only when the perpendicular neighbour is itself a through-lane in this tile's orientation). Purely a rendering change — the road *set* and connectivity are untouched, so "trees between adjacent lanes" stays a future option. [city_board_component.dart](lib/game/city/city_board_component.dart) `_drawRoadTile` now calls `roadSpriteAt` instead of `roadSpriteFor`. **Follow-up (2026-06-24):** the first cut had a non-symmetric-seam bug — it treated a *junction* tile (through in both axes, e.g. a crossroads or where a side street meets the band) as a parallel lane and dropped the seam on one side only, leaving a road arm jutting into a curb (visible stair-step). Fixed by suppressing only between **pure lanes** (through in exactly one axis); junctions stay fully connected and the seam test is symmetric (reads identically from either tile). +3 junction-case tests. **Known-remaining:** a 2-wide band that just *ends* still caps with curves (a small U-turn look) — fixing that needs road-*generation* changes, deferred. (2) **Debug bottom sheet dismissible again:** the scroll-controlled sheet grew to ~full height (no scrim, body-drag scrolled instead of dismissing) → capped at 85% screen height in [city_screen.dart](lib/presentation/city/city_screen.dart). (3) **Player-card overflow:** the fixed-width picker card overflowed once a balance got large (🧱 1322 …) → the 🧱/🔬 row wrapped in `FittedBox(scaleDown)` in [home_screen.dart](lib/presentation/home/home_screen.dart). `flutter analyze` clean, **746 tests pass** (+5 `roadSpriteAt` cases). All device-verified on the emulator and pushed to `main`.
- **Prior action (2026-06-21, earlier):** **City placement UX revamp — tap-to-select, auto-fit footprint, yellow-tint selection (no more move-mode FAB).** Reworked building placement around a single mobile-friendly interaction. (1) **Tap-to-select:** tapping any placed building (anywhere on its real footprint, not just the anchor tile) picks it up for repositioning; tapping it again — or **Done** — drops it. The separate move-mode FAB is gone; while a building is held the bottom catalog swaps for a Done bar. (2) **Auto-placement after buying:** buying + placing leaves the just-placed building selected so it can be nudged on a small screen — `AppDatabase.placeBuilding` / `CityActions.placeBuilding` now return the new placement id for this. (3) **Auto-fit footprint:** new pure-domain `resolvePlacement` in [placement_rules.dart](lib/domain/city/placement_rules.dart) slides a footprint's anchor so the footprint *covers the tapped tile* (preferring the smallest slide), so a multi-tile building lands on the area under the tap even when its anchor corner has to move; returns null when the tap is occupied / out of bounds / no legal covering spot exists. [city_screen.dart](lib/presentation/city/city_screen.dart) routes both place and move through it (move excludes the mover's own tiles). (4) **Yellow-tint selection** replaces the old highlight (which drew a single lifted 1×1 diamond *north* of multi-tile buildings — bug fixed): selected buildings render with a yellow wash (sprite `srcATop` ColorFilter; box-placeholder faces lerped toward yellow) in [city_board_component.dart](lib/game/city/city_board_component.dart); `setHighlight`/`highlightTile` plumbing removed from [iso_city_game.dart](lib/game/city/iso_city_game.dart). A per-tile footprint outline was added then dropped as redundant/confusing — tint alone. `flutter analyze` clean, **741 tests pass** (+7 `resolvePlacement` cases). Pushed to `main`. Final tint-only state not yet device-screenshotted (emulator session was mid-verify; user eyeballed and approved).
- **Prior action (2026-06-14):** **Phase-9 catalog completed — the remaining 22 building types wired + all 54 art-backed, `train_station` dropped, and the sprite pipeline gained flip + affine geometry correction with a wrong-dimensions error report.** (1) **Sprite pipeline upgrades ([process.py](tools/sprite_pipeline/process.py)):** (a) **horizontal-flip auto-detect** — NB frequently returns a transposed footprint (a 3×2 drawn as 2×3); a left-right mirror swaps the dimetric ground axes, fixing it (caught sports_field, mid_rise_apartment, playground_v2). (b) **Vertical-preserving affine ground-fit** — replaces the squash-only fit: detects the drawn ground plate's W/S/E tips and warps them onto the footprint diamond, correcting ratio *and* projection angle. The horizontal map is a pure scale pinned to the W/E tips (no x-shear → vertical walls stay vertical, no lean); the vertical map hits all three corner heights exactly. The warp is **supersampled** (run at ~source resolution, then LANCZOS-downscaled) because PIL's affine has no area filter and aliases when downscaling — output is now crisp. (c) **Sidewalk gap fill** — the transparent wedges between the building base and its footprint diamond are filled with the same NB-quilted sidewalk texture the road tiles use (imported from [compose_roads.py](tools/sprite_pipeline/compose_roads.py), sampled in screen space, building AA edge composited over it), so buildings sit on a paved apron that blends with roads instead of the old nearest-pixel smear (graceful fallback to the bleed if the style ref is missing). (d) **Wrong-dimensions error report** — when a clean ground plate is detected but its proportions disagree with the §3 footprint (anisotropy > 1.4), the sprite is *listed for regeneration in NB* rather than silently distorted; falls back to squash for unreliable tips (tall/foliage) and emits a squash placeholder so the build still has art. Manual `--flip/--no-flip` + `--affine/--no-affine` overrides added. Deps now run from a py3.9 venv at `tools/sprite_pipeline/.venv` (py3.14 has no rembg wheels). (2) **All sprites (new + previously-committed) reprocessed with the final pipeline** for consistency — flips re-oriented `duplex_v1`/`post_office_v2`/`school_v1`/`school_v2`/`townhouse_row_v2`; **16 sprites across 11 types are flagged for regeneration** (drawn proportions don't match the §3 footprint): commercial `clothing_store`/`grocery`/`movie_theater`/`restaurant`(v1,v2)/`supermarket`/`toy_store`, plus `clinic`(v1,v2)/`duplex`(v3,v4)/`post_office`(v1,v2)/`recycling_center`/`townhouse_row`(v1,v3). All ship squash+sidewalk placeholders meanwhile. (`bakery` was regenerated mid-session and now fits.) (3) **22 new building types wired** in [building_registry.dart](lib/domain/city/building_registry.dart) + 22 demand beats + `praise_zoo` in [beat_registry.dart](lib/domain/city/beat_registry.dart): services (`high_school`, `fire_station`, `police_station`, `bus_depot`), commercial (`market_stall`, `supermarket`, `bakery`, `restaurant`, `farmers_market`, `bookshop`, `toy_store`, `clothing_store`, `office_building`, `shopping_mall`, `business_tower`), entertainment (`playground`, `community_garden`, `fountain_plaza`, `botanical_garden`, `swimming_pool`, `movie_theater`, `zoo`); plus `numVariants` set on the 6 previously-artless wired types (`grocery` footprint also corrected 1×1→1×2 per §3, `park`, `mid_rise_apartment`, `sports_field`, `museum`, `stadium`). (4) **`train_station` removed** from city_builder.md (§3.2 / §4.1 / §5.2 / §5.4 + all rollup counts: 55→54 anchors, 14 services, ~73 beats, 96 sprites, ≈117 🔬) and from generate_prompts.py `VARIANT_COUNTS` + regenerated prompts.txt (54 prompts). (5) Sync script applied +45 ✅ markers → **54/54 buildings wired, all sprite-backed; 71/73 beats**. `flutter analyze` clean, **734 tests pass** (updated the building-registry numVariants test — every type is now art-backed). Not yet device-verified (owed once the 8 flagged sprites are regenerated). Not yet committed.
- **Prior action (2026-06-12, late session):** **Phase-9 triple: six more building types got art (three newly wired), the §6 ✅-sync script is live, and land expansion shipped (device-verified).** (1) **Art batch:** processed the 9 remaining committed raws through [process.py](tools/sprite_pipeline/process.py) — `clinic`×2 / `school`×2 / `waste_management`×2 (Phase-7 types, now sprite-backed, registry footprints set from §3: 2×2 / 2×3 / 2×2 — clinic's §3 row bumped 1×2→2×2 because both raws are drawn on a square lot) plus `hospital` / `recycling_center` / `water_treatment` (new registry entries + 5 demand/praise beats per §3/§4) → **32/55 buildings wired, 48/74 beats, 26 with processed art**. process.py gained a **despeckle pass** (scipy connected components; drops disconnected opaque islands < 3% of the largest): hospital_v1's noisy backdrop left not-green-enough flecks that the non-green protection force-kept, which also skewed its bbox crop and ground-tip detection (measured 2.21:1 pre-fix, 1.73:1 after). water_treatment is drawn near-top-down (1.36:1, outside the trusted range) → processed with an explicit `--squash=0.68`. All 9 debug overlays QA'd against their footprint quads. (2) **[tools/city_builder/sync_implementation_status.py](tools/city_builder/sync_implementation_status.py) stood up** (mirrors the curriculum one): toggles leading ✅ on §3.1–§3.4 / §4.x rows from `building_registry.dart` / `beat_registry.dart`, rewrites §6 as an auto-managed `IMPL_STATUS` fenced block (wired counts + which wired buildings still render the box placeholder), and warns on ID drift, `numVariants`-vs-on-disk mismatches, and orphan sprites. Idempotent; first sync applied 80 markers. `ID_RE` in process.py / generate_prompts.py now tolerates the leading ✅. (3) **Land expansion shipped:** pure-domain offer policy in [land_expansion.dart](lib/domain/city/land_expansion.dart) (+2 tiles per side per purchase → 12→16→20→24 cap, 🧱 60/150/300 price ladder, per-axis cap handling), transactional `AppDatabase.expandCityLand` (grow grid + shift every placement so the old land stays centered + spend 🧱), `CityActions.expandLand`, and a city-screen FAB (zoom-out-map icon, hidden at the cap and in move mode) with a confirm dialog; [city_screen.dart](lib/presentation/city/city_screen.dart) rebuilds the Flame game when the grid size changes so the camera re-centers on the bigger board. **Device-verified.** (4) **City debug sheet made scrollable** — the force-fire chip list (now 48 beats) overflowed the fixed Column by 634 px. `flutter analyze` clean, **733 tests pass** (new: offer-policy unit tests + expandCityLand DB-transaction tests). All pushed to `main`.
- **Prior action (2026-06-12, earlier):** **Phase-9 building rollout — 19 more building types wired, non-square footprints fixed (#90 closed), permissions moved out of git.** [building_registry.dart](lib/domain/city/building_registry.dart) + [beat_registry.dart](lib/domain/city/beat_registry.dart) grew **10→29 building types** (added `town_hall`, `city_hall`, `library`, `post_office`, `duplex`, `townhouse_row`, `mid_rise_apartment`, `high_rise`, `luxury_condo`, `farmhouse`, `power_station`, `solar_farm`, `water_tower`, `sports_field`, `museum`, `stadium`, `aquarium`, `amusement_park`, `observation_tower`), each with demand beats / footprints / variant counts; processed art shipped for most — the 4 artless ones (`mid_rise_apartment`, `sports_field`, `museum`, `stadium`) render the box placeholder until their sprites land. **#90 fixed:** non-square footprints now render as the true iso parallelogram in both the pipeline ([process.py](tools/sprite_pipeline/process.py) inverse-projects pixels into footprint tile space for the gap-fill mask + draws the real footprint quad; adds `footprint_override`/`squash_override`) and the renderer ([city_board_component.dart](lib/game/city/city_board_component.dart) anchors the sprite at `Anchor(w/(w+h), 1)` + draws the box placeholder over the full quad). **Permissions out of git:** [.claude/settings.json](.claude/settings.json) is now hooks-only; personal allow/ask rules live in the gitignored `.claude/settings.local.json`. `flutter analyze` clean, **725 tests pass**, all pushed to `main`. **Also (same day): Phase-9 road-tile art shipped (device-verified).** Per [city_builder.md §5.5](city_builder.md): new build-time compositor [compose_roads.py](tools/sprite_pipeline/compose_roads.py) — geometry analytically rendered (SDFs in top-down meter space, exact edge-midpoint crossings, tile-periodic dashes, 0.4 m overscan rim against grass-sliver seams), surface textures quilted from a single NB reference tile ([raw_sheets/road_style_ref.jpeg](tools/sprite_pipeline/raw_sheets/road_style_ref.jpeg)) — emits 6 game-ready `assets/buildings/road_<shape>.png` directly (no process.py). Pure-domain autotiling resolver `roadSpriteFor` in [road_sprites.dart](lib/domain/city/road_sprites.dart) (16 masks → 6 sprites × H/V flips; flip-algebra round-trip test); [city_board_component.dart](lib/game/city/city_board_component.dart) draws roads as sprites after the terrain pass (grey fill now only the async-load fallback); [iso_city_game.dart](lib/game/city/iso_city_game.dart) preloads the 6 sprites on first `setRoads`. Both NB-direct tile generation and pure-procedural fills were tried and rejected first-hand (full log in §5.5). `flutter analyze` clean, 723 tests pass. *(Earlier same-arc work below.)* **Prior:** **Phase-9 art-pipeline pilot executed end-to-end on real sprites + first game-code wiring (device-validated).** Processed the 4 Phase-7-registry building types present in the raw batch — 16 sprites (`single_home`×6, `apartment`×5, `coffee_shop`×4, `mayors_office`×1) — through [process.py](tools/sprite_pipeline/process.py) → [assets/buildings/](assets/buildings/) + QA overlays in `tools/sprite_pipeline/debug/`. Generalised process.py to accept the real raw naming (`<id>.jpeg` / `<id>_<n>.jpeg` / `<id>_v<n>.png`, bare singleton → v1) while still emitting canonical `<id>_v<n>.png`. **Renderer wiring (additive, zero domain churn):** new `BuildingType.numVariants` (`0` = no art yet → keep the Phase-7 box+emoji placeholder); [city_board_component.dart](lib/game/city/city_board_component.dart) `PlacedBuildingView` now carries `footprint` + `assetPath` and draws the sprite anchored at the footprint's **south corner**, scaled `tileWidth/192`, with the colored box as a one-frame fallback until the async load lands; [iso_city_game.dart](lib/game/city/iso_city_game.dart) owns an `assets/buildings/`-prefixed `Images` cache that lazy-loads referenced sprites; [city_screen.dart](lib/presentation/city/city_screen.dart) `_assetPathFor` picks the variant deterministically per tile (`(gridX*1000+gridY) % numVariants + 1`). Set the 4 pilot buildings' §3 footprints (`mayors_office` / `apartment` → 2×2) + `numVariants` in [building_registry.dart](lib/domain/city/building_registry.dart); placement + road-gen were already footprint-aware so no other changes needed. `flutter analyze` clean, **720 tests pass**. **Device-validated on the Android emulator (API 34):** mayors_office (2×2) + multiple single_home (1×1) sprites render at correct scale + south-corner anchor, tile cleanly alongside the waste-management box placeholder, auto-roads hug the real footprints, and per-tile variant selection yields visible house variety. Code + all 16 processed sprites committed and pushed to `main` (raw NB jpegs renamed `<id>_v<n>.jpeg` to match the PNG `_v<n>` convention; all variants kept, cull deferred). **Follow-up alignment fix:** the footprint didn't sit flush on the tiles because Nano Banana draws a ~1.8:1 isometric while the grid is exactly 2:1 — verified on-device with a temporary footprint-diamond overlay. [process.py](tools/sprite_pipeline/process.py) now measures each sprite's own ground-diamond aspect (south/east/west opaque tips) and squashes it vertically to a true 2:1 (`ground_squash`; falls back to a 0.90 default when the tip detection latches onto a tree/overhang). **Background-removal fix:** rembg's ML matte was sometimes eating a building's flat gray plaza as "ground" (apartment_v2/v5). A pure green chroma-key can't replace it because the green lawns/trees match the green backdrop (a tree foliage pixel measured distance 14 from the screen). So `remove_green_bg` is now a hybrid: rembg's matte (keeps green foliage) + a non-green protection pass that force-keeps any pixel which isn't backdrop-green (judged by greenness, G−max(R,B) > `GREEN_MARGIN`), since the only true background is the green screen. Fixes the plazas without touching trees/lawns. Reprocessed the 16 pilot sprites and re-verified clean in-game (no footprint overlay). **Two city-screen UX fixes:** (a) sprite variant selection is now **round-robin by placement order** in `_viewsFor` — the old `(gridX*1000+gridY) % numVariants` hash collapsed (1000 is divisible by 2/4/5) so every building down a row drew the same variant; (b) fixed a **camera jump on every placement** — the bottom catalog bar collapsed to zero height during `cityCatalogProvider`'s per-placement refresh (`when(loading: SizedBox.shrink())`), resizing the Flame viewport (confirmed via logcat: height toggled 782↔662); now it renders from the retained `AsyncValue.value` so it never collapses. **New raw art added** (committed, not yet processed/wired): `farmhouse`, `luxury_condo`, `power_plant`, `power_station`, `solar_farm`, `water_tower`. **Footprint-gap fix:** even squashed, a building's irregular base left thin transparent wedges inside the tile that showed terrain through. `fill_footprint_gaps` now bleeds the ground out to the footprint-diamond edges (for every not-fully-opaque pixel inside the diamond, copy the nearest solid pixel's RGB + set alpha 255 — a standard alpha-bleed against the footprint geometry); reprocessed the 16 pilot sprites, verified gap-free in-game. (The non-square parallelogram case — issue #90 — is now **fixed**; see this session's rollout above.)
- **Earlier action:** **Phase-9 art-pipeline tooling end-to-end on synthetic inputs.** Locked four design points (10m/tile scale; 97 variants across the 55 §3 anchors; "no text on sprites" + horizontal-flip-for-facing; no 4-facing rotation in v1) and shipped [generate_prompts.py](tools/sprite_pipeline/generate_prompts.py) (55 NB prompts → [prompts.txt](tools/sprite_pipeline/prompts.txt) with `Nx` variant prefix + strict gcd-reduced ratio + `No text.` suffix) + [process.py](tools/sprite_pipeline/process.py) (rembg → bbox-crop → per-footprint canvas at TILE_W=192px → bottom-center anchor → pngquant → debug overlay). Full alternatives-considered log in [city_builder.md §5.2](city_builder.md). No game code touched that session.
- **Next action:** **Pick up the leftovers the remediation deliberately deferred, then return to Phase-9 device verification.** (a) The fresh sweep's 77 could-improve notes ([report](ux_reports/2026-08-19-all-both/report.md)) — mostly cosmetics (tiny superscripts in `integer_exponent_props`, base-ten block size, area-model edge labels, net-3d label placement) plus dataset-item wording that needs re-ingestion (add/sub/mult explanation quality, `mult_multidigit_standard_alg`'s asterisk operator, `sort_rationals` outlier rows). (b) **Dataset versioning:** seeding is only-if-empty (`_seedDatasetQuestionsIfEmpty`), so the repaired `kth_value_in_list` JSON only reaches a device after `pm clear` — existing installs keep stale data until a version/hash check triggers re-seed; without it every future dataset fix silently no-ships. (c) US-coin concepts stay US by design (§7 decision); currency-symbol concepts keep `$` since there is no locale system. Then: **Phase-9 — A second full 364-concept pass has run and is committed ([report](ux_reports/2026-08-13-all-both/report.md): 156 clean, 150 could-improve, 58 bug; screenshots shrunk to ~9.7 MB via `tools/ux_sweep/shrink_shots.py`). **Agreed scope is everything in that report** — all 58 bugs, all 150 could-improves, plus six hand-written observations (§1–§6 of the report's preserved OBSERVATIONS block). §7 records the execution order and the decisions already taken, so **don't re-litigate them**: fraction-division diagrams get fixed rather than dropped; units go metric-alongside-imperial per concept with no locale system; the named sibling concepts are in scope; raw-algebra app-bar titles become plain English. Roughly 50 of the 58 bugs collapse into six root causes — prompt-card clipping (~30, `question_screen.dart:204-225`), `exactString` grading (`answer_check.dart:44`), colliding axis labels (`dot_plot.dart`), keypad-vs-MC gating, also-correct distractors, and content templates — so work those before any wording polish. Verify with `flutter analyze` + `flutter test` per cluster, then re-run `/ux-sweep all` to prove it; that writes a **new dated report dir** — keep this one as the baseline to diff against. Then: **Phase-9 — device-verify the completed catalog + tackle the remaining big features.** (1) ~~Regenerate flagged sprites~~ — **done**: all 16 original dimension-mismatch flags cleared (15 via NB regeneration through 2026-06-15, `clinic` re-footprinted 2×1), every sprite now affine-fits its footprint. — no code change needed (process.py re-runs from the venv; it'll affine-fit them and the error list should come back empty). Alternatively reconcile those §3 footprints toward the drawn ~1×1/2×2 if NB keeps drawing them square. (2) **Device-verify the full 54-building catalog on the Android emulator** — place a sample across all four categories, confirm sprite scale / south-corner anchor / auto-road hugging, especially the affine-fit non-square footprints (sports_field, mid_rise, bus_depot) and the capstones (zoo 5×5, amusement_park 6×6). (3) Bigger Phase-9 features still open: **themed maps + map switcher, building upgrade tiers, currency-funded events** (land expansion ✅ shipped). (4) **Variant cull** to §5.4 target counts still deferred (e.g. `single_home` has 6, target 4–5). (5) Land-expansion price ladder (🧱 60/150/300) is a designed-coherent placeholder — sanity-check it against real earn rates once playtested. **Gotcha hit this session:** iCloud/Finder ` 2`-suffixed duplicate-file pollution under `build/` + `.dart_tool/` broke the first Android build (`packJniLibs` zip conflict on `libsqlite3 2.so`); `flutter clean` + `find . -name '* 2.*' -delete` fixed it, recurs if the Documents folder re-syncs mid-build. **Phase-7 device-verification (non-sprite) still partly owed** — pan/zoom feel, tap-to-place accuracy, tap-to-select + auto-fit move/drop + yellow-tint selection (2026-06-21 revamp), citizen-bubble rotation/ack, demand-gated reveal, age-gated milestone bubble; most are now incidentally observable on the emulator. Once swept, run the **Phase-7 exit-criteria playthrough**. Phase 6 deferred work (selective DeepMind expansion, mix-policy + adaptive-system tuning, kid validation) revisited post-Phase-7. *(Variant-cull to §5.4 target counts deferred — all 16 pilot variants kept for now.)*
- **Deferred:** Audio SFX + background music (CC0 assets not sourced yet — stub in place). iOS verification. Both revisit before Phase 12 at latest.

- **City builder design (planning, 2026-05-21):** Phases 7–8 (city builder) were restructured into Phases 7–9 in a planning conversation. Phase 7 now ships a small "Simple DAG Proof" (~10 buildings, ~5 beats, multi-gate DAG, citizen-bubble UI); Phase 8 is a research + content-design phase that produces a new `city_builder.md` cataloging the full DAG (hundreds of buildings) and beat scripts; Phase 9 implements that content. Phases 9–12 from the old plan shifted to 10–13. PRD City Builder section rewritten accordingly. Currency model **resolved at Phase 7 start (2026-05-23)** — two-currency economy: 🧱 bricks + 🔬 research; see *Domain Specs / Research-currency earning*.

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
| **Cosmetics economy** | Single sink for 🧱 / 🔬: **city builder only**. Avatar is free to customize and not tied to the economy | Phase 4 spike found no Flutter avatar library combines full-body rendering with rich accessory slots — building hat/costume/shoes/backpack overlays on top of a bust-only library was more work than the variety it would buy. City builder alone is plenty of long-arc motivation |
| **Avatar rendering** | **DiceBear Adventurer** style, rendered **fully offline** via local SVG composition using `flutter_svg`. The DiceBear Adventurer SVG component paths (MIT-licensed code, CC BY 4.0 design by Lisa Wischofsky) are bundled in-app as Dart string constants; the composer assembles them at runtime. Player picks from a curated subset of slots (hair style/color, skin tone, eyes, mouth, glasses, earrings, blush/freckles); free to re-edit anytime | Cleanest off-the-shelf look for kids. Fully offline — no network calls, no INTERNET permission needed. `dice_bear` pub package rejected because it calls `api.dicebear.com` at runtime — a showstopper for a kids app that must work without WiFi |
| **City rendering** | Isometric tiles, fixed grid, **auto-generated roads** between buildings | Mobile-friendly: tile-snap + auto-roads avoid fiddly placement; established CC0 isometric packs (e.g. Kenney City Kit) cover the style |
| **Building art pipeline** (Phase 9) | **Nano Banana** (image-gen), single source, **style-anchored** to 2–3 hand-curated CC0 reference images from the [Kenney "Isometric Tiles" series](https://kenney.nl/assets/tag:isometric). Same anchors on every prompt; raster PNG-with-transparency at 2:1 dimetric. No procedural `CustomPainter` for buildings, no mixing finished sprites from multiple CC0 packs, no multi-source generation | First-hand evaluation rejected the native-vector GenAI tools (Recraft V4, Magnific) on quality. Commissioning an artist (~$8–20k indie for 55 buildings — see prior research) is out of budget for a free hobby project. CC0 vector packs cover only ~half the catalog. Procedural building art (Phase-7 placeholders) reads flat. Full alternatives table in [city_builder.md §5.2](city_builder.md) |
| **Milestones** | **Removed.** Replaced by 🧱 brick prices per placement + 🔬 research thresholds for unlocking new building types and themed maps | Milestones were dead weight once the city builder provides natural long-arc progression — every land expansion or new building tier *is* a milestone moment |
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
  coinBalance           // spendable coins (1 coin ≈ 1 expected second of study); spent on buildings, land, events
  lifetimeCoinsEarned   // never decreases — literally "total seconds studied"; gate input on unlockRule.minLifetimeCoins
  streakCount           // consecutive correct answers, uncapped ("N in a row!"); +1 per correct, reset on wrong; coin pay = 0.2 × min(count, 5); persists across sessions
  roundsPlayed          // monotonic count of answered questions — the persistent "round" clock; drives building age (placedAtRound) + bubble rotation
  lastPlayedDate        // (daily streak — future)

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
  coinUnlockCost,                // coins; 0 for the beginner map
  terrainSeed                    // deterministic terrain layout

BuildingType (static catalog — registry in code, mirrored in `city_builder.md §3`)
  id, name, category (civicHousing | services | commercial | entertainment),
  coinCost,                      // coins to place one instance (reads as minutes of study: 60 = 1 min)
  unlockRule,                    // typed value: AND-combination of {minLifetimeCoins, requiredBuildingsPlaced[], minPopulation, requiredBeatsRead[]} — gates whether the building is *available to buy*; requiredBeatsRead means the player must have OPENED (tapped to read) the listed demand beat(s) for the card to appear; once the rule passes the card shows its coin price and is bought straight away (no research step — removed 2026-09-08)
  populationContribution,         // residents this building houses, if any
  serviceProvision,               // map of {clinic: N, power: N, school: N, …}
  varietyContribution,            // 0/1 — whether this type counts toward its category's variety multiplier
  maxTier, assetRefByTier         // opaque per-tier asset ref — Phase 7 resolves to a CustomPainter, Phase 9 swaps to PNG

BuildingTypeResearched (per player, per building type)
  playerId, buildingTypeId, researchedAt
  // Presence => the player has spent the researchCost and this type is permanently in their build menu

BuildingPlacement
  id, cityId, buildingTypeId, currentTier, gridX, gridY, placedAtRound
  // placedAtRound = the player's roundsPlayed at placement; age = current roundsPlayed − placedAtRound, feeds the "building age" beat trigger

ConceptBandMilestone (per player, per concept, per band index)
  playerId, conceptId, bandIndex, awardedAt
  // bandIndex maps into the in-code List<double> of research-award thresholds (currently [0.5, 0.85] — 2 bands)
  // Adding a 3rd band later is a List<double> extension; no schema migration needed

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
  startedAt, players (list)
  // Streak and the persistent round clock (roundsPlayed) both live on Player, not here
```

**Notes:**
- `Item`, `Milestone`, and `AvatarAccessory` from earlier sketches are removed. The only currency sink is the city builder; the avatar is free to customize.
- **Single-currency model (revised 2026-09-08; supersedes the Phase-7 two-currency 🧱/🔬 design):** **coins** are spent on placements, land, and (later) map expansions / events. Coins come from every correct answer — `round(expectedSeconds × formatMult × 0.2 × streakCount)` — plus a one-time band-crossing bonus (2× expectedSeconds) per concept per threshold. See *Domain Specs / Coin economy* and `lib/domain/economy/`.
- `coinBalance` vs. `lifetimeCoinsEarned`: spending decreases `coinBalance`; lifetime only ever grows and is literally "total seconds studied".
- **Unlock model is one-step:** a building is *available to buy* iff its `unlockRule` (lifetime coins / prereq-building / population / `requiredBeatsRead` AND-combination) evaluates true → its card appears in the catalog with its coin price → the player buys it on placement. Saving up for the building the citizens are asking for IS the progression decision. **In the catalog, `requiredBeatsRead` is the primary gate:** every non-starter building names the demand beat that asks for it, so its card only appears after the player taps that demand bubble open. Opening the bubble (not just its appearing) is the trigger — see `markBeatRead` / `db.readBeatIds`.
- `unlockRule` and `triggerRule` are AND combinations of multiple optional conditions. The shape is intentionally typed-but-extensible — Phase 7 ships with the conditions listed above; Phase 9 may add more (e.g. "season" or "time-of-day") if research surfaces a need.
- `serviceProvision` + `varietyContribution` together drive the growth model: aggregate service ratios cap population for under-served categories, and category variety bonuses encourage a balanced mix (monotone cities stall).
- The static `BuildingType` / `StoryBeat` catalogs live as Dart registries (`building_registry.dart` / `beat_registry.dart`) authored against `city_builder.md`, mirroring how `generator_registry.dart` mirrors `curriculum.md`. A sync script (Phase 9) keeps the ✅ markers in `city_builder.md` honest.
- **Building art reference is opaque (`assetRef`).** Phase 7's resolver maps it to a Flutter `CustomPainter`; Phase 9 swaps the resolver to load PNGs. Domain layer never sees a Flutter type either way.

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
| `0.2 ≤ p < 0.5` | challenging | On wheel; correct = 5 🧱; multiple choice |
| `0.5 ≤ p < 0.85` | comfortable | On wheel; correct = 3 🧱; typed input |
| `p ≥ 0.85` | mastered | Excluded from wheel |

**Initial value** when a player first encounters a concept:
- Concept grade ≤ player's stated grade: start at `p = 0.4` (challenging band)
- Concept grade > player's stated grade: start at `p = 0.05` (not yet, off the wheel)

Open Phase 2 knobs: tune `α`, asymmetric reward/penalty (e.g. wrong answers move p down faster than right answers move it up), threshold values, and whether to consider time-since-last-attempt (proficiency decays if not practiced).

### Coin economy — revised 2026-09-08 (supersedes *Research-currency earning*)

One currency, **coins**, where 1 coin ≈ 1 expected second of study. Everything lives in `lib/domain/economy/` (pure Dart, unit-tested):

- **`expected_seconds.dart`** — `conceptId → int` for all 366 concepts, hand-estimated from a grade-band draft (K–1 ≈ 5 s, G2–3 ≈ 10 s, G4–5 ≈ 20 s, G6–8 ≈ 35 s) with quick recall under its band and multi-digit algorithms / long division / multi-step word problems 2–3× over. Coverage-tested against the registry. Never reward *actual* time taken.
- **`coin_economy.dart`** — the tunables and the rules:
  - correct answer pays `max(1, round(expectedSeconds × formatMult × kStreakStep × streakCount))`, `formatMult` 1.0 MC / **1.5 keypad**; wrong pays 0;
  - `streakCount` +1 per correct, reset to 0 on wrong — uncapped and shown as "N in a row!"; pay multiplier = 0.2 × min(count, **5**), computed at the *new* count so the first correct after a miss pays 20%; global per player, persisted (`Players.streakCount`);
  - a spin yields `ceil(25 s / expectedSeconds)` questions, clamped **[1, 6]**;
  - **band-crossing bonus** = `2 × expectedSeconds`, paid once per concept per threshold.
- **`band_crossings.dart`** — thresholds `[0.5, 0.85]`, one-shot per `(player, concept, bandIndex)` via `ConceptBandMilestones` (unchanged table; adding a band is a one-line code change, no migration).
- **`question_block.dart`** — `QuestionBlock` / `AnswerReward` value types the spin → question → summary chain threads through.

The band's only remaining job is choosing MC vs keypad. Wheel retirement: a concept ≥2 grades below the player retires once comfortable (`isRetiredFromWheel`).

### Wheel composition — revised 2026-09-16 (supersedes the Phase 5 "starter pack of 2/4, one unlock per mastery, `min(introduced, 8)` segments" rules)

**Problem it solves.** With a 4-concept starter pack and a one-in/one-out drip-feed, the wheel never grew past 4 and the same 3–4 labels showed every spin. For grade-2+ players it was worse: the lowest-grade-first pick handed out K concepts that *start* mastered, so each mastery shrank the wheel by one until the fallback pinned the mastered starters forever. Content was never the bottleneck (364/366 concepts have generators).

**Decisions (user, 2026-09-16):**
- **8 segments whenever the pool allows** (`kWheelSegments`). Everything lives in [lib/domain/concepts/wheel_selection.dart](lib/domain/concepts/wheel_selection.dart), pure Dart, unit-tested.
- **Two tiers.** *Frontier* = introduced ∩ implemented ∩ challenging-or-comfortable ∩ not retired. *Review* = introduced ∩ mastered ∩ not retired — mastered concepts are **back on the wheel**, capped at **`kReviewSlots` = 2** segments (keypad mode, normal pay; `expected_seconds` pricing and retirement bound any coin farming). If one tier can't fill its share the other does, so the wheel is only short when both are.
- **Active pool target `kActivePoolTarget` = 12.** The starter pack is 12 (same easiest-at-the-frontier policy, ignoring prereqs as before). After every *correct* answer `DripFeedEngine.topUp` introduces concepts (via the unchanged `pickNext` policy: lowest grade → category with fewest active → row order, prereqs mastered, generator registered) until the frontier count is back at 12 — so a mastery or a retirement refills the pool, usually by one. Wrong answers never unlock anything.
- **Rotation `kMinRotation` = 3.** At least 3 of the 8 segments were not on the wheel the player last saw (`lastWheelProvider`, session-only), pool permitting. Frontier absorbs the quota first, review takes the remainder.
- **Two drip-feed fixes that fell out.** (1) `pickNext` never picks a concept whose starting proficiency is already mastered (they satisfy prereqs without being introduced). (2) `startingProficiency(introduced: true)` floors an *introduced* above-grade concept at 0.40 (challenging) instead of 0.05 (`notYet`): the drip-feed only introduces it once its prereqs are mastered, and at 0.05 nothing could ever lift it onto the wheel — a K player who mastered all of K would have had grade 1 introduced invisibly.
- **Unlock UX moves to the wheel.** Segments the player has never answered (no proficiency row) carry a **"NEW" sticker**; the **first landing** on one shows a celebration overlay before the block (tap or 2.4 s auto-advance). The block summary keeps a **one-line teaser** ("N new topics are on the wheel!") with category-coloured placeholder badges — the per-concept icons the wheel will eventually carry replace those badges later.
- **Mastery speed left for playtest.** α = 0.1 and the 0.85 threshold are unchanged (14 straight correct from 0.40). A wider pool visits each concept less often, so masteries and band bonuses come slower; fold retuning into the coin-price playtest.

**Follow-ups (done 2026-09-16, direct to `main`):** (1) **Grades interleave.** The starter pack is drawn round-robin across in-band grades, at-grade first (a grade-3 player starts 6 × grade-3 + 6 × grade-2), and `pickNext`'s step 1 is now "stay at-or-below the player's grade while anything there is eligible; among those grades prefer the one with the fewest active concepts, tiebreak higher" — above-grade content only once at-or-below is exhausted, lowest first. (2) **Review sticker.** Mastered concepts on the wheel carry a small teal ✓ pill (same sticker as NEW, different colour). Unit-tested (6/6 split, grade-balanced refill, grade-6 player never gets grade-7 while ≤6 remains); the sticker is not device-verified (needs a mastered concept on a fresh profile).

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
- **DAG drip-feed semantics.** *(Superseded 2026-09-16 — see Domain Specs → Wheel composition: starter pack of 12, top-up to 12 after every correct answer, auto-mastered concepts never picked.)* New player starts with 2 implemented concepts (lowest grade, lowest within-category row order). One new concept is introduced per mastery event. A concept is eligible for introduction only when all its DAG prereqs are `mastered` *and* its generator is registered. **No cross-domain gating** — independently per branch. **Pick policy:**
  1. Among eligible concepts, pick the lowest `Grade` first.
  2. Tiebreak by category: prefer the category in which the player currently has the *fewest active concepts* (introduced-but-not-mastered) — keeps the wheel balanced across math domains.
  3. Within the chosen category, pick the lowest row position in the [curriculum.md](curriculum.md) §3.x table for that category. Per `curriculum.md` design principle 8, that row order is the curated within-grade difficulty signal. **No global cross-category difficulty order exists** — re-sorting one category never touches another.
- **Unlock UI moment.** *(Superseded 2026-09-16 — the wheel carries "NEW" stickers and a first-landing celebration; the summary keeps a one-line teaser.)* A "New concept unlocked!" celebration card is shown after the result screen, but only on correct answers that triggered either a mastery event or a queue advance. Never on wrong answers — this avoids the confusing scenario where a kid gets a question wrong but sees a celebratory unlock.
- **Word-problem framework: deferred to Phase 6.** This phase already covers schema migration + framework architecture + ~12 migrated + ~10 new generators + 3 diagram widgets + DAG engine + unlock UI. The word-problem framework (name/item/verb pools + 1-step template engine) and its first dataset-tagged sub-concept moved to Phase 6.
- **Drift v4: wipe-and-recreate.** No real users yet, so the existing v3 migration pattern is fine. A proper additive-migration implementation is now a prerequisite task in Phase 11 (Cloud Save) — once player data lives off-device, wipes destroy real data.
- **Wheel segment count.** *(Superseded 2026-09-16 — always 8 when the pool allows, 2 of them review slots; see Domain Specs → Wheel composition.)* Fixed cap at 8. The wheel renders `min(introducedConceptCount, 8)` segments and never more.

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

**Resolved (locked at Phase 7 start, 2026-05-23):**
- [x] **Currency model: two-currency.** 🧱 **bricks** (rename of `stars`) for placements; 🔬 **research** for unlocking building types. Bricks earned per correct answer; research earned on per-concept band crossings (see *Domain Specs / Research-currency earning*). Number of award bands is a `List<double>` constant — easy to extend without a schema migration. PRD + Data Model updated.
- [x] **Initial ~10-building catalog:**
  - Civic-core / housing: mayor's office, single home, apartment, school
  - Services: clinic, power plant, waste management
  - Commercial: grocery, coffee shop
  - Entertainment: park
- [x] **Placeholder art: pure Flutter `CustomPainter`.** Colored isometric tiles + emoji + label per building type, sized by tile footprint. No Kenney / PNG / asset-pipeline work in Phase 7. `BuildingType.assetRef` is opaque so Phase 9's swap to image-based art is a resolver change with zero domain churn. See "Art roadmap" below.

**Art roadmap (Phases 7 → 9):**
- **Phase 7:** Flutter `CustomPainter` placeholders. Single isometric (dimetric, 2:1 pixel ratio) projection; each building rendered as a colored tile + emoji + label.
- **Phase 9 (locked 2026-06-04): Nano Banana, style-anchored to hand-curated CC0 reference images.** A small set of 2–3 anchor refs from the [Kenney "Isometric Tiles" series](https://kenney.nl/assets/tag:isometric) (the chunky-iso CC0 line — see prior-session Kenney research) is fed on *every* prompt so palette / lighting / shadow direction / projection stay coherent across all 55 buildings. Output: PNG-with-transparency, 2:1 dimetric, with per-building footprint metadata (`1×1`–`6×6`, anchor point so the base sits on the grid). **Hard rules:** no procedural `CustomPainter` art for buildings (Phase-7 placeholders read flat); no mixing finished sprites from different CC0 packs (visible style seams); no multi-source generation. Full alternatives-considered log in [city_builder.md §5.2](city_builder.md).

**Build:**
- [x] Drift schema (now **v8**): currency split on `Player` (brick/research balances + lifetime counters) plus the persistent `roundsPlayed` round clock, plus new tables `City`, `CityMap`, `BuildingTypeResearched`, `BuildingPlacement`, `StoryBeatState`, `ConceptBandMilestone` — see Data Model section. Wipe-and-recreate migration (still pre-real-users per plan.md). Static catalogs (`BuildingType`, `StoryBeat`, `CityMap`) live as code registries, not Drift rows.
- [x] One beginner `CityMap` definition: ~12×12 tile grid, fixed terrain (`city_map_registry.dart`)
- [x] Initial `BuildingType` registry (the 10 from the catalog above — `building_registry.dart`), each with `category`, `brickCost`, `researchCost`, `populationContribution`, `serviceProvision`, `unlockRule`, and a placeholder `assetRef`
- [x] **DAG unlock engine** (pure-Dart, well unit-tested — `unlock_rule.dart`, tests in `unlock_rule_test.dart` + `city_catalog_test.dart`) — a building's `unlockRule` is a typed value combining any of `{minLifetimeBricks, requiredBuildingsPlaced, minPopulation, requiredBeatsRead}` with AND semantics. `cityCatalogProvider` evaluates the rule against current city + player state and returns the *available-to-research* set. Per the 2026-05-24 design call the catalog is discovery-based (available buildings simply appear as locked cards — no separate "newly available" event / tech tree). **Demand-beat gating (2026-05-26):** every non-starter building sets `requiredBeatsRead` to the demand beat that asks for it, so its card only appears once the player has *opened* (read) that bubble — `cityCatalogProvider` feeds `db.readBeatIds` (beats with a non-null `ackedAtRound`) into the `UnlockContext`. **Note:** a building moving into the available-to-research set does NOT auto-unlock it — the player must still spend `researchCost` to add it to `BuildingTypeResearched`.
- [x] **Research-award rule** (pure-Dart, well unit-tested) — wired into the proficiency-update path: on each `p` update, for every threshold in `researchAwardThresholds` that's been crossed (old `p` below, new `p` ≥) and has no `ConceptBandMilestone` row, insert the row and increment the player's research balance. Idempotent (re-running the update with the same inputs awards nothing). *(Chunk 1)*
- [x] **Story-beat engine** (pure-Dart, well unit-tested) — each beat has trigger conditions (`buildingsPresent` / `buildingsAbsent` / `minPopulation` / `minBuildingAgeForX` / `requiredBeatsFired` / `minBricksEarnedSinceLastBeat`), emoji + sticker payload, and short + long text. *(Pure `BeatEngine.eligibleBeats` + `TriggerRule` done in Chunk 1; firing + the `(beatId → state)` cross-session map wired in Chunk 6 via `CityActions.fireBeats` + `StoryBeatStates`.)* The persistent round clock (`Players.roundsPlayed`) now feeds building-age triggers (`minBuildingAgeForId`) and round-based bubble rotation (`onScreenBeatsProvider` hides an un-acked bubble after `kBubbleRotationRounds`).
- [x] ~5–10 hand-written beats in code — **9 beats in [lib/domain/city/beat_registry.dart](lib/domain/city/beat_registry.dart)** (2026-05-24): housing demand + praise, pre-unlock demand for clinic / power / waste (the waste one is the "trash is everywhere" anti-prereq warning gated on `minPopulation`), a recurring "another park?" demand (brick-spaced), grocery + coffee-shop placement praise, and an aged-mayor + prior-praise milestone. Exercises every `TriggerRule` field. Tested in `test/domain/city/beat_engine_test` (eligibility scenarios) + new `test/domain/city/beat_registry_test` (catalog integrity: unique ids, all referenced buildings/beats exist).
- [x] Isometric tile renderer (Flame component) — terrain + placed buildings + auto-roads, pinch-zoom and pan (done in earlier chunks), plus the **emoji-bubble overlay** (Chunk 6): floating stickers over the city (≤5, from `onScreenBeatsProvider`, ringed by beat kind), tap-to-expand into a card with the full sentence + "Got it" → `CityActions.dismissBeat`. Empty overlay regions pass touches through so the city stays pannable; a scrim catches outside taps while a card is open. *Bubbles are screen-space (top of the viewport), not yet anchored over the specific relevant building — per-building anchoring is a Phase 9/polish refinement (camera-transform tracking). Device-verification owed.*
- [x] **Research UI — folded into the build-mode catalog (no separate panel; 2026-05-24 design call).** The bottom catalog lists buildings currently *available to research* (per `unlockRule`) as **locked cards** (🔬 `researchCost` + lock badge) mixed in with the already-researched/placeable ones. Tapping a locked card with sufficient research balance opens a confirm dialog, then spends 🔬, inserts a `BuildingTypeResearched` row, and the card flips to placeable in place. Buildings not yet available-to-research are not listed (discovery-based — no visible tech tree). *(Chunk 3)*
- [x] **Build-mode UI:** catalog at the bottom listing only buildings the player has researched (rows in `BuildingTypeResearched`); tap building → tap free tile → placed; insufficient 🧱 greys out the option. *(Chunk 2)*
- [x] **Move-mode UI** — toggle FAB (🔧 `open_with`, hidden until something's placed) flips the city into move mode; the bottom bar becomes a `_MoveModeBar` instruction strip + Done button. Tap a placed building to pick it up (outlined on the board via `CityBoardComponent.highlightTile` + `IsoCityGame.setHighlight`), tap a free tile to drop it (no 🧱, validated by the same road-access invariant with the mover excluded), tap another building to switch, tap the held one to put it down. *(Chunk 4; device-verification owed — pick-up highlight + drop on the Flame canvas.)*
- [x] **Placement validation — road-access invariant** — `lib/domain/city/placement_rules.dart` (pure-Dart, 15 tests in `test/domain/city/placement_rules_test.dart`). Free placement stays (any unoccupied tile, buildings may touch); the one constraint is that **no building may be boxed in.** A placement or move is legal only if every building keeps ≥1 free orthogonal tile somewhere on its footprint perimeter (the grid edge does *not* count as open — a road needs an in-bounds vacant tile). Checked **two-way**: (a) the building being placed/moved must have an open perimeter side, *and* (b) it must not seal the last open side of any neighbor it now abuts (only neighbors the candidate actually touches are re-checked, so a pre-existing boxed-in building never blames a fresh placement). Generalized over `BuildingType.footprint` via `GridFootprint.perimeter()` — all Phase 7 buildings are 1×1, but the check walks the real footprint ring so a future 2×2 is handled. Wired into `CityScreen._onTileTapped` (place + unique-relocate paths) with a gentle snackbar nudge per `PlacementRejection`. Supersedes the bare occupied-tile rejection
- [x] **Auto-road generation — island-hug + connectors** — `lib/domain/city/road_network.dart` (pure-Dart, 8 tests in `test/domain/city/road_network_test.dart`). `generateRoads` runs two steps: (1) **hug** — pave every empty tile in the Moore (8-dir) neighbourhood of a building, wrapping each cluster of buildings in a connected road ring and filling the small gaps between neighbours; (2) **connect** — find the road components and thread separate clusters together with shortest grass paths (multi-source BFS). Nothing is paved unless it hugs a building or links two clusters, so open space stays green (replaces the earlier bounding-box fill, which paved dead space and looked bad). Leans on the road-access invariant so every building is fronted by road. Rendered as grey tiles in the board's terrain pass (`CityBoardComponent.roads` + `IsoCityGame.setRoads`, same pending-buffer pattern as buildings), so buildings always draw on top. Recomputed in `CityScreen.build` from the live placements (refreshes on place + move). *Device-verification owed: roads visible/correct on the Flame canvas.*
- [x] Population counter visible on the city screen — `_PopulationChip` (👥 + count) over the top-left, reading the live `Cities.population` value. *(Chunk 5)*
- [x] **Population growth model v1** (pure-Dart, well unit-tested) — `lib/domain/city/population_model.dart`, 2026-05-24; wired into the city via `CityActions.tickPopulation` (stepped on each placement + each answered question). Grows toward `sum(populationContribution)` modulated by:
  - service ratios (e.g. 1 clinic per 50 residents, 1 power plant per 200)
  - category-variety multiplier (a small bonus per distinct commercial / entertainment building type placed; a small penalty for category lopsidedness like "all entertainment, no housing")
- [x] "My City" screen accessible from the home screen *(Chunk 2 — now the per-player hub: home chip → My City → spin wheel)*
- [ ] **Exit criteria:** Player starts empty, places the mayor's office as their first build, earns enough 🔬 from band-crossings to research a non-mayor building, sees a citizen bubble demand a service that's not yet *available* to research, plays math until they hit the `unlockRule` (lifetime 🧱 + prereqs + pop) for that service, spends 🔬 to research it, spends 🧱 to place it, sees a praise bubble appear, hits a growth-stalling service-ratio cap on a different service, sees the corresponding demand bubble, builds the missing service, watches population resume growing — all surviving an app restart.

---

### Phase 8 — City Builder: Research & Rich Design (target: ~2–3 weeks)

**Goal:** Design the full DAG (target: hundreds of buildings across the 4 categories) and the rich beat catalog (target: hundreds of beats) that Phase 9 will implement. This is a content-authoring phase with **no code changes** — its primary deliverable is a new `city_builder.md` that plays the same role for the city builder that `curriculum.md` plays for the math curriculum.

**Why this is a phase, not a chunk:** the design needs to *feel infinite* without becoming a junk drawer. That requires studying what existing city-builders do well, then producing a coherent design — not improvising hundreds of buildings ad hoc.

- [x] **Research phase** — study existing city-builders for what makes their progression feel rewarding vs. grindy. SimCity (original through *SimCity 4*) is the obvious primary reference; secondary candidates: Cities: Skylines (unlock pacing), Township / Stardew Valley (cozy progression), CivCity, Anno series. Capture findings in `city_builder.md` §1 "References & Lessons Learned" — *done; §1 written with borrow/reject lists.*
- [x] Author **`city_builder.md`** at the repo root, structured to mirror `curriculum.md` *(first draft — §1–§5 + §7 full, §6 Phase-7 rows only; awaiting review)*:
  - **Status block** — current state of the design (which sections are stable, last edited, etc.)
  - **§1 References & Lessons Learned** — what other games did, what we'll borrow / reject
  - **§2 Categories** — civic-core/housing, services, commercial, entertainment — with role definitions and growth contribution
  - **§3 Building catalog** — the full DAG. Each entry: id, name, category, 🧱 `brickCost`, 🔬 `researchCost`, unlock rule (the multi-gate DAG that controls *availability to research*), population contribution, service-provision profile, expected unlock arc (early / mid / late game). Group by category. Aim for a coherent progression within each category (e.g. housing arc: single home → duplex → apartment → high rise → luxury condo); avoid "random" multi-parent prereqs
  - **§4 Story beat catalog** — every beat: id, trigger conditions (buildingsPresent / buildingsAbsent / minPop / minBuildingAge / requiredBeatsFired / spacing), emoji + sticker, short text, expanded text, tone (silly / civic / praise / demand). Cross-reference back to §3 building IDs
  - **§5 Asset checklist** — for each §3 building, what art / sound assets are needed; sourcing strategy (Kenney / OpenGameArt / commission / generate). Must hit the licensing rules: CC0, CC-BY, or equivalent only; CC-BY-NC and CC-BY-NC-SA excluded (matches curriculum.md / `LICENSES_THIRD_PARTY.md`)
  - **§6 Implementation status** — ✅ markers for each §3 building & §4 beat indicating whether it's wired up in code yet. Initially all blank; Phase 9 ticks them. Auto-managed by a `tools/city_builder/sync_implementation_status.py` script (deferred until §6 has rows worth syncing)
  - **§7 Open Questions** — items that need playtesting or further research before they can be locked
- [x] Sanity-check the DAG: no cycles, every multi-parent node makes narrative sense, every building has at least one trigger beat in §4 — *done in §3.7; cross-checked that all 54 `reads:` demand-beat references resolve.*
- [x] Lock the design enough that Phase 9 can implement without designing as it goes — but expect to iterate during Phase 9 as content meets reality
- [x] **Exit criteria:** `city_builder.md` exists with §1–§7 populated; the DAG is reviewed for narrative coherence; Phase 9 has a clear queue of buildings + beats to implement.

---

### Phase 9 — City Builder: Rich Implementation & Graphics (target: ~6–10 weeks)

**Goal:** Implement the full `city_builder.md` design — every building in §3 is placeable, every beat in §4 fires, every art asset in §5 is in the app. Significantly larger phase than the others.

- [x] Stand up `tools/city_builder/sync_implementation_status.py` (mirroring `tools/curriculum/sync_implementation_status.py`) — syncs ✅ markers in `city_builder.md` §3 / §4 / §6 against `building_registry.dart` / `beat_registry.dart` / `assets/buildings/` *(shipped 2026-06-12; also audits numVariants vs on-disk sprites)*
- [ ] **Authoring loop** — iterate building-by-building (or in small clusters):
  - Add to `building_registry.dart` with category, costs, unlock rule, population/service data
  - Add the building's triggering beats to `beat_registry.dart`
  - Source / generate the building art per §5
  - Run the sync script; tick the ✅
- [ ] **Building art pipeline — locked 2026-06-04: Nano Banana, single source, style-anchored to a small CC0 reference set** (anchors from the [Kenney "Isometric Tiles" series](https://kenney.nl/assets/tag:isometric)). All 55 §3 buildings generated through one pipeline; same anchors on every prompt; outputs are PNG-with-transparency at 2:1 dimetric. Procedural `CustomPainter`, CC0-pack mixing, native-vector GenAI (Recraft / Magnific), and commissioning a freelance artist were all considered and rejected — full research log in [city_builder.md §5.2](city_builder.md). Phase-9 work is therefore *executing* the pipeline, not picking it.
- [ ] Themed maps (countryside, big-city, futuristic) — each with its own `starCostToUnlock` (or equivalent in the chosen currency model) and independent placement state per player
- [ ] Map switcher UI on the city screen
- [x] Land expansion — spend 🧱 to grow the grid symmetrically outward by 2 tiles per side (existing placements shift to stay centered). Cap at 24×24 for v1; 🧱 60/150/300 ladder *(shipped + device-verified 2026-06-12)*
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
- **By Phase 7 start (resolved 2026-05-23):** **Currency model** — **two-currency economy:** 🧱 bricks (rename of `stars`, spent to place buildings) + 🔬 research (spent to unlock new building types). Bricks per correct answer; research on per-concept band crossings. Number of research-award bands is a `List<double>` constant — easy to extend without schema migration. See Phase 7 task list + Domain Specs / Research-currency earning.
- **By Phase 7 (resolved 2026-05-23):** **Initial ~10-building catalog** — mayor's office / single home / apartment / school (civic+housing); clinic / power plant / waste management (services); grocery / coffee shop (commercial); park (entertainment).
- **By Phase 7 (resolved 2026-05-23):** **Placeholder art** — pure Flutter `CustomPainter` placeholders; opaque `assetRef` makes the Phase 9 swap to image-based art a resolver change with zero domain churn. Kenney + image-gen pipeline deferred to Phase 9 (see Phase 7 "Art roadmap").
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
