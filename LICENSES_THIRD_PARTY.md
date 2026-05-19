# Third-party content licensing

Math City is a free, open project (see [prd.md](prd.md)) and depends on a
small number of open-licensed third-party assets and datasets. This file is
the authoritative attribution log; every dataset, font, image, or audio
asset shipped in the app must be listed here.

Per [curriculum.md §7.1](curriculum.md), the only licences we accept for
bundled third-party content are MIT, Apache 2.0, CC-BY (4.0), and CC0.
CC-BY-NC, CC-BY-NC-SA, and unclear-provenance content are excluded.

---

## Question datasets

### DeepMind `mathematics_dataset` (Apache 2.0)

- **Project:** [google-deepmind/mathematics_dataset](https://github.com/google-deepmind/mathematics_dataset)
- **Authors:** David Saxton, Edward Grefenstette, Felix Hill, Pushmeet Kohli (DeepMind)
- **Reference:** Saxton et al., 2019, *Analysing Mathematical Reasoning Abilities of Neural Models* ([arXiv:1904.01557](https://arxiv.org/abs/1904.01557))
- **Licence:** Apache License, Version 2.0
- **Used in:** `assets/data/dataset_questions/*.json` — items with `"source": "deepmind_mathematics_dataset"`
- **Ingestion tooling:** [tools/question_generation/ingest_deepmind_arithmetic.py](tools/question_generation/ingest_deepmind_arithmetic.py)
- **Modules ingested:** `arithmetic.add_or_sub`
- **Notes:** Each item is a freshly procedurally-generated question from the
  upstream Python package — we do not bundle any verbatim file from the
  upstream repo. The Math City ingester filters items to the K–8
  non-negative-integer subset, sub-concept-tags them by operand magnitude,
  and adds three multiple-choice distractors (Math City's own work, not
  DeepMind's). All transformations preserve attribution to the upstream
  source in the per-item `source` and `source_module` JSON fields.

---

## Code dependencies

Code dependencies (Flutter packages, Dart packages, Python build-time
tooling) are tracked in [pubspec.yaml](pubspec.yaml) and
[tools/question_generation/requirements.txt](tools/question_generation/requirements.txt).
Per-package licences are surfaced by `flutter pub deps` and `pip show`.
This file lists only third-party *content* (datasets, assets) shipped to
end users.
