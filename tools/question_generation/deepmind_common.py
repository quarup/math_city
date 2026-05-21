"""Shared helpers for DeepMind mathematics_dataset ingesters.

Each per-submodule ingester (`ingest_deepmind_numbers.py`,
`ingest_deepmind_measurement.py`, `ingest_deepmind_arithmetic_mul.py`)
imports from here. Centralises:

- Item-ID hashing
- The distractor-generation pattern (jitter + misconception)
- Idempotent per-source JSON merge (re-runs replace only this source's rows;
  other ingesters' rows in the same file survive)
- The output schema + writer

The first DeepMind ingester (`ingest_deepmind_arithmetic.py`, Chunk 80)
predates this module and has its own inlined versions of these helpers
— left untouched to avoid touching shipping JSON.
"""

from __future__ import annotations

import hashlib
import json
import random
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = REPO_ROOT / "assets" / "data" / "dataset_questions"

SOURCE_NAME = "deepmind_mathematics_dataset"
SOURCE_LICENSE = "Apache-2.0"


def item_id(prompt: str, *, prefix: str) -> str:
    """Stable per-item ID. ``prefix`` should disambiguate ingesters.

    e.g. ``arith_mul`` for arithmetic.mul, ``pv`` for numbers.place_value.
    """
    digest = hashlib.sha1(prompt.encode("utf-8")).hexdigest()[:10]
    return f"{SOURCE_NAME}_{prefix}_{digest}"


# ---------------------------------------------------------------------------
# Distractors
# ---------------------------------------------------------------------------

def jitter_distractors(correct: int, rand: random.Random) -> list[int]:
    """Three distinct non-negative integers near ``correct``.

    Mirrors Dart's ``integerDistractorsWith`` filler logic.
    """
    candidates: set[int] = {correct + 1}
    if correct - 1 >= 0:
        candidates.add(correct - 1)
    for _ in range(40):
        if len(candidates) >= 8:
            break
        offset = rand.randint(1, 5)
        sign = rand.choice((-1, 1))
        v = correct + sign * offset
        if v >= 0:
            candidates.add(v)
    candidates.discard(correct)
    fallback = 0
    while len(candidates) < 3:
        if fallback != correct:
            candidates.add(fallback)
        fallback += 1
    out = sorted(candidates)
    rand.shuffle(out)
    return out[:3]


def integer_distractors_with(
    correct: int,
    misconception: int | None,
    rand: random.Random,
) -> list[str]:
    """Three distinct non-negative integer-string distractors with one
    optional forced misconception value. Mirrors Dart's
    ``integerDistractorsWith``.
    """
    base = jitter_distractors(correct, rand)
    if misconception is None or misconception < 0 or misconception == correct:
        return [str(n) for n in base]
    rest = [n for n in base if n != misconception][:2]
    while len(rest) < 2:
        for n in jitter_distractors(correct, rand):
            if n != misconception and n not in rest:
                rest.append(n)
                if len(rest) == 2:
                    break
    result = [misconception, *rest]
    rand.shuffle(result)
    return [str(n) for n in result]


# ---------------------------------------------------------------------------
# Output writer with idempotent per-source merge
# ---------------------------------------------------------------------------

def write_buckets(
    buckets: dict[str, list[dict]],
    *,
    source_module: str,
    output_dir: Path = OUTPUT_DIR,
    dry_run: bool = False,
) -> None:
    """Write per-concept JSON files, replacing only this ingester's rows.

    Re-runs are idempotent: existing rows whose ``source_module`` matches
    ours are dropped before re-merging. Rows from other ingesters (or other
    DeepMind submodules) in the same file survive untouched.
    """
    if dry_run:
        return
    output_dir.mkdir(parents=True, exist_ok=True)
    for concept_id, items in buckets.items():
        items_sorted = sorted(items, key=lambda x: x["id"])
        path = output_dir / f"{concept_id}.json"
        existing: list[dict] = []
        if path.exists():
            existing = json.loads(path.read_text())["items"]
            existing = [
                r for r in existing
                if not (
                    r.get("source") == SOURCE_NAME
                    and r.get("source_module") == source_module
                )
            ]
        merged = sorted(existing + items_sorted, key=lambda x: x["id"])
        path.write_text(
            json.dumps({"items": merged}, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )


def build_item(
    *,
    id: str,
    concept_id: str,
    prompt: str,
    correct_answer: str,
    distractors: list[str],
    explanation: list[str],
    source_module: str,
) -> dict:
    """Build a row matching the dataset_questions JSON schema."""
    return {
        "id": id,
        "concept_id": concept_id,
        "prompt": prompt,
        "correct_answer": correct_answer,
        "distractors": distractors,
        "explanation": explanation,
        "source": SOURCE_NAME,
        "source_module": source_module,
        "license": SOURCE_LICENSE,
    }
