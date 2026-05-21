#!/usr/bin/env python3
"""Ingest GSM8K word problems into Math City JSON.

Bucket each item by candidate target sub-concept (using stricter
filters than the audit, per the per-bucket filter recipes in
``audits/gsm8k.md``), verify the math by evaluating every
``<<expr=result>>`` calculator annotation, generate three distractors
(intermediate-result + verbatim-input + jitter), and write one JSON
file per sub-concept under ``assets/data/dataset_questions/``.

Buckets ingested (per the audit's recommended ingestion order):

1. ``mult_div_word_2step`` — G4 multi-step ×/÷ word problems.
2. ``mult_compare_word`` — G4 multiplicative-comparison framings.
3. ``add_sub_2step_word_problems`` — G2 two-step ± word problems.
4. ``fraction_word_problems`` — G5 word problems with explicit
   fractions in the question text.

Buckets explicitly skipped (per the audit's verdict):

- ``add_word_problems_within_100`` (unfit — GSM8K has no true 1-step items)
- ``interpret_remainder_word`` (unfit — regex over-matches; "leftover" used colloquially)
- ``word_problem_two_step_eq`` (deferred — needs a sub-classifier to split 1-var-linear vs. system vs. percent)

Re-runs are deterministic for a given ``--seed`` value.
"""

from __future__ import annotations

import argparse
import ast
import hashlib
import json
import operator
import random
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Callable, Iterable

# Reuse feature extraction + JSONL caching from the audit script.
from audit_gsm8k import (
    ANN_RE,
    FINAL_RE,
    features,
    load_items,
)


REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = REPO_ROOT / "assets" / "data" / "dataset_questions"

SOURCE_NAME = "gsm8k"
SOURCE_MODULE = "main"  # single flat pool; "main" matches the HF config name
SOURCE_LICENSE = "MIT"


# ---------------------------------------------------------------------------
# Ingestion bucket detectors (stricter than audit_gsm8k.py's detectors —
# per the per-bucket filter recipes in audits/gsm8k.md).
# ---------------------------------------------------------------------------

def _is_add_sub_2step_word_problems(f: dict) -> bool:
    """G2: 2-step ± word problems. Per audit: keep audit filter as-is."""
    return (
        2 <= f["n_lines"] <= 3
        and 1 <= f["n_ann"] <= 2
        and f["ops"].issubset({"+", "-"}) and f["ops"]
        and f["final_is_int"]
        and not f["has_fraction_q"]
        and not f["has_decimal_step"]
        and not f["has_percent"]
        and not f["has_algebra_let"]
    )


def _is_mult_compare_word(f: dict) -> bool:
    """G4. Per audit: tighten to n_lines ≤ 4 vs. the audit's wider catch."""
    return (
        f["has_mult_compare"]
        and f["final_is_int"]
        and f["n_lines"] <= 4
        and not f["has_algebra_let"]
    )


def _is_mult_div_word_2step(f: dict) -> bool:
    """G4: multi-step × and/or ÷ word problems. Per audit: keep as-is."""
    return (
        2 <= f["n_lines"] <= 4
        and bool(f["ops"] & {"*", "/"})
        and f["final_is_int"]
        and not f["has_fraction_q"]
        and not f["has_percent"]
        and not f["has_algebra_let"]
    )


def _is_fraction_word_problems(f: dict) -> bool:
    """G5. Per audit: tighten to n_lines ≤ 4."""
    return (
        f["has_fraction_q"]
        and f["final_is_int"]
        and f["n_lines"] <= 4
        and not f["has_algebra_let"]
    )


# Match-priority order. First-match wins so the more specific buckets
# (mult_compare, fraction) come before the broader mult_div / add_sub.
BUCKETS: list[tuple[str, str, Callable[[dict], bool]]] = [
    ("mult_compare_word", "mc", _is_mult_compare_word),
    ("fraction_word_problems", "fr", _is_fraction_word_problems),
    ("add_sub_2step_word_problems", "as", _is_add_sub_2step_word_problems),
    ("mult_div_word_2step", "md", _is_mult_div_word_2step),
]


def classify(f: dict) -> tuple[str, str] | None:
    for bucket_id, short, detector in BUCKETS:
        if detector(f):
            return bucket_id, short
    return None


# ---------------------------------------------------------------------------
# Math verification — safely evaluate <<expr=result>> annotations.
# ---------------------------------------------------------------------------

_AST_BINOPS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.FloorDiv: operator.floordiv,
    ast.Mod: operator.mod,
    ast.Pow: operator.pow,
}
_AST_UNARYOPS = {
    ast.UAdd: operator.pos,
    ast.USub: operator.neg,
}


