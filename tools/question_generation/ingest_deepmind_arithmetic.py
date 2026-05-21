#!/usr/bin/env python3
"""Ingest DeepMind mathematics_dataset arithmetic items into Math City JSON.

Drives the upstream ``arithmetic.add_or_sub`` generator, parses each item's
question text to recover operands and operation, verifies the math, tags to
a Math City sub-concept by operand magnitude, generates three distractors,
and writes one JSON file per sub-concept under
``assets/data/dataset_questions/``.

Re-runs are deterministic for a given ``--seed`` value (subject to upstream
library determinism, which DeepMind guarantees within a sympy version).

This is the first ingester in the dataset-ingestion sub-track; it only covers
``arithmetic.add_or_sub`` from DeepMind. More submodules and other datasets
will land in follow-up chunks (see plan.md "Dataset ingestion sub-track").
"""

from __future__ import annotations

import argparse
import hashlib
import json
import random
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Optional

# DeepMind imports are deferred to main() so --help works without the deps
# installed.


REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = REPO_ROOT / "assets" / "data" / "dataset_questions"

SOURCE_NAME = "deepmind_mathematics_dataset"
SOURCE_MODULE = "arithmetic.add_or_sub"
SOURCE_LICENSE = "Apache-2.0"

# Words that distinguish add vs sub in DeepMind's templates. Order matters
# only insofar as we check add and sub sets and require exactly one hit.
ADD_WORDS = (
    "plus",
    "Add ",
    "Sum ",
    "Put together",
    "Total of",
    "Add together",
    "add together",
)
SUB_WORDS = (
    "minus",
    "take away",
    "less than",
    "Subtract ",
    "subtract ",
    "distance between",
    "difference between",
)


def detect_operation(prompt: str) -> Optional[str]:
    """Return 'add' / 'sub' based on prompt phrasing, or None if ambiguous.

    Falls back to operator-character detection when no operation word is
    present (e.g. the bare ``{p} + {q}`` and ``{p}-{q}`` templates).
    """
    p = prompt
    add_word = any(w in p for w in ADD_WORDS)
    sub_word = any(w in p for w in SUB_WORDS)
    if add_word and not sub_word:
        return "add"
    if sub_word and not add_word:
        return "sub"
    if add_word and sub_word:
        return None
    # No textual signal — disambiguate by operator character.
    # No sub template uses '+', and no add template has space-minus-space.
    has_plus = "+" in p
    has_spaced_minus = " - " in p
    if has_plus and not has_spaced_minus:
        return "add"
    if has_spaced_minus and not has_plus:
        return "sub"
    return None


# Captures all integers (no decimals) in the prompt. DeepMind uses ASCII '-'
# for both negation and subtraction. We require exactly two integer tokens —
# decimal items (e.g. ``0.79 + 55935``) fail this and are dropped.
INT_RE = re.compile(r"-?\d+")
HAS_DECIMAL_RE = re.compile(r"\d\.\d")


def extract_two_operands(prompt: str) -> Optional[tuple[int, int]]:
    matches = INT_RE.findall(prompt)
    if len(matches) != 2:
        return None
    return int(matches[0]), int(matches[1])


def verify_and_orient(
    a: int, b: int, op: str, answer: int
) -> Optional[tuple[int, int]]:
    """Verify the math and return the (operand1, operand2) order that makes
    ``operand1 op operand2 == answer``.

    Sub templates have two possible regex orderings — DeepMind's
    ``Subtract {q} from {p}``, ``{q} less than {p}``, and
    ``{distance|difference} between {q} and {p}`` reverse the textual
    order relative to the math. Try both orderings and accept whichever
    verifies.
    """
    if op == "add":
        if a + b == answer:
            return (a, b)
        return None
    # op == 'sub'
    if a - b == answer:
        return (a, b)
    if b - a == answer:
        return (b, a)
    return None


