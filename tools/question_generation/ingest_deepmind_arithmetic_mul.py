#!/usr/bin/env python3
"""Ingest DeepMind `arithmetic.mul` items into Math City JSON.

Maps to the multiplication-fact family per audit's rank #3.

Filters applied:
- Both operands must be positive integers (no negatives, no decimals).
- Answer must be a positive integer.
- Operand magnitudes restricted to the curriculum's K-G5 range.

Tagging order (tightest bucket first):

- both ≤ 9 → `mult_facts_within_100` (G3)
- one ≤ 9 + multiple of 10 → `mult_1digit_by_multiple_of_10` (G3)
- 1-digit × 4-digit → `mult_4digit_by_1digit` (G4)
- 2-digit × 2-digit, answer ≤ 9999 → `mult_2digit_by_2digit` (G4)
- bigger → `mult_multidigit_standard_alg` (G5)

DeepMind templates: bare "{a} * {b}" / "{a}*{b}", word forms
"Multiply A and B.", "Product of A and B.", "What is A times B?",
"What is the product of A and B?", "Calculate A*B.", "Work out A * B.",
"A times B".
"""

from __future__ import annotations

import argparse
import random
import re
import sys
from collections import defaultdict
from pathlib import Path

from deepmind_common import (
    build_item,
    integer_distractors_with,
    item_id,
    write_buckets,
)

MODULE = "arithmetic.mul"


# Extracts all integers (no decimals) from the prompt. Decimal items
# (e.g. "Multiply -0.5 and 40.4.") fail this and are dropped — the
# decimal point breaks the regex's word boundary.
INT_RE = re.compile(r"(?<!\.)(?<!\d)(-?\d+)(?!\.\d)")
HAS_DECIMAL_RE = re.compile(r"\d\.\d")


def extract_two_operands(prompt: str) -> tuple[int, int] | None:
    if HAS_DECIMAL_RE.search(prompt):
        return None
    matches = INT_RE.findall(prompt)
    if len(matches) != 2:
        return None
    try:
        return int(matches[0]), int(matches[1])
    except ValueError:
        return None


def tag_concept(a: int, b: int, answer: int) -> str | None:
    """Pick the tightest matching bucket, or None if out of K-G5 mult scope.

    Order: tightest concept first. We want 1-digit × 1-digit to land in
    ``mult_facts_within_100``, not ``mult_2digit_by_2digit``.
    """
    if a <= 0 or b <= 0 or answer <= 0:
        return None
    # G3 facts: both single-digit, answer ≤ 100.
    if a <= 9 and b <= 9 and answer <= 100:
        return "mult_facts_within_100"
    # G3 1-digit × multiple of 10. Detect by one operand being a single
    # digit and the other being a 2-digit multiple of 10.
    def _one_digit_x_multiple_of_10(x: int, y: int) -> bool:
        return 1 <= x <= 9 and 10 <= y <= 90 and y % 10 == 0
    if _one_digit_x_multiple_of_10(a, b) or _one_digit_x_multiple_of_10(b, a):
        return "mult_1digit_by_multiple_of_10"
    # G4 4-digit × 1-digit: detect by one operand being single-digit and
    # the other being in [10, 9999].
    if (a <= 9 and 10 <= b <= 9999) or (b <= 9 and 10 <= a <= 9999):
        return "mult_4digit_by_1digit"
    # G4 2-digit × 2-digit.
    if 10 <= a <= 99 and 10 <= b <= 99:
        return "mult_2digit_by_2digit"
    # G5 multi-digit × multi-digit. Cap to keep answers grokable.
    if a <= 9999 and b <= 9999 and answer <= 100_000_000:
        return "mult_multidigit_standard_alg"
    return None


def ingest_mul(
    n_target: int,
    rand: random.Random,
) -> tuple[dict[str, list[dict]], dict[str, int]]:
    from mathematics_dataset.modules import arithmetic

    def entropy_fn(r):
        return r

    gen = arithmetic.train(entropy_fn)["mul"]

    buckets: dict[str, list[dict]] = defaultdict(list)
    stats = defaultdict(int)
    seen_prompts: set[str] = set()
    attempts = 0
    # 5 target concepts; budget generously since most DeepMind mul items
    # are decimal / negative / huge and get filtered out.
    target_total = n_target * 5
    max_attempts = max(target_total * 200, 200_000)

    while sum(len(v) for v in buckets.values()) < target_total and attempts < max_attempts:
        attempts += 1
        ex = gen()
        prompt = str(ex.question)
        answer_str = str(ex.answer)

        # Drop decimal answers.
        if "." in answer_str:
            stats["rejected_decimal_answer"] += 1
            continue
        # Drop negatives.
        try:
            answer = int(answer_str)
        except ValueError:
            stats["rejected_non_int_answer"] += 1
            continue
        if answer <= 0:
            stats["rejected_non_positive_answer"] += 1
            continue

        operands = extract_two_operands(prompt)
        if operands is None:
            stats["rejected_operand_parse"] += 1
            continue
        a, b = operands
        if a * b != answer:
            stats["rejected_verify"] += 1
            continue

        concept_id = tag_concept(a, b, answer)
        if concept_id is None:
            stats["rejected_no_concept"] += 1
            continue

        if len(buckets[concept_id]) >= n_target:
            stats["bucket_full_skips"] += 1
            continue
        if prompt in seen_prompts:
            stats["rejected_duplicate"] += 1
            continue
        seen_prompts.add(prompt)

        # Distractor: opposite operation (a + b) or (a - b) — the classic
        # "got the wrong op" misconception. Pick whichever is positive and
        # distinct from the correct answer.
        misconception: int | None = None
        for cand in (a + b, abs(a - b)):
            if cand > 0 and cand != answer:
                misconception = cand
                break
        distractors = integer_distractors_with(answer, misconception, rand)

        # Normalize prompt to U+2212 minus for any negatives (consistency
        # with the add_or_sub ingester) — but mul prompts shouldn't have
        # negatives after our filter, so this is a no-op in practice.

        explanation = [f"{a} × {b} = {answer}"]
        item = build_item(
            id=item_id(prompt, prefix="mul"),
            concept_id=concept_id,
            prompt=prompt,
            correct_answer=str(answer),
            distractors=distractors,
            explanation=explanation,
            source_module=MODULE,
        )
        buckets[concept_id].append(item)
        stats["accepted"] += 1

    stats["attempts"] = attempts
    return dict(buckets), dict(stats)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--items-per-concept", type=int, default=200)
    parser.add_argument("--seed", type=int, default=20260521)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    rand = random.Random(args.seed)
    random.seed(args.seed)

    print("=== arithmetic.mul ===", file=sys.stderr)
    buckets, stats = ingest_mul(args.items_per_concept, rand)
    for cid, items in sorted(buckets.items()):
        print(f"  {cid:36s} {len(items):4d}", file=sys.stderr)
    for k, v in stats.items():
        print(f"  [stat] {k:28s} {v}", file=sys.stderr)
    write_buckets(buckets, source_module=MODULE, dry_run=args.dry_run)
    return 0


if __name__ == "__main__":
    sys.exit(main())