def safe_eval(expr: str) -> float | None:
    """Evaluate a pure-arithmetic expression. Returns None on parse / op error.

    Accepts +, -, *, /, //, %, **, parens, integer / float literals, and
    unary +/-. Rejects everything else (names, function calls, attribute
    access, etc.) — important because GSM8K annotations are user-authored.
    """
    try:
        tree = ast.parse(expr, mode="eval")
    except SyntaxError:
        return None

    def _walk(node):
        if isinstance(node, ast.Expression):
            return _walk(node.body)
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
            return node.value
        if isinstance(node, ast.BinOp) and type(node.op) in _AST_BINOPS:
            left = _walk(node.left)
            right = _walk(node.right)
            if left is None or right is None:
                return None
            try:
                return _AST_BINOPS[type(node.op)](left, right)
            except (ZeroDivisionError, OverflowError):
                return None
        if isinstance(node, ast.UnaryOp) and type(node.op) in _AST_UNARYOPS:
            v = _walk(node.operand)
            return _AST_UNARYOPS[type(node.op)](v) if v is not None else None
        return None

    try:
        return _walk(tree)
    except RecursionError:
        return None


def verify_annotations(answer: str) -> list[float] | None:
    """Return the parsed result values from every annotation, or None if any
    annotation fails arithmetic verification.

    Verification: for each ``<<expr=result>>``, ``safe_eval(expr)`` must equal
    ``float(result)`` within a small epsilon.
    """
    results: list[float] = []
    for expr, result_str in ANN_RE.findall(answer):
        computed = safe_eval(expr.strip())
        if computed is None:
            return None
        try:
            stated = float(result_str.replace(",", "").strip())
        except ValueError:
            return None
        if abs(computed - stated) > 1e-6:
            return None
        results.append(stated)
    return results


# ---------------------------------------------------------------------------
# Distractor generation
# ---------------------------------------------------------------------------

INT_RE = re.compile(r"\b\d+\b")
JITTER_OFFSETS = (-2, -1, 1, 2, -5, 5, -3, 3)
ANN_STRIP_RE = re.compile(r"<<[^>]*>>")
FINAL_LINE_RE = re.compile(r"^####.*$", re.MULTILINE)


def extract_explanation(answer: str) -> list[str]:
    """Turn a GSM8K rationale into 1–4 short explanation lines.

    Strips ``<<expr=result>>`` markup and the ``#### N`` terminator, then
    collapses to non-blank lines. Caps at 4 lines per the runtime contract
    in `database.dart` (`/// JSON-encoded List<String> of 1–4 explanation
    lines.`); longer rationales get the trailing lines folded into the last
    visible line so no information is lost.
    """
    cleaned = ANN_STRIP_RE.sub("", answer)
    cleaned = FINAL_LINE_RE.sub("", cleaned)
    lines = [ln.strip() for ln in cleaned.split("\n") if ln.strip()]
    if len(lines) <= 4:
        return lines
    head = lines[:3]
    tail = " ".join(lines[3:])
    return [*head, tail]


def extract_question_integers(question: str) -> list[int]:
    """Pull positive integers from the question text."""
    return [int(m.group()) for m in INT_RE.finditer(question)]


def make_distractors(
    correct: int,
    intermediates: list[int],
    inputs: list[int],
    rand: random.Random,
) -> list[str]:
    """Return three distinct positive-integer distractors.

    Composition (per audit recommendation):
    - one intermediate-result distractor (the "stopped early" mistake)
    - one verbatim-input distractor (the "didn't compute, copied a number" mistake)
    - one ±-jitter distractor as filler

    Falls back across pools when a category is empty / collides.
    """
    def _clean(pool: Iterable[int], taken: set[int]) -> list[int]:
        return [
            n for n in dict.fromkeys(pool)  # de-dup preserving order
            if n > 0 and n != correct and n not in taken
        ]

    chosen: list[int] = []
    taken: set[int] = {correct}

    inter_pool = _clean(intermediates, taken)
    if inter_pool:
        pick = rand.choice(inter_pool)
        chosen.append(pick)
        taken.add(pick)

    input_pool = _clean(inputs, taken)
    if input_pool:
        pick = rand.choice(input_pool)
        chosen.append(pick)
        taken.add(pick)

    # Jitter pool, then any remaining pool members, as backstop.
    jitter_pool = _clean(
        (correct + off for off in JITTER_OFFSETS), taken
    )
    if jitter_pool:
        pick = rand.choice(jitter_pool)
        chosen.append(pick)
        taken.add(pick)

    # If any slot is still empty (rare — only when intermediates + inputs + jitter
    # all collide), keep widening the jitter range.
    fallback_offset = 6
    while len(chosen) < 3 and fallback_offset < 200:
        cand = correct + fallback_offset
        if cand > 0 and cand not in taken:
            chosen.append(cand)
            taken.add(cand)
        cand = correct - fallback_offset
        if cand > 0 and cand not in taken:
            chosen.append(cand)
            taken.add(cand)
        fallback_offset += 1

    rand.shuffle(chosen)
    return [str(n) for n in chosen[:3]]