# Tagging order matters: tightest bucket first. The first match wins.
#
# Each row: (concept_id, op, predicate). Predicate is a closure over
# (a, b, result) — all already known to be non-negative.
TAG_TABLE = [
    # K
    ("add_within_5", "add", lambda a, b, r: a <= 5 and b <= 5 and r <= 5),
    ("sub_within_5", "sub", lambda a, b, r: a <= 5 and b <= 5 and r <= 5),
    # G1
    ("add_within_10", "add", lambda a, b, r: a <= 10 and b <= 10 and r <= 10),
    ("sub_within_10", "sub", lambda a, b, r: a <= 10 and b <= 10 and r <= 10),
    ("add_within_20", "add", lambda a, b, r: a <= 20 and b <= 20 and r <= 20),
    ("sub_within_20", "sub", lambda a, b, r: a <= 20 and b <= 20 and r <= 20),
    # G2 — 2-digit work.
    (
        "add_2digit_carry",
        "add",
        lambda a, b, r: 10 <= a <= 99
        and 10 <= b <= 99
        and r <= 100
        and (a % 10) + (b % 10) >= 10,  # ones-place carry => regroup
    ),
    (
        "sub_2digit_borrow",
        "sub",
        lambda a, b, r: 10 <= a <= 99 and 10 <= b <= 99 and (a % 10) < (b % 10),
    ),
    ("add_within_100", "add", lambda a, b, r: r <= 100 and a <= 99 and b <= 99),
    ("sub_within_100", "sub", lambda a, b, r: a <= 99 and b <= 99 and r <= 99),
    # G2 — 3-digit work.
    (
        "add_within_1000",
        "add",
        lambda a, b, r: r <= 1000 and a <= 999 and b <= 999,
    ),
    (
        "sub_within_1000",
        "sub",
        lambda a, b, r: a <= 999 and b <= 999 and r <= 999,
    ),
]


def tag_concept(a: int, b: int, op: str, result: int) -> Optional[str]:
    """Return the tightest matching sub-concept ID, or None if out of K-2 add/sub scope."""
    for concept_id, expected_op, pred in TAG_TABLE:
        if expected_op == op and pred(a, b, result):
            return concept_id
    return None


def _jitter_distractors(correct: int, rand: random.Random) -> list[int]:
    """Return three distinct non-negative integers near ``correct``."""
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


def make_distractors(
    correct: int,
    misconception: int,
    rand: random.Random,
) -> list[str]:
    """Return three distinct non-negative integer-string distractors.

    Mirrors lib/domain/questions/distractors.dart `integerDistractorsWith`:
    the misconception (opposite-operation result) is forced into the slate
    when it's a valid candidate; the remaining two come from a ±5 jitter
    around ``correct``. The result is shuffled so the misconception's
    position varies.
    """
    base = _jitter_distractors(correct, rand)
    if misconception < 0 or misconception == correct:
        return [str(n) for n in base]
    rest = [n for n in base if n != misconception][:2]
    while len(rest) < 2:
        for n in _jitter_distractors(correct, rand):
            if n != misconception and n not in rest:
                rest.append(n)
                if len(rest) == 2:
                    break
    result = [misconception, *rest]
    rand.shuffle(result)
    return [str(n) for n in result]


def normalize_prompt(prompt: str) -> str:
    """Replace ASCII minus with the typographic U+2212 only when used as
    subtraction or negation, matching what the rest of the app shows kids.

    DeepMind uses ASCII '-' for both. The regex below targets the cases
    relevant to add_or_sub: negatives like ``-7`` and binary subtraction
    like ``a - b``. Both are safe to map to U+2212.
    """
    out = re.sub(r"(?<![\w-])-(?=\d)", "−", prompt)  # negation
    out = out.replace(" - ", " − ")  # binary subtraction
    return out


def item_id(prompt: str) -> str:
    digest = hashlib.sha1(prompt.encode("utf-8")).hexdigest()[:10]
    return f"{SOURCE_NAME}_arith_{digest}"


