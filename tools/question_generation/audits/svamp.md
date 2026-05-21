# SVAMP — ingestion audit

This document is the input to the dataset-ingestion sub-track decision for
SVAMP. Mirrors the DeepMind audit pattern from Chunk 81: a hand-edited
verdict around an auto-regenerated sample report
([svamp_samples.md](svamp_samples.md), produced by
[`audit_svamp.py`](../audit_svamp.py)).

**TL;DR — Verdict: drop SVAMP (don't ingest).** Following Chunk 82's
MD-ES convention, this is recorded by flipping §7.7's SVAMP row to
*"audited 2026-05-21 — dropped (licence)"* and adding a TL;DR paragraph
to §7.7; the §7.2 priority list, §7.5 coverage matrix, and §7.6 gap
callouts are intentionally left untouched so SVAMP stays visible in the
dataset universe as considered-but-rejected. Detail below.

---

## 1. The framing

SVAMP is one of the §7.2 top-5 priority datasets, with a known caveat
flagged on the row itself: *"MIT (with provenance audit needed: some items
derive from CC-BY-NC ASDiv)"*. The audit's central question is therefore
not the DeepMind-style coverage-vs-variety axis but **whether SVAMP is
licence-clean enough to bundle in a freely-distributed app at all**, and
if not, whether enough of the dataset is salvageable that the answer
could still be "ingest a slice".

## 2. Licence findings

SVAMP's own [LICENSE file](https://github.com/arkilpatel/SVAMP/blob/main/LICENSE)
is MIT (© 2021 Arkil Patel). That alone is not the licence picture for
downstream redistribution. Three findings:

**Finding A — Paper-acknowledged derivation from CC-BY-NC ASDiv-A.**
The SVAMP paper (Patel et al., *Are NLP Models really able to Solve Simple
Math Word Problems?*, NAACL 2021, §3) constructs SVAMP by selecting seed
examples from ASDiv-A and MAWPS and applying three families of variation
(Question Sensitivity, Reasoning Ability, Structural Invariance) to each.
The repo's README is explicit:

> We work with the following datasets: mawps, asdiv-a, svamp [...] we
> created a challenge set called "SVAMP"

ASDiv's own README is unambiguous about its licence:

> This dataset is released under the CC BY-NC 4.0 license

