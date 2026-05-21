#!/usr/bin/env python3
"""Audit SVAMP: sample items per Type bucket and emit a Markdown report.

The report is the input to a manual classification pass: the auditor reads
the sampled items, weighs them against curriculum.md sub-concepts, and
decides whether to ingest the dataset (in whole or in part). For SVAMP
the central question is not coverage-vs-variety (the DeepMind axis) but
licence cleanness — SVAMP's MIT LICENSE file is undermined by the
paper-acknowledged derivation from ASDiv-A (CC-BY-NC) and MAWPS.

Run from the repo root:

    python3 tools/question_generation/audit_svamp.py \\
        > tools/question_generation/audits/svamp_samples.md

The output is *just* the samples — the verdict roll-up lives in
tools/question_generation/audits/svamp.md, which is hand-edited around
the samples (mirrors the DeepMind audit pattern from Chunk 81).

By default the SVAMP.json is fetched once via urllib at a pinned commit
hash and cached on the script's side. Pass ``--svamp-json PATH`` to point
at a local checkout instead (useful when the sandbox blocks egress).
"""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import sys
import urllib.request
from collections import Counter, defaultdict

SVAMP_PINNED_COMMIT = "689d7ccac74b9983a2ac7cc3b264f441b99e7c53"
SVAMP_PINNED_URL = (
    f"https://raw.githubusercontent.com/arkilpatel/SVAMP/{SVAMP_PINNED_COMMIT}/SVAMP.json"
)
CACHE_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), ".cache", "svamp.json"
)


# Per-Type pre-verdicts. Hand-edited verdicts and reasoning live in
# audits/svamp.md.
TYPE_VERDICTS: list[tuple[str, str, str]] = [
    # (type_label, pre_verdict, one-line note)
    (
        "Addition",
        "drop",
        "G2-G4 add word problems — covered by Chunk 79 framework + queued GSM8K (MIT, clean)",
    ),
    (
        "Subtraction",
        "drop",
        "G2-G4 sub word problems — covered by Chunk 79 framework + queued GSM8K (MIT, clean)",
    ),
    (
        "Multiplication",
        "drop",
        "G3-G4 mult word problems — covered by Chunk 79 mult contexts + queued GSM8K (MIT, clean)",
    ),
    (
        "Common-Division",
        "drop",
        "G3-G4 div word problems — partial coverage (interpret_remainder_word, mult_div_word_2step datasets); GSM8K queued",
    ),
    (
        "Common-Divison",  # data has 1 item under this misspelled label
        "drop",
        "Same as Common-Division (typo in upstream data on 1 item)",
    ),
]


def load_svamp(local_path: str | None) -> list[dict]:
    """Load SVAMP.json from --svamp-json PATH or fetch from the pinned URL."""
    if local_path:
        with open(local_path) as f:
            return json.load(f)
    if os.path.exists(CACHE_PATH):
        with open(CACHE_PATH) as f:
            return json.load(f)
    os.makedirs(os.path.dirname(CACHE_PATH), exist_ok=True)
    with urllib.request.urlopen(SVAMP_PINNED_URL, timeout=30) as r:
        raw = r.read()
    with open(CACHE_PATH, "wb") as f:
        f.write(raw)
    return json.loads(raw)


_EQUATION_OP_RE = re.compile(r"[+\-*/]")


def equation_shape(eq: str) -> str:
    """Coarse classification of a SVAMP equation's structural shape.

    Examples:
        '( 76.0 - 25.0 )'                              -> '2op_sub'
        '( 7.0 * ( 4.0 + 8.0 ) )'                      -> '3op_compound'
        '7.0'                                          -> 'literal'
    """
    ops = _EQUATION_OP_RE.findall(eq)
    n_ops = len(ops)
    if n_ops == 0:
        return "literal"
    if n_ops == 1:
        single = ops[0]
        label = {"+": "add", "-": "sub", "*": "mul", "/": "div"}[single]
        return f"1op_{label}"
    # 2+ operations — same op throughout or mixed?
    distinct = set(ops)
    if len(distinct) == 1:
        return f"{n_ops}op_same"
    return f"{n_ops}op_mixed"


def numbers_in_equation(eq: str) -> list[float]:
    """Extract numeric operands from a SVAMP equation."""
    return [float(x) for x in re.findall(r"-?\d+\.?\d*", eq)]


