#!/usr/bin/env python3
"""Ingest DeepMind `numbers.place_value` and `numbers.round_number` into
Math City JSON.

Both submodules are per audit's recommended ingestion order (#1 and #4):

- `numbers.place_value` — "What is the {place} digit of {N}?" → single
  digit. Cleanest fit in the entire DeepMind corpus. Tags by digit count.
- `numbers.round_number` — splits two templates: "to N decimal places"
  → ``round_decimals``; "to the nearest N" → ``round_to_10`` /
  ``round_to_100`` / ``round_multidigit_any_place``.

Re-runs are deterministic per ``--seed`` and idempotent (re-merge drops
prior rows from these submodules).
"""

from __future__ import annotations

import argparse
import random
import re
import sys
from collections import defaultdict
from pathlib import Path

from deepmind_common import (
    OUTPUT_DIR,
    build_item,
    integer_distractors_with,
    item_id,
    jitter_distractors,
    write_buckets,
)

MODULE_PLACE_VALUE = "numbers.place_value"
MODULE_ROUND_NUMBER = "numbers.round_number"


# ---------------------------------------------------------------------------
# numbers.place_value
# ---------------------------------------------------------------------------

# Names DeepMind uses for digit places, mapped to the 0-indexed digit position
# from the right (10^k).
PLACE_NAMES: dict[str, int] = {
    "units": 0,
    "tens": 1,
    "hundreds": 2,
    "thousands": 3,
    "ten thousands": 4,
    "hundred thousands": 5,
    "millions": 6,
    "ten millions": 7,
    "hundred millions": 8,
    "billions": 9,
    "ten billions": 10,
    "hundred billions": 11,
}

PLACE_VALUE_RE = re.compile(
    r"^What is the ((?:ten |hundred )?(?:units|tens|hundreds|thousands|"
    r"ten thousands|hundred thousands|millions|ten millions|hundred millions|"
    r"billions)) digit of (\d+)\?$"
)


def _tag_place_value(n_digits: int) -> str | None:
    """Bucket by total digit count of the source number.

    Match the curriculum's place_value concepts:
    - 2 digits → place_value_2digit (G1)
    - 3 digits → place_value_3digit (G2)
    - 4–7 digits → place_value_multidigit (G4)
    - 8+ digits → out of scope (curriculum tops at 7-digit multidigit).
    """
    if n_digits == 2:
        return "place_value_2digit"
    if n_digits == 3:
        return "place_value_3digit"
    if 4 <= n_digits <= 7:
        return "place_value_multidigit"
    return None


