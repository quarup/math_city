---
name: ux-sweep
description: Play through implemented curriculum concepts on the emulator — screenshot each question in both the multiple-choice and keypad interfaces, answer it right and wrong, and write a dated UX review report with per-concept notes. Use when asked to UX-test / review / sweep concepts, a curriculum section (e.g. "3.3 addition and subtraction"), or all of them.
---

# Concept UX sweep

Drives every implemented concept through a real question on the emulator
and produces `ux_reports/<date>-<scope>-<band>/report.md`: one row per
concept with its question screenshot in each input mode, the wrong-answer
screenshot, and notes on what's broken or could look better.

## Inputs

| input | values | default |
|---|---|---|
| **scope** | `all`, a section number (`3.3`), a category id (`add_sub`), a category-name substring (`"fractions"`), a single concept id (`add_within_10`), or a comma-separated mix | ask if not given |
| **band** | `both`, `mc`, `keypad` | **`both`** — don't ask |

The catalogue is **364 concepts** — the union of the generator registry
and the bundled dataset pool, i.e. everything the app can actually serve.
Four concepts are dataset-only, so listing the registry alone would
silently drop them.

Scale check before you start — `python3 tools/ux_sweep/uxctl.py concepts <scope>`
counts what you're committing to. A full 364-concept sweep is about 27 min
of probing plus ~25 review subagents.

## How it works

The app runs a `kDebugMode`-only HTTP control port
([lib/services/debug_harness.dart](../../../lib/services/debug_harness.dart))
on `127.0.0.1:8081`. `uxctl.py` drives it over `adb forward`. There is
**no tapping and no navigating by screenshot** — the port takes a concept
id and puts that question on screen, hands back the correct answer, and
submits answers through the app's real submit path.

Up to three screenshots per concept, all report deliverables:

1. **question, multiple choice** — the four choice buttons.
2. **question, keypad** — a completely different answer area, and the
   pad's extra-chars row (`/` for fractions, `:` for times) is derived
   from the answer, so it's worth seeing on its own.
3. **wrong answer** — the same question, replayed from its seed and
   answered with a distractor, so you see the red screen and its
   explanation.

**Only one wrong-answer screenshot, even in `both` mode.** The band never
reaches `ResultScreen` — it renders from the question, the submitted
answer and the outcome, and in debug mode bricks are always 0 and the
unlock event null. Same seed → same question → same distractor → the same
red screen (verified on device: only the status-bar clock differed).

**Concepts that force multiple choice get no second screenshot.** A
question with `multipleChoiceOnly`, or a text-shaped answer format
(`string`, `commaList`), renders the MC screen even at the comfortable
band. `uxctl` detects this, records `keypadForcedMc`, and skips the
duplicate; the report shows _keypad → MC_.

The green "Correct!" screen is asserted programmatically, not captured —
it's identical for every concept.

`RenderFlex` overflows and build exceptions are captured by the port and
returned as data, so you do not have to hunt for them in pixels.

## 1. Preflight

```sh
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
"$ADB" devices                                    # expect emulator-5554
python3 tools/ux_sweep/uxctl.py ping              # {"ok":true,"homeReady":true}
```

If the ping fails, launch the app per
[run-on-emulator](../run-on-emulator/SKILL.md) — including its step 0
iCloud-duplicate cleanup — then ping again:

```sh
nohup flutter run -d emulator-5554 > /tmp/mathcity_run.log 2>&1 &
```

Poll `/tmp/mathcity_run.log` for `Flutter run key commands` (1–3 min cold).
`uxctl ping` returning `homeReady: false` means it's still on the splash
screen; wait and retry.

## 2. Probe — one serial pass, no images

Pick the report directory once and reuse it for the whole run:

```sh
OUT="ux_reports/$(date +%F)-<scope-slug>-<band>"
```

Then probe. **Always pass `--resume`** — it makes the command safe to
re-run after any interruption.

```sh
python3 tools/ux_sweep/uxctl.py probe --out "$OUT" --resume '<scope>'
```

`--band` defaults to `both`; pass `--band mc` or `--band keypad` only if
the user asked for one mode.

~4.4 s per concept in `both` mode (2.2 s single-band). Anything over ~100
concepts exceeds the Bash timeout, so **run it with
`run_in_background: true`** and wait for the completion notification. Tell
the user it's running and roughly how long.

This is the only step that touches the emulator, and it is strictly
serial. Never run two probes at once.

Output so far: `$OUT/probe.jsonl` (one JSON line per concept) and
`$OUT/shots/<id>__mc.png`, `<id>__keypad.png`, `<id>__wrong.png`.

## 3. Review — parallel subagents

The screenshots are on disk now, so reviewers only read files and never
contend for the emulator. **Batch 15 concepts per subagent, up to 5
subagents at a time** — at up to 3 images each that's ~45 images per
reviewer.

Split the ids from `probe.jsonl` in file order (already curriculum order),
skipping any id that already has a note. Give each batch an index so its
notes file is unique.

Spawn each with the `Explore` agent type and this prompt, substituting
`$OUT`, `$N`, and the id list:

> Review Math City question screenshots for UX defects.
>
> For each concept id below, read its record in `$OUT/probe.jsonl` (JSON
> line, match on `"id"`) and look at every screenshot it names —
> `mcShot`, `keypadShot` (absent when `keypadForcedMc` is true, which is
> fine and not a defect), and `wrongShot`, all relative to `$OUT/`.
>
> IDS: `<15 ids>`
>
> Judge each against this rubric, in priority order:
> 1. **Is the question answerable and correct?** Does the prompt match
>    the diagram? Is `correctAnswer` actually right for what's shown? Are
>    the distractors plausible but genuinely wrong? Watch for a diagram
>    labelled in a different notation than the answer expects.
> 2. **Is it clipped, overflowing, or cut off?** Long choice labels,
>    prompts running out of the card, diagrams pushed off-screen.
> 3. **Does the keypad version work as a typed question?** It has no
>    choices to bound the answer, so: is the expected form unambiguous
>    (would `0.50` / `2/4` / `1 1/2` be typed instead)? Does the pad
>    expose the non-digit keys the answer needs — `/` for a fraction,
>    `:` for a time? Could more than one number be correct? A question
>    that only makes sense against a list belongs in MC.
> 4. **Is it legible for a 6–14 year old?** Text size, contrast, crowded
>    diagram elements, unexplained notation.
> 5. **Is the wrong-answer explanation useful?** Does it explain the
>    method, or just restate the answer?
>
> When a record has `datasetPool` > 0, some of that concept's questions
> come from a bundled dataset rather than the generator, so this one probe
> may not be representative — say so in the note rather than declaring the
> concept clean on a single sample.
>
> Then append exactly one JSON line per concept to
> `$OUT/notes/batch-$N.jsonl` (create the dir if needed):
>
>     {"id": "...", "verdict": "ok"|"improve"|"bug", "notes": "..."}
>
> - `ok` — nothing worth a developer's time. Leave `notes` empty.
> - `improve` — works, but a visual/wording change would help.
> - `bug` — wrong, broken, clipped, or unanswerable.
>
> Keep `notes` to one or two specific sentences naming what you saw, and
> say which mode it applies to when it isn't both. No praise, no hedging,
> no restating the rubric. Every id in the list gets exactly one line,
> even the clean ones.
>
> Return only: `<n> reviewed, <n> ok, <n> improve, <n> bug`.

Do not review batches yourself unless the scope is under ~15 concepts.

## 4. Build the report

```sh
python3 tools/ux_sweep/build_report.py "$OUT"
```

Deterministic and idempotent — re-run it after every batch or at the end.
It merges `probe.jsonl` with every `notes/*.jsonl` and writes
`$OUT/report.md`: a summary line, a **Findings** table of everything
flagged, then a per-category table in curriculum.md order.

### It validates itself — don't skip this

A sweep under-covers in more ways than "an agent forgot a note", and all
of them look like a finished report unless something checks. On every
build it verifies:

| check | catches |
|---|---|
| every id in `scope.json` is in `probe.jsonl` | a probe pass that died partway — `probe.jsonl` alone always looks complete, only the scope manifest knows what was asked for |
| every probed concept has a note | a reviewer subagent that died, or quietly dropped ids from its list |
| every note maps to a probed id | a typo'd or invented concept id counting as coverage |
| verdicts are `ok` / `improve` / `bug` | malformed reviewer output |
| `bug` / `improve` notes have text | a flagged problem nobody can act on |
| referenced screenshots exist on disk | a lost or half-pulled capture |

Any problem → **exit code `2`**, the problems printed, and a
`> [!WARNING] This report is incomplete` block at the top of `report.md`
listing them. Clean → exit `0` and
`validation: OK — every scoped concept probed and reviewed`.

To close a review gap:

```sh
python3 tools/ux_sweep/build_report.py "$OUT" --list-unreviewed
```

Feed those ids back into step 3 as a fresh batch, rebuild, and repeat
until the exit code is `0`. To close a probe gap, re-run step 2 with
`--resume`. If an id fails review twice, write its note by hand rather
than leaving it blank.

Two exemptions, both deliberate: concepts whose probe `status` is
`failed` need no note (there are no screenshots to look at, and they're
already in Findings), and a `--limit` run reports its unprobed remainder
as expected rather than as a fault.

## 5. Wrap up

- **Only report a sweep as complete when `build_report.py` exits `0`.**
  If you stop early, say so explicitly and quote the validation output —
  never present a partial report as a finished one.
- Report the counts and the most serious findings in your reply. Link the
  report with a markdown path.
- Commit the whole `$OUT` directory (`report.md`, `probe.jsonl`,
  `notes/`, `shots/`). Screenshots average ~69 KB, so a full both-band
  sweep is roughly **60 MB of PNGs** — say so before committing one, and
  offer `--max-dim 800` for a smaller re-run.
- File anything serious as a GitHub issue with `gh issue create`, not in
  `plan.md`.

## Resuming an interrupted sweep

Point at the same `$OUT` and re-run from step 2 — `--resume` skips
concepts already in `probe.jsonl`, and step 3 skips ids that already have
a note. Nothing is redone.

## Failures the harness reports for you

These land in `probe.jsonl` `status` and are surfaced in the report
automatically — you don't need to spot them:

| status | meaning |
|---|---|
| `correct_answer_rejected` | the app graded its own canonical answer WRONG |
| `distractor_accepted` | a distractor was graded CORRECT |
| `failed` | the screen never rendered — see `error` |

`renderErrors` (overflows, build exceptions) and `replayStable: false`
(the seed didn't reproduce the question) are flagged the same way.

## Options

| flag | default | use |
|---|---|---|
| `--band B` | `both` | `mc` or `keypad` to capture just one input mode |
| `--max-dim N` | `1200` | screenshot long edge; `0` keeps native 1080×2400 |
| `--limit N` | all | probe only the first N — good for a smoke test |
| `--salt N` | `0` | change it to draw different questions for the same concepts — the way to get a second sample of a dataset-backed concept |