def ingest(
    items_per_concept: int,
    seed: int,
    max_attempts: int,
    output_dir: Path,
    dry_run: bool,
) -> dict:
    """Generate items until each bucket is full or attempts run out.

    Returns a dict {concept_id: count} summarizing the ingestion.
    """
    # Import here so --help works without deps.
    from mathematics_dataset.modules import arithmetic

    # Drive DeepMind at the full standard entropy range (3..10 chars). This
    # gives a wide mix of magnitudes which is exactly what we want — we
    # filter by magnitude in tag_concept() to bucket them, and drop the
    # ones that fall outside K-8 add/sub scope.
    def entropy_fn(range_):
        return range_

    submodules = arithmetic.train(entropy_fn)
    add_or_sub = submodules["add_or_sub"]

    rand = random.Random(seed)
    # DeepMind uses the global `random` module internally; seed it too for
    # reproducibility.
    random.seed(seed)

    buckets: dict[str, list[dict]] = defaultdict(list)
    seen_prompts: set[str] = set()
    attempts = 0
    accepted = 0
    rejected_decimal = 0
    rejected_negative = 0
    rejected_op = 0
    rejected_operands = 0
    rejected_verify = 0
    rejected_no_concept = 0
    rejected_duplicate = 0

    target_total = items_per_concept * sum(1 for _ in TAG_TABLE)

    while accepted < target_total and attempts < max_attempts:
        attempts += 1
        ex = add_or_sub()
        prompt_raw = str(ex.question)
        answer_str = str(ex.answer)

        # Decimal items are out of scope for this ingester (G5 decimals would
        # be a separate sub-concept track).
        if HAS_DECIMAL_RE.search(prompt_raw) or "." in answer_str:
            rejected_decimal += 1
            continue

        try:
            answer = int(answer_str)
        except ValueError:
            rejected_decimal += 1
            continue

        op = detect_operation(prompt_raw)
        if op is None:
            rejected_op += 1
            continue

        operands = extract_two_operands(prompt_raw)
        if operands is None:
            rejected_operands += 1
            continue

        oriented = verify_and_orient(operands[0], operands[1], op, answer)
        if oriented is None:
            rejected_verify += 1
            continue
        a, b = oriented

        # K-8 add/sub scope: non-negative everywhere.
        if a < 0 or b < 0 or answer < 0:
            rejected_negative += 1
            continue

        concept_id = tag_concept(a, b, op, answer)
        if concept_id is None:
            rejected_no_concept += 1
            continue

        if len(buckets[concept_id]) >= items_per_concept:
            continue

        if prompt_raw in seen_prompts:
            rejected_duplicate += 1
            continue
        seen_prompts.add(prompt_raw)

        misconception = a - b if op == "add" else a + b
        distractors = make_distractors(answer, misconception, rand)

        # One-line step-by-step shown on the wrong-answer screen. Mirrors
        # the format the Dart algorithmic generators emit so the kid sees a
        # consistent post-mortem regardless of which side produced the
        # item. U+2212 minus for sub, matching normalize_prompt().
        op_symbol = "+" if op == "add" else "−"
        explanation = [f"{a} {op_symbol} {b} = {answer}"]

        item = {
            "id": item_id(prompt_raw),
            "concept_id": concept_id,
            "prompt": normalize_prompt(prompt_raw),
            "correct_answer": str(answer),
            "distractors": distractors,
            "explanation": explanation,
            "source": SOURCE_NAME,
            "source_module": SOURCE_MODULE,
            "license": SOURCE_LICENSE,
        }
        buckets[concept_id].append(item)
        accepted += 1

    summary = {cid: len(items) for cid, items in sorted(buckets.items())}
    summary["__stats__"] = {
        "attempts": attempts,
        "accepted": accepted,
        "rejected_decimal": rejected_decimal,
        "rejected_op_detect": rejected_op,
        "rejected_operands_extract": rejected_operands,
        "rejected_verify": rejected_verify,
        "rejected_negative": rejected_negative,
        "rejected_no_concept": rejected_no_concept,
        "rejected_duplicate": rejected_duplicate,
    }

    if dry_run:
        return summary

    output_dir.mkdir(parents=True, exist_ok=True)
    for concept_id, items in buckets.items():
        items_sorted = sorted(items, key=lambda x: x["id"])
        path = output_dir / f"{concept_id}.json"
        path.write_text(
            json.dumps({"items": items_sorted}, indent=2, ensure_ascii=False)
            + "\n",
            encoding="utf-8",
        )

    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--items-per-concept",
        type=int,
        default=200,
        help="Per-sub-concept cap on items in the output JSON. Default 200.",
    )
    parser.add_argument("--seed", type=int, default=20260519, help="RNG seed.")
    parser.add_argument(
        "--max-attempts",
        type=int,
        default=500_000,
        help="Hard stop on DeepMind generator calls (default 500k). With "
        "the default seed and 200-item cap we converge in ~50k calls.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the per-concept counts + rejection stats; don't write files.",
    )
    args = parser.parse_args()

    summary = ingest(
        items_per_concept=args.items_per_concept,
        seed=args.seed,
        max_attempts=args.max_attempts,
        output_dir=OUTPUT_DIR,
        dry_run=args.dry_run,
    )

    stats = summary.pop("__stats__")
    print("Per-concept counts:")
    for cid, count in sorted(summary.items()):
        print(f"  {cid}: {count}")
    print()
    print(f"Stats: {stats}")
    if not args.dry_run:
        print(f"Wrote {len(summary)} files to {OUTPUT_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