(See [chaochun/nlu-asdiv-dataset](https://github.com/chaochun/nlu-asdiv-dataset).)
ASDiv already lives in our [curriculum.md §7.4](../../../curriculum.md) as
*"ASDiv | CC-BY-NC 4.0 | Excluded (NC)"* — a deliberate prior decision.

MAWPS — the second of SVAMP's two upstream sources — has an *unclear*
licence (no LICENSE file in [sroy9/mawps](https://github.com/sroy9/mawps);
README is silent on licensing). Already marked Unclear/excluded in §7.4.

**Finding B — Derivation is paper-acknowledged but not surface-detectable.**
A name+number overlap heuristic across all 1000 SVAMP items vs. all 2305
ASDiv items (run during this audit) finds:

- **0/1000** SVAMP items with an exact body-text match in ASDiv.
- **73/1000** items sharing ≥1 proper noun and ≥2 numbers with some
  ASDiv item.
- **1/1000** items sharing ≥2 proper nouns and ≥2 numbers (a
  textbook "Reasoning Ability" variation:
  ASDiv `nluds-0737` "Ryan spends 4 hours on English and 3 hours on
  Chinese" → SVAMP `chal-717` "Ryan spends 3 hours on English and some
  more hours on Chinese, total 4").

Per the paper SVAMP applies substantial rewriting (renamed characters,
changed numbers, restructured bodies), which is exactly why the
surface-overlap signal is weak. **This means we cannot mechanically
identify and exclude the ASDiv-derived slice** — the entire dataset must
be treated as one provenance class, not partitioned into "clean" and
"NC-tainted" buckets.

**Finding C — CLAUDE.md / PRD posture is conservative by design.**
[CLAUDE.md](../../../CLAUDE.md) and [prd.md](../../../prd.md) make the
project's stance explicit: *"CC-BY-NC and CC-BY-NC-SA are excluded
because app-store distribution carries non-zero commercial-use risk."*
The legal question of whether SVAMP's variations are sufficiently
transformative to clear ASDiv's NC term is real and arguable; the project
chose not to take that gamble for other datasets and shouldn't take it
here.

**Net licence read:** SVAMP is *de jure* MIT but *de facto* downstream
of a CC-BY-NC source it openly declares. Conservative-posture projects
treat it as NC-tainted.

## 3. Marginal-value findings

If SVAMP's licence were clean, the second question is whether it adds
enough pedagogical value to be worth the ingestion work. Findings from
[svamp_samples.md](svamp_samples.md):

**Content shape:** 1000 items, all G2–G4 arithmetic word problems with
integer answers. Type distribution: Subtraction 53%, Addition 20%,
Division 17%, Multiplication 11%. ~76% have all operands ≤100 (clean K–4
scope); the rest spill into G4–G5 range.

**Equation shape:** ~76% single-operation; ~24% two-step (mostly
mixed-operation two-step, exactly the items that fit
`add_sub_2step_word_problems` and `mult_div_word_2step`).

**Sub-concept mapping** (if we were ingesting):

| SVAMP Type | Items | Target sub-concepts |
|---|---|---|
| Subtraction (1op, operands ≤100) | ~320 | `add_word_problems_within_100` (sub flavour) |
| Subtraction (2op) | ~127 | `add_sub_2step_word_problems` |
| Addition (1op, operands ≤100) | ~109 | `add_word_problems_within_100` |
| Addition (2op) | ~56 | `add_sub_2step_word_problems` |
| Multiplication (1op) | ~74 | `mult_compare_word`, `mult_div_word_2step` flavour 0 |
| Division (1op) | ~144 | `interpret_remainder_word` (when remainder), else `mult_div_word_2step` |
| Mixed 2op (mult/div) | ~50 | `mult_div_word_2step` |

**What we already have:**

- **Chunk 79's word-problem framework** generates parameterised
  contextualised add / sub / mult word problems with templated phrasing
  variants. The framework already targets `add_word_problems_within_100`,
  `add_sub_2step_word_problems`, `mult_compare_word`, and
  `mult_div_word_2step`. SVAMP doesn't unlock any sub-concept the
  framework can't already produce.
- **DeepMind `arithmetic.add_or_sub`** (ingested Chunk 80) adds 352
  phrasing-varied non-contextual arithmetic items — different niche from
  SVAMP (no body/question split) but covers the same +/− math.
- **GSM8K** (queued §7.2, MIT, no NC provenance) brings 8,500 grade
  3–6 word problems with rationales. ~9× SVAMP's size, MIT-clean,
  no upstream NC. **GSM8K substantially supersedes SVAMP's role.**

**Coverage-matrix impact** of dropping SVAMP (§7.5): SVAMP appears in
exactly one cell — *"OA, G4: DM(A), MDES(A), SV(A), GSM(A)"*. Three other
A-tier sources remain. No new gap opens.

**Grade-2 gap** (§7.6) is already noted as *not* filled by SVAMP
("SVAMP floor is grade 4"), so dropping doesn't widen it.

**The interesting-but-not-ingestible part:** SVAMP's three variation
families (Question Sensitivity, Reasoning Ability, Structural Invariance)
*are* pedagogically valuable — items where the body contains a
distractor number, or where naive keyword-matching gives the wrong
operation. Examples from the samples:

- `chal-74`: body mentions a subsequent purchase, question asks about
  leftovers — kids who keyword-match "bought more" → "+" get it wrong.
- `chal-371`: body mentions kids played with on Wednesday (96) but the
  question is "more on Monday than Tuesday?" — 96 is a distractor.

These *patterns* are valuable but the *items themselves* aren't
licence-clean, and the patterns can be replicated cheaply in our own
framework (a future Chunk 79-style extension could add "irrelevant number
in body" and "ask about a different operation than the body suggests"
variation flags).

## 4. Per-Type verdicts

All four Type buckets reduce to the same call. Listed here only to mirror
the per-submodule structure of [deepmind.md](deepmind.md).

| Type | Items | Verdict | Maps to | Notes |
|---|---|---|---|---|
| `Subtraction` | 531 | **drop** (licence) | `add_word_problems_within_100`, `add_sub_2step_word_problems` | Math covered by Chunk 79 framework + queued GSM8K. |
| `Addition` | 195 | **drop** (licence) | `add_word_problems_within_100`, `add_sub_2step_word_problems` | Same. |
| `Common-Division` | 165 | **drop** (licence) | `interpret_remainder_word`, `mult_div_word_2step` | Marginal coverage benefit (we have less div-word-problem variety than +/-), but doesn't change the licence-driven call. GSM8K queued for this slot. |
| `Multiplication` | 108 | **drop** (licence) | `mult_compare_word`, `mult_div_word_2step` | Math covered by Chunk 79 mult contexts (added Chunk 79). |
| `Common-Divison` (sic) | 1 | **drop** | — | Typo'd label on a single item; same call regardless. |

## 5. Recommendation

Following the convention established by Chunk 82's MD-ES audit (which
verdicted "skip dataset" but kept MD-ES on the §7.2 priority list and in
the §7.5 coverage matrix for traceability), the SVAMP changes are
intentionally minimal — verdict lives in §7.7, not by rewriting the
priority list:

1. **Flip §7.7** SVAMP row from *"not yet audited"* to *"audited
   2026-05-21 — dropped (licence)"*, linking to this document.
2. **Add a SVAMP TL;DR paragraph to §7.7** mirroring the MD-ES TL;DR
   that landed in Chunk 82.
3. **Leave §7.2 (priority list), §7.4 (other-evaluated), §7.5 (coverage
   matrix), §7.6 (gap callouts), and §10 (references) untouched.** SVAMP
   stays listed as a considered-but-rejected priority dataset rather than
   being scrubbed — same posture as MD-ES.
4. **No ingestion this chunk.** The "audit + ingest the safe slice"
   option becomes audit-only because no safe slice exists.
7. **(Future, separate work)** Consider replicating SVAMP's three
   variation families (Question Sensitivity, Reasoning Ability,
   Structural Invariance) inside our own Chunk 79 word-problem framework
   — the variation *patterns* are pedagogically valuable and can be
   produced licence-clean from our own seed pool. Out of scope for this
   audit chunk.

## 6. Side notes for future audits

- The same provenance scrutiny applied here should be carried over to the
  GSM8K audit: confirm GSM8K's MIT cleanness end-to-end (OpenAI 2021
  authorship, no derivative-of-NC inputs flagged in the paper or repo).
  Expected to be clean, but the audit should not skip the check.
- The same scrutiny applied to MathDataset-ES: it's MIT but aggregates
  from multiple upstreams; the per-row `source` field needs auditing for
  NC-tainted upstreams.
- For MathQA: Apache 2.0 (Allen AI), upstream is AQuA-RAT (Apache 2.0).
  Less licence risk but verify in audit.
