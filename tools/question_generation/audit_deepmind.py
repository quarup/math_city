#!/usr/bin/env python3
"""Audit DeepMind mathematics_dataset: sample items from every K-8-scoped
submodule and emit a Markdown report.

The report is the input to a manual classification pass: per submodule,
the auditor reads the sampled items and decides whether the submodule
should be (a) ingested for phrasing variety, (b) ingested for gap-fill,
(c) skipped as out of K-8 scope, or (d) skipped because our algorithmic
generators already cover this richly.

Run from the repo root:

    python3 tools/question_generation/audit_deepmind.py > tools/question_generation/audits/deepmind_samples.md

The output is *just* the samples — the classification verdict and
roll-up live in tools/question_generation/audits/deepmind.md, which is
hand-edited around the samples.
"""

from __future__ import annotations

import argparse
import random
import sys
from typing import Callable


# Submodules grouped by top-level category, in the order they appear in
# DeepMind's `modules.train()` output. The "_composed" variants are
# omitted — they wrap the base submodule into a multi-step expression
# and don't add new content for audit purposes.
#
# A pre-classification verdict appears next to each row. The audit pass
# checks/overrides these based on the sampled items.
SUBMODULES: list[tuple[str, str, str]] = [
    # (full_name, pre_verdict, one-line note)
    ("algebra.linear_1d", "variety", "ax + b = c — covered by solve_one_step_eq_*"),
    ("algebra.linear_2d", "variety", "systems — covered by solve_system_*"),
    ("algebra.polynomial_roots", "out_of_scope", "HS algebra"),
    ("algebra.sequence_next_term", "variety", "arithmetic sequences — covered by numerical_pattern_rule"),
    ("algebra.sequence_nth_term", "review", "closed-form nth term — may be gap-fill"),
    ("arithmetic.add_or_sub", "variety", "covered by add_within_* / sub_within_* (ingested Chunk 80)"),
    ("arithmetic.add_or_sub_in_base", "out_of_scope", "non-decimal bases not in CCSS K-8"),
    ("arithmetic.add_sub_multiple", "variety", "multi-step ± — covered by order_of_operations_*"),
    ("arithmetic.div", "variety", "covered by div_facts_* / div_with_remainder_*"),
    ("arithmetic.mixed", "review", "mixed ops with fractions — may be partial coverage"),
    ("arithmetic.mul", "variety", "covered by mult_facts_* / mult_2_by_2digit"),
    ("arithmetic.mul_div_multiple", "variety", "multi-step ×÷ — covered by order_of_operations_*"),
    ("arithmetic.nearest_integer_root", "out_of_scope", "HS"),
    ("arithmetic.simplify_surd", "out_of_scope", "HS"),
    ("calculus.differentiate", "out_of_scope", "HS"),
    ("comparison.closest", "review", "no generator equivalent — possible gap-fill"),
    ("comparison.kth_biggest", "review", "no generator equivalent — possible gap-fill"),
    ("comparison.pair", "variety", "covered by compare_2digit / compare_3digit / compare_multidigit"),
    ("comparison.sort", "review", "no generator equivalent — possible gap-fill"),
    ("measurement.conversion", "variety", "covered by convert_units_within_system / convert_units_multistep"),
    ("measurement.time", "variety", "covered by time_to_hour_half / time_to_5_min / time_to_minute / elapsed_time"),
    ("numbers.base_conversion", "out_of_scope", "non-decimal bases not in CCSS K-8"),
    ("numbers.div_remainder", "variety", "covered by div_with_remainder_*"),
    ("numbers.gcd", "variety", "covered by gcf_two_numbers"),
    ("numbers.is_factor", "variety", "covered by factors_of_n"),
    ("numbers.is_prime", "variety", "covered by prime_or_composite"),
    ("numbers.lcm", "variety", "covered by lcm_two_numbers"),
    ("numbers.list_prime_factors", "variety", "covered by prime_factorization"),
    ("numbers.place_value", "variety", "covered by place_value_2digit / 3digit / multidigit"),
    ("numbers.round_number", "variety", "covered by round_to_10 / round_to_100 / round_multidigit_any_place"),
    ("polynomials.add", "out_of_scope", "HS algebra"),
    ("polynomials.coefficient_named", "out_of_scope", "HS algebra"),
    ("polynomials.collect", "out_of_scope", "HS algebra"),
    ("polynomials.compose", "out_of_scope", "HS algebra"),
    ("polynomials.evaluate", "review", "evaluate poly at a value — partial G8 coverage in function generators?"),
    ("polynomials.expand", "out_of_scope", "HS algebra"),
    ("polynomials.simplify_power", "out_of_scope", "HS algebra"),
    ("probability.swr_p_level_set", "review", "sample-without-replacement P — partial coverage in probability_simple_event?"),
    ("probability.swr_p_sequence", "review", "sequence-of-draws P — possible gap-fill"),
]


def get_generator(full_name: str) -> Callable | None:
    """Look up a submodule by its dotted name."""
    from mathematics_dataset.modules import modules as m

    tree = m.train(lambda r: r)
    parts = full_name.split(".")
    cur = tree
    for p in parts:
        if not isinstance(cur, dict) or p not in cur:
            return None
        cur = cur[p]
    return cur if callable(cur) else None


def sample(full_name: str, n: int, seed: int) -> list[tuple[str, str]]:
    """Return n (question, answer) samples from the named submodule.

    DeepMind's generators occasionally raise on edge cases; we catch and skip,
    capped at 4× attempts before giving up.
    """
    gen = get_generator(full_name)
    if gen is None:
        return []
    random.seed(seed)
    out: list[tuple[str, str]] = []
    attempts = 0
    while len(out) < n and attempts < n * 4:
        attempts += 1
        try:
            ex = gen()
        except Exception:
            continue
        out.append((str(ex.question), str(ex.answer)))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--samples",
        type=int,
        default=8,
        help="Number of items to sample per submodule (default 8).",
    )
    parser.add_argument("--seed", type=int, default=20260519, help="RNG seed.")
    parser.add_argument(
        "--filter",
        default="",
        help="Substring filter on submodule name (e.g. 'arith' to limit to "
        "arithmetic.*). Empty = all.",
    )
    args = parser.parse_args()

    rows = [r for r in SUBMODULES if args.filter in r[0]]

    print("# DeepMind `mathematics_dataset` — sampled items per submodule\n")
    print(
        f"Auto-generated by [audit_deepmind.py](../audit_deepmind.py); "
        f"{args.samples} samples per submodule, seed={args.seed}. Re-run to refresh.\n"
    )
    print("Pre-verdicts (in italics) are first-pass guesses; the audit "
          "pass in [deepmind.md](deepmind.md) checks each against the "
          "actual samples.\n")

    by_category: dict[str, list[tuple[str, str, str]]] = {}
    for full, pre, note in rows:
        category = full.split(".", 1)[0]
        by_category.setdefault(category, []).append((full, pre, note))

    for category, group in by_category.items():
        print(f"## {category}\n")
        for full, pre, note in group:
            print(f"### `{full}` — *{pre}*")
            print(f"\n{note}\n")
            samples = sample(full, args.samples, args.seed)
            if not samples:
                print("_(no samples — generator unavailable or raised on every attempt)_\n")
                continue
            for q, a in samples:
                q_short = q if len(q) <= 100 else q[:97] + "..."
                a_short = a if len(a) <= 60 else a[:57] + "..."
                print(f"- `{q_short}`  →  `{a_short}`")
            print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