def is_integer_answer(item: dict) -> bool:
    a = item["Answer"]
    try:
        return float(a).is_integer()
    except Exception:
        return False


def operands_fit_grade(item: dict, max_operand: float) -> bool:
    nums = numbers_in_equation(item["Equation"])
    return bool(nums) and all(abs(n) <= max_operand for n in nums)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--samples",
        type=int,
        default=6,
        help="Number of items to sample per Type bucket (default 6).",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=20260521,
        help="RNG seed (default = today's date as int).",
    )
    parser.add_argument(
        "--svamp-json",
        default=None,
        help=(
            "Path to a local SVAMP.json (e.g. from a git clone). If omitted, "
            "the script fetches the file from a pinned commit on GitHub and "
            "caches it under tools/question_generation/.cache/."
        ),
    )
    parser.add_argument(
        "--filter",
        default="",
        help="Substring filter on Type label (e.g. 'Add' to limit to Addition). Empty = all.",
    )
    args = parser.parse_args()

    svamp = load_svamp(args.svamp_json)

    type_counts = Counter(x["Type"] for x in svamp)
    by_type: dict[str, list[dict]] = defaultdict(list)
    for item in svamp:
        by_type[item["Type"]].append(item)

    shape_counts_by_type: dict[str, Counter] = {
        t: Counter(equation_shape(it["Equation"]) for it in items)
        for t, items in by_type.items()
    }

    integer_answer_counts = {
        t: sum(1 for it in items if is_integer_answer(it))
        for t, items in by_type.items()
    }

    op_le_100_counts = {
        t: sum(1 for it in items if operands_fit_grade(it, 100))
        for t, items in by_type.items()
    }

    rng = random.Random(args.seed)

    print("# SVAMP — sampled items per Type bucket\n")
    print(
        f"Auto-generated by [audit_svamp.py](../audit_svamp.py); "
        f"{args.samples} samples per Type, seed={args.seed}, pinned upstream "
        f"commit `{SVAMP_PINNED_COMMIT[:7]}`. Re-run to refresh.\n"
    )
    print(
        "Pre-verdicts (in italics) are first-pass guesses; the hand-audit "
        "in [svamp.md](svamp.md) refines them.\n"
    )

    print("## Dataset summary\n")
    print(f"- Total items: **{len(svamp)}**\n")
    print("- Type distribution:\n")
    for t, n in type_counts.most_common():
        pct = 100 * n / len(svamp)
        print(f"  - `{t}`: **{n}** ({pct:.1f}%)")
    print()
    print("- Integer-answer share per Type:\n")
    for t, _ in type_counts.most_common():
        n = type_counts[t]
        share = 100 * integer_answer_counts[t] / n if n else 0.0
        print(f"  - `{t}`: {integer_answer_counts[t]}/{n} ({share:.0f}%)")
    print()
    print("- Items with all operands ≤ 100 (K–4 scope) per Type:\n")
    for t, _ in type_counts.most_common():
        n = type_counts[t]
        share = 100 * op_le_100_counts[t] / n if n else 0.0
        print(f"  - `{t}`: {op_le_100_counts[t]}/{n} ({share:.0f}%)")
    print()

    print("## Equation-shape breakdown per Type\n")
    print(
        "`1op_*` = single-operation item (e.g. `(76 - 25)`); "
        "`Nop_same` = N operations of the same kind; "
        "`Nop_mixed` = N operations of different kinds (multi-step).\n"
    )
    for t, _ in type_counts.most_common():
        print(f"- `{t}`:")
        for shape, n in shape_counts_by_type[t].most_common():
            print(f"  - `{shape}`: {n}")
    print()

    print("## Per-Type sampled items\n")
    for t, pre, note in TYPE_VERDICTS:
        items = by_type.get(t, [])
        if args.filter and args.filter not in t:
            continue
        print(f"### `{t}` ({len(items)} items) — *{pre}*")
        print(f"\n{note}\n")
        if not items:
            print("_(no items in this Type bucket)_\n")
            continue
        n = min(args.samples, len(items))
        sampled = rng.sample(items, n)
        for it in sampled:
            body = it["Body"].strip()
            q = it["Question"].strip()
            print(f"- **{it['ID']}** | `{it['Equation']}` = `{it['Answer']}`")
            print(f"  - Body: {body}")
            print(f"  - Q:    {q}")
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