# ---------------------------------------------------------------------------
# Ingestion driver
# ---------------------------------------------------------------------------

def item_id(question: str, bucket_short: str) -> str:
    digest = hashlib.sha1(question.encode("utf-8")).hexdigest()[:10]
    return f"{SOURCE_NAME}_{bucket_short}_{digest}"


def ingest(
    items_per_concept: int,
    seed: int,
    output_dir: Path,
    dry_run: bool,
) -> dict:
    rand = random.Random(seed)
    raw = load_items()
    # Deterministic shuffle so the per-bucket cap takes a representative
    # slice rather than the first N items.
    rand.shuffle(raw)

    buckets: dict[str, list[dict]] = defaultdict(list)
    stats = {
        "considered": 0,
        "rejected_no_bucket": 0,
        "rejected_no_annotations": 0,
        "rejected_math_failed": 0,
        "rejected_distractor_short": 0,
        "rejected_duplicate": 0,
        "accepted": 0,
        "bucket_full_skips": 0,
    }
    seen_questions: set[str] = set()

    for item in raw:
        stats["considered"] += 1
        question = item["question"]
        answer = item["answer"]

        f = features(item)
        cls = classify(f)
        if cls is None:
            stats["rejected_no_bucket"] += 1
            continue
        bucket_id, bucket_short = cls

        if len(buckets[bucket_id]) >= items_per_concept:
            stats["bucket_full_skips"] += 1
            continue

        # Drop items without annotations — we can't verify their math.
        if f["n_ann"] == 0:
            stats["rejected_no_annotations"] += 1
            continue

        intermediate_floats = verify_annotations(answer)
        if intermediate_floats is None:
            stats["rejected_math_failed"] += 1
            continue

        # Final answer is the integer parsed from `#### N`.
        correct = int(f["final_val"])

        # Drop the final-annotation result if it equals the correct answer
        # (typical — the last `<<...>>` IS the final computation). Keep
        # earlier intermediates as "stopped-early" distractor candidates.
        intermediates = [
            int(v) for v in intermediate_floats
            if v == int(v) and int(v) > 0 and int(v) != correct
        ]

        inputs = [n for n in extract_question_integers(question) if n != correct]

        distractors = make_distractors(correct, intermediates, inputs, rand)
        if len(distractors) < 3:
            stats["rejected_distractor_short"] += 1
            continue

        if question in seen_questions:
            stats["rejected_duplicate"] += 1
            continue
        seen_questions.add(question)

        out_item = {
            "id": item_id(question, bucket_short),
            "concept_id": bucket_id,
            "prompt": question,
            "correct_answer": str(correct),
            "distractors": distractors,
            "explanation": extract_explanation(answer),
            "source": SOURCE_NAME,
            "source_module": SOURCE_MODULE,
            "license": SOURCE_LICENSE,
        }
        buckets[bucket_id].append(out_item)
        stats["accepted"] += 1

    summary = {cid: len(items) for cid, items in sorted(buckets.items())}
    summary["__stats__"] = stats

    if dry_run:
        return summary

    output_dir.mkdir(parents=True, exist_ok=True)
    for bucket_id, items in buckets.items():
        items_sorted = sorted(items, key=lambda x: x["id"])
        existing = []
        path = output_dir / f"{bucket_id}.json"
        if path.exists():
            existing = json.loads(path.read_text())["items"]
            # Drop any prior GSM8K rows so re-runs are idempotent. Other
            # ingesters' rows (DeepMind, etc.) survive untouched.
            existing = [r for r in existing if r.get("source") != SOURCE_NAME]
        merged = sorted(existing + items_sorted, key=lambda x: x["id"])
        path.write_text(
            json.dumps({"items": merged}, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--items-per-concept",
        type=int,
        default=300,
        help="Per-sub-concept cap on items in the output JSON. Default 300.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=20260521,
        help="RNG seed (default: 20260521).",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=OUTPUT_DIR,
        help="Where to write per-sub-concept JSON files.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the per-bucket summary without writing JSON.",
    )
    args = parser.parse_args()

    summary = ingest(
        items_per_concept=args.items_per_concept,
        seed=args.seed,
        output_dir=args.output_dir,
        dry_run=args.dry_run,
    )
    stats = summary.pop("__stats__")
    print("=== Per-bucket yield ===", file=sys.stderr)
    for cid, n in summary.items():
        print(f"  {cid:36s} {n:4d}", file=sys.stderr)
    print(file=sys.stderr)
    print("=== Stats ===", file=sys.stderr)
    for k, v in stats.items():
        print(f"  {k:30s} {v}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
