# tools/question_generation

Build-time tooling that ingests open-licensed math-question datasets and emits
bundled JSON under `assets/data/dataset_questions/`, one file per sub-concept.
The Dart runtime is wired up separately (see plan.md Phase 6 dataset
sub-track); these scripts only produce the data.

This is build-time-only tooling. The dependencies below are **not** required
to run or build the Flutter app — only to regenerate the bundled question
JSON.

## Setup

```sh
pip install -r tools/question_generation/requirements.txt
```

Note: the DeepMind `mathematics_dataset` package was last released in 2019 and
pins against pre-1.5 sympy. Newer sympy releases broke the import path for
`base_solution_linear`. `requirements.txt` pins `sympy<1.5` to keep the
package importable.

## Available ingesters

| Script | Source dataset | Module(s) | License |
|---|---|---|---|
| `ingest_deepmind_arithmetic.py` | DeepMind [`mathematics_dataset`](https://github.com/google-deepmind/mathematics_dataset) | `arithmetic.add_or_sub` | Apache 2.0 |
| `ingest_gsm8k.py` | [GSM8K](https://github.com/openai/grade-school-math) | `main` (4 sub-concept buckets — see audit) | MIT |

More modules and datasets will be added incrementally. See plan.md §
"Dataset ingestion sub-track" for the priority list.

Audit scripts (separate from ingestion — these emit per-dataset audit
reports under `audits/`, no JSON output):

| Script | Source dataset | License | Cache |
|---|---|---|---|
| `audit_gsm8k.py` | [GSM8K](https://github.com/openai/grade-school-math) (8792 items, main split) | MIT | `.cache/gsm8k/` (gitignored, re-downloadable) |

## Per-dataset audits

Before broad ingestion of a new dataset, an **audit** establishes per-submodule
verdicts (variety / gap-fill / out_of_scope / skip) by sampling real items and
mapping them to curriculum.md sub-concept IDs. The audit informs which slices
we ingest and which we skip — most submodules turn out to be either out of
K–8 scope or to add only phrasing variety on top of math we already generate
algorithmically.

Audit artifacts live under [`audits/`](audits/), one Markdown verdict per
dataset:

| Dataset | Audit script | Verdict |
|---|---|---|
| DeepMind | [audit_deepmind.py](audit_deepmind.py) | [audits/deepmind.md](audits/deepmind.md) |
| GSM8K | [audit_gsm8k.py](audit_gsm8k.py) | [audits/gsm8k.md](audits/gsm8k.md) |
| MathDataset-ES | [audit_md_es.py](audit_md_es.py) | [audits/md_es.md](audits/md_es.md) (verdict: **skip — redundant or license-blocked**) |
| MathQA | [audit_mathqa.py](audit_mathqa.py) | [audits/mathqa.md](audits/mathqa.md) — **skip** (content quality); narrow geometry slice deferred |
| SVAMP | [audit_svamp.py](audit_svamp.py) | [audits/svamp.md](audits/svamp.md) — **dropped** (CC-BY-NC derivation) |

**Pattern for adding a new dataset audit** (followed for DeepMind, reusable):

1. Write `audit_<dataset>.py` that enumerates the dataset's submodules /
   categories, samples ~5 representative items each, and emits a
   `audits/<dataset>_samples.md` file as a Markdown report.
   - Script accepts `--samples N`, `--seed S`, and `--filter <substring>`.
   - Output is deterministic per seed.
   - Pre-classification verdicts (italics next to each submodule name) are
     first-pass guesses; the hand-audit step refines them.
2. Run the script, capture output to `audits/<dataset>_samples.md`.
3. Hand-edit `audits/<dataset>.md` (the verdict document) around the samples
   — per-submodule row mapping to curriculum.md sub-concept IDs + verdict +
   notes on filtering work needed.
4. Roll up: which submodules are worth ingesting (sorted by ROI), what
   runtime support (new answer formats?) is required for the gap-fill
   candidates.
5. Update [`curriculum.md` §7.7](../../curriculum.md) — flip the dataset's
   audit row from "not yet audited" to "audited YYYY-MM-DD" and link to the
   verdict doc.
6. Update this README's audit table.
7. Only then is it worth writing an actual `ingest_<dataset>.py` against
   the highest-ROI submodules from the audit.

## Conventions

- **One JSON file per sub-concept**, at
  `assets/data/dataset_questions/<concept_id>.json`. The same file may be
  appended to by multiple ingesters across multiple datasets.
- **The schema** of each row:
  ```json
  {
    "id": "<dataset>_<module>_<sha1-of-prompt>",
    "concept_id": "add_within_20",
    "prompt": "What is 7 plus 9?",
    "correct_answer": "16",
    "distractors": ["15", "17", "8"],
    "explanation": ["7 + 9 = 16"],
    "source": "deepmind_mathematics_dataset",
    "source_module": "arithmetic.add_or_sub",
    "license": "Apache-2.0"
  }
  ```
  `explanation` is a list of 1–4 short step-by-step lines shown on the
  wrong-answer screen, matching the shape of `GeneratedQuestion.explanation`
  emitted by Dart algorithmic generators.
- **Per-sub-concept item cap** is `--items-per-concept` (default 200). When a
  bucket fills, additional items from that bucket are dropped.
- **Determinism**: each ingester takes a `--seed` so re-runs produce
  byte-identical JSON (subject to upstream library determinism, which DeepMind
  guarantees within a sympy version).
- **No runtime side effects**: scripts never touch the Drift database; they
  only write JSON. The runtime ingestion layer reads these files at app
  startup (see `lib/data/`).

## Attribution

Every dataset ingested is also attributed in [`LICENSES_THIRD_PARTY.md`](../../LICENSES_THIRD_PARTY.md) at the repo root.
