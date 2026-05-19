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

More modules and datasets will be added incrementally. See plan.md §
"Dataset ingestion sub-track" for the priority list.

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
    "source": "deepmind_mathematics_dataset",
    "source_module": "arithmetic.add_or_sub",
    "license": "Apache-2.0"
  }
  ```
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