def ingest_place_value(
    n_target: int,
    rand: random.Random,
) -> tuple[dict[str, list[dict]], dict[str, int]]:
    """Drive numbers.place_value, return (buckets, stats)."""
    from mathematics_dataset.modules import numbers

    def entropy_fn(r):
        return r

    gen = numbers.train(entropy_fn)["place_value"]

    buckets: dict[str, list[dict]] = defaultdict(list)
    stats = defaultdict(int)
    seen_prompts: set[str] = set()
    attempts = 0
    max_attempts = n_target * 50  # generous budget; place_value is small/fast

    while sum(len(v) for v in buckets.values()) < n_target * 3 and attempts < max_attempts:
        attempts += 1
        ex = gen()
        prompt = str(ex.question)
        answer_str = str(ex.answer)

        m = PLACE_VALUE_RE.match(prompt)
        if not m:
            stats["rejected_parse"] += 1
            continue

        place_name, n_str = m.group(1), m.group(2)
        if place_name not in PLACE_NAMES:
            stats["rejected_unknown_place"] += 1
            continue
        place_idx = PLACE_NAMES[place_name]
        n = int(n_str)
        # Verify the math.
        expected = (n // (10**place_idx)) % 10
        try:
            stated = int(answer_str)
        except ValueError:
            stats["rejected_non_int_answer"] += 1
            continue
        if expected != stated:
            stats["rejected_verify"] += 1
            continue

        concept_id = _tag_place_value(len(n_str))
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

        # Distractors: other digits of the same number. The kid's typical
        # mistake here is "read the wrong place" — exactly the digits
        # actually appearing in N. Combine with ±1 of the correct digit
        # for the "off by one" mistake.
        other_digits = [int(d) for d in n_str if int(d) != stated]
        misconception = other_digits[0] if other_digits else None
        distractors = integer_distractors_with(stated, misconception, rand)

        item = build_item(
            id=item_id(prompt, prefix="pv"),
            concept_id=concept_id,
            prompt=prompt,
            correct_answer=str(stated),
            distractors=distractors,
            explanation=[
                f"In {n}, the {place_name} digit is {stated}."
            ],
            source_module=MODULE_PLACE_VALUE,
        )
        buckets[concept_id].append(item)
        stats["accepted"] += 1

    stats["attempts"] = attempts
    return dict(buckets), dict(stats)


# ---------------------------------------------------------------------------
# numbers.round_number
# ---------------------------------------------------------------------------

# Match the "to N decimal places" / "to N dps" / "to N dp" / "to the nearest
# integer" / "to zero decimal places" family.
DECIMAL_DPS_RE = re.compile(
    r"\b(?:to|rounded to)\s+(zero|one|two|three|four|five|six|seven|eight|nine|"
    r"\d+)\s+(?:dps?|decimal places?)\b",
    re.I,
)
DECIMAL_INTEGER_RE = re.compile(
    r"\b(?:to|rounded to)\s+the nearest integer\b",
    re.I,
)
# Match the "to the nearest N" family, where N is either a number literal
# (10, 100, 1000, …) or a place word ("ten", "one thousand", "ten million",
# etc.).
NEAREST_NUM_RE = re.compile(
    r"\b(?:to|rounded to)\s+the nearest\s+(\d+)\b",
    re.I,
)
NEAREST_PLACE_RE = re.compile(
    r"\b(?:to|rounded to)\s+the nearest\s+"
    r"((?:one|ten|hundred)(?:\s+(?:thousand|million|billion))?|"
    r"thousand|million|billion)\b",
    re.I,
)

# Map place-word phrases to powers of 10.
NEAREST_PLACE_POWER: dict[str, int] = {
    "ten": 1,
    "hundred": 2,
    "one thousand": 3,
    "ten thousand": 4,
    "hundred thousand": 5,
    "one million": 6,
    "ten million": 7,
    "hundred million": 8,
    "thousand": 3,
    "million": 6,
    "billion": 9,
    "one billion": 9,
}

# Extract a signed number (possibly with a decimal point) from the prompt.
SIGNED_NUMBER_RE = re.compile(r"-?\d+(?:\.\d+)?")

WORD_TO_INT: dict[str, int] = {
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
    "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
}


def _parse_round_input(prompt: str) -> tuple[float, str, int] | None:
    """Parse the round prompt and return (input_value, kind, k) where:

    - kind == 'dps' : k is the number of decimal places (0..)
    - kind == 'place' : k is the power of 10 (1..)

    Returns None if the prompt doesn't match any known template.
    """
    # First grab the input number — both templates put it before the "to".
    m_num = SIGNED_NUMBER_RE.search(prompt)
    if m_num is None:
        return None
    value = float(m_num.group(0))

    # "to the nearest integer" → dps with k=0
    if DECIMAL_INTEGER_RE.search(prompt):
        return value, "dps", 0

    # "to N decimal places" / "to N dps"
    m = DECIMAL_DPS_RE.search(prompt)
    if m:
        n_str = m.group(1).lower()
        if n_str in WORD_TO_INT:
            return value, "dps", WORD_TO_INT[n_str]
        try:
            return value, "dps", int(n_str)
        except ValueError:
            return None

    # "to the nearest N" (numeric)
    m = NEAREST_NUM_RE.search(prompt)
    if m:
        n = int(m.group(1))
        # n must be 10^k for some k≥1 to land in our concepts.
        if n in {10, 100, 1000, 10000, 100000, 1000000, 10000000}:
            k = 0
            while 10**k != n:
                k += 1
            return value, "place", k
        return None

    # "to the nearest {place word}"
    m = NEAREST_PLACE_RE.search(prompt)
    if m:
        phrase = m.group(1).lower()
        if phrase in NEAREST_PLACE_POWER:
            return value, "place", NEAREST_PLACE_POWER[phrase]
        return None

    return None


def _tag_round_dps(value: float, k: int) -> str | None:
    """Bucket a decimal-place rounding item."""
    # round_decimals covers k = 0..3 in curriculum. k=0 ("to nearest integer"
    # or "to zero dps") is borderline — algorithmic generator handles 1..3
    # only. Drop k=0.
    if k < 1 or k > 3:
        return None
    # Need a decimal input for the rounding to be meaningful.
    if value == int(value):
        return None
    # G5 decimals are positive-only (negatives are G6+ territory).
    if value < 0:
        return None
    return "round_decimals"


def _tag_round_place(value: float, k: int) -> str | None:
    """Bucket a nearest-place rounding item."""
    # Algorithmic round_to_10 / round_to_100 are G3, with integer inputs only.
    # DeepMind sometimes hands us decimal inputs — drop those.
    if value != int(value):
        return None
    v = int(value)
    if v < 0:
        return None  # K-G4 rounding is non-negative.
    if k == 1:
        # round_to_10: input ≤ ~999 in algorithmic generator.
        if v <= 999:
            return "round_to_10"
        return None
    if k == 2:
        if v <= 9999:
            return "round_to_100"
        return None
    if 3 <= k <= 7:
        return "round_multidigit_any_place"
    return None


def _round_half_away_from_zero(value: float, k: int, kind: str) -> int | float:
    """Reference rounding (half-away-from-zero) for verification."""
    if kind == "dps":
        # Round to k decimal places, away from zero on .5 tie.
        mult = 10**k
        return (
            int(value * mult + (0.5 if value >= 0 else -0.5)) / mult
            if k > 0
            else int(value + (0.5 if value >= 0 else -0.5))
        )
    # kind == "place"
    step = 10**k
    return int((value + (step / 2 if value >= 0 else -step / 2)) // step) * step


def ingest_round_number(
    n_target: int,
    rand: random.Random,
) -> tuple[dict[str, list[dict]], dict[str, int]]:
    """Drive numbers.round_number, return (buckets, stats)."""
    from mathematics_dataset.modules import numbers

    def entropy_fn(r):
        return r

    gen = numbers.train(entropy_fn)["round_number"]

    buckets: dict[str, list[dict]] = defaultdict(list)
    stats = defaultdict(int)
    seen_prompts: set[str] = set()
    attempts = 0
    max_attempts = n_target * 200

    target_total = n_target * 4  # 4 target concepts
    while (
        sum(len(v) for v in buckets.values()) < target_total
        and attempts < max_attempts
    ):
        attempts += 1
        ex = gen()
        prompt = str(ex.question)
        answer_str = str(ex.answer)

        parsed = _parse_round_input(prompt)
        if parsed is None:
            stats["rejected_parse"] += 1
            continue
        value, kind, k = parsed

        # Don't ingest items whose stated answer DeepMind formats in a way
        # we can't easily round-trip — anything with scientific notation
        # ("1e-06"), trailing-zero stripping issues, etc. Accept clean
        # decimal / integer strings only.
        try:
            stated = float(answer_str)
        except ValueError:
            stats["rejected_non_numeric_answer"] += 1
            continue

        # Tag.
        if kind == "dps":
            concept_id = _tag_round_dps(value, k)
        else:
            concept_id = _tag_round_place(value, k)
        if concept_id is None:
            stats["rejected_no_concept"] += 1
            continue

        # Verify.
        expected = _round_half_away_from_zero(value, k, kind)
        if abs(expected - stated) > 1e-9:
            stats["rejected_verify"] += 1
            continue

        if len(buckets[concept_id]) >= n_target:
            stats["bucket_full_skips"] += 1
            continue
        if prompt in seen_prompts:
            stats["rejected_duplicate"] += 1
            continue
        seen_prompts.add(prompt)

        # Distractors: ±1 in the rounding unit.
        #
        # - `kind == "place"`: answer is always an integer; emit integer-string
        #   distractors with the "rounded the wrong direction" misconception.
        # - `kind == "dps"`: answer is always a fixed-precision decimal,
        #   even when the rounded value is mathematically an integer
        #   (e.g. 0.04 rounded to 1 dp is "0.0", not "0"). Emit decimal
        #   distractors at the same precision.
        if kind == "place":
            unit = 10**k
            jitter_correct = int(stated)
            other_dir = (
                int(stated - unit) if value > stated else int(stated + unit)
            )
            distractors = integer_distractors_with(
                jitter_correct,
                other_dir if other_dir >= 0 else None,
                rand,
            )
            correct_answer_str = str(int(stated))
        else:
            # kind == "dps" — decimal answer at precision k.
            unit = 10**-k
            cand: set[float] = set()
            for delta in (-2, -1, 1, 2, -3, 3, -4, 4):
                v = round(stated + delta * unit, k)
                if v != stated:
                    cand.add(v)
            cand_list = sorted(cand)
            rand.shuffle(cand_list)
            picks = cand_list[:3]
            distractors = [f"{p:.{k}f}" for p in picks]
            correct_answer_str = f"{stated:.{k}f}"

        if len(distractors) < 3:
            stats["rejected_distractor_short"] += 1
            continue

        place_phrase = (
            f"{k} decimal place{'s' if k != 1 else ''}"
            if kind == "dps"
            else f"nearest {10**k}"
        )
        explanation = [
            f"Round {value:g} to {place_phrase} gives {correct_answer_str}."
        ]

        item = build_item(
            id=item_id(prompt, prefix="round"),
            concept_id=concept_id,
            prompt=prompt,
            correct_answer=correct_answer_str,
            distractors=distractors,
            explanation=explanation,
            source_module=MODULE_ROUND_NUMBER,
        )
        buckets[concept_id].append(item)
        stats["accepted"] += 1

    stats["attempts"] = attempts
    return dict(buckets), dict(stats)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--items-per-concept",
        type=int,
        default=200,
        help="Per-sub-concept cap. Default 200.",
    )
    parser.add_argument("--seed", type=int, default=20260521)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--only",
        choices=("place_value", "round_number", "all"),
        default="all",
        help="Restrict to one submodule (default: all).",
    )
    args = parser.parse_args()

    rand = random.Random(args.seed)
    random.seed(args.seed)

    print("=== numbers.place_value ===", file=sys.stderr)
    if args.only in {"place_value", "all"}:
        buckets_pv, stats_pv = ingest_place_value(args.items_per_concept, rand)
        for cid, items in sorted(buckets_pv.items()):
            print(f"  {cid:36s} {len(items):4d}", file=sys.stderr)
        for k, v in stats_pv.items():
            print(f"  [stat] {k:28s} {v}", file=sys.stderr)
        write_buckets(
            buckets_pv,
            source_module=MODULE_PLACE_VALUE,
            dry_run=args.dry_run,
        )

    print("\n=== numbers.round_number ===", file=sys.stderr)
    if args.only in {"round_number", "all"}:
        buckets_rd, stats_rd = ingest_round_number(args.items_per_concept, rand)
        for cid, items in sorted(buckets_rd.items()):
            print(f"  {cid:36s} {len(items):4d}", file=sys.stderr)
        for k, v in stats_rd.items():
            print(f"  [stat] {k:28s} {v}", file=sys.stderr)
        write_buckets(
            buckets_rd,
            source_module=MODULE_ROUND_NUMBER,
            dry_run=args.dry_run,
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
