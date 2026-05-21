#!/usr/bin/env python3
"""Audit MathDataset-ElementarySchool (MD-ES): sample items from every
(source, subcategory) bucket and emit a Markdown report.

MD-ES is a re-aggregation of 6 upstream datasets (DeepMind, Math-401,
SVAMP, AddSub, MultiArith, MathQA_Geometry) into one bundle. The audit
groups by (source, subcategory) because the source is what determines
both content shape and license provenance.

The report is the input to a manual classification pass: per bucket,
the auditor reads the sampled items and decides whether to ingest, gap-
fill, skip as out-of-K-8, or skip because we'd already ingest the
upstream directly via another priority audit (DeepMind / SVAMP /
MathQA).

Run from the repo root, with a local checkout of the MD-ES repo:

    git clone https://github.com/RamonKaspar/MathDataset-ElementarySchool /tmp/mdes
    python3 tools/question_generation/audit_md_es.py \\
        --data-path /tmp/mdes/data > \\
        tools/question_generation/audits/md_es_samples.md

The output is *just* the samples — the classification verdict and roll-
up live in tools/question_generation/audits/md_es.md, which is hand-
edited around the samples.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
from collections import defaultdict
from pathlib import Path


# Pre-classification verdict per (source, subcategory). Source determines
# the content shape and license; the audit pass refines these against
# the actual samples.
#
# Verdict vocabulary:
#   variety       — math already covered by our generators; phrasing
#                   variety only
#   gap-fill      — math not yet covered; high potential value
#   redundant     — already on our priority dataset list (DeepMind /
#                   SVAMP / MathQA); ingest the upstream directly, not
#                   via MD-ES
#   license_block — upstream license is missing / unclear; not safe to
#                   bundle in v1
#   out_of_scope  — outside CCSS K-8 (HS algebra / trig / log etc.)
PRE_VERDICTS: dict[tuple[str, str], tuple[str, str]] = {
    # (source, subcategory): (pre_verdict, one-line note)
    # ---- Arithmetic ----
    ("Math-401", "arithmetic_mixed"): (
        "license_block",
        "GanjinZero/math401-llm — no LICENSE file; default copyright. "
        "Content also mixes K-8 arithmetic with HS-only items (log, sin, "
        "exponentials).",
    ),
    ("Mathematics Dataset (Google DeepMind)", "add_or_sub"): (
        "redundant",
        "Direct DeepMind ingestion (Chunk 80) already covers this with "
        "more items and seeded determinism.",
    ),
    ("Mathematics Dataset (Google DeepMind)", "add_sub_multiple"): (
        "redundant",
        "Available via direct DeepMind ingestion — see deepmind.md.",
    ),
    ("Mathematics Dataset (Google DeepMind)", "conversion"): (
        "redundant",
        "Available via direct DeepMind ingestion (verdict: skip — "
        "obscure unit pairs).",
    ),
    ("Mathematics Dataset (Google DeepMind)", "div"): (
        "redundant",
        "Available via direct DeepMind ingestion — see deepmind.md.",
    ),
    ("Mathematics Dataset (Google DeepMind)", "div_remainder"): (
        "redundant",
        "Available via direct DeepMind ingestion — see deepmind.md.",
    ),
    ("Mathematics Dataset (Google DeepMind)", "gcd"): (
        "redundant",
        "Available via direct DeepMind ingestion — see deepmind.md.",
    ),
    ("Mathematics Dataset (Google DeepMind)", "lcm"): (
        "redundant",
        "Available via direct DeepMind ingestion — see deepmind.md.",
    ),
    ("Mathematics Dataset (Google DeepMind)", "mul"): (
        "redundant",
        "Available via direct DeepMind ingestion — see deepmind.md.",
    ),
    ("Mathematics Dataset (Google DeepMind)", "mul_div_multiple"): (
        "redundant",
        "Available via direct DeepMind ingestion — see deepmind.md.",
    ),
    ("Mathematics Dataset (Google DeepMind)", "place_value"): (
        "redundant",
        "Available via direct DeepMind ingestion (one of the highest-ROI "
        "submodules per deepmind.md).",
    ),
    ("Mathematics Dataset (Google DeepMind)", "round_number"): (
        "redundant",
        "Available via direct DeepMind ingestion — see deepmind.md.",
    ),
    ("Mathematics Dataset (Google DeepMind)", "sequence_next_term"): (
        "redundant",
        "Available via direct DeepMind ingestion (verdict: out_of_scope "
        "— polynomial-fit sequences, not arithmetic).",
    ),
    ("Mathematics Dataset (Google DeepMind)", "time"): (
        "redundant",
        "Available via direct DeepMind ingestion — see deepmind.md.",
    ),
    # ---- Word Problems ----
    ("SVAMP", "challenge"): (
        "redundant",
        "SVAMP is dataset #5 on our priority list; ingest from the "
        "upstream SVAMP repo (1k items, full set) rather than via MD-ES "
        "(also 1k but a re-sample).",
    ),
    ("AddSub", "add_sub"): (
        "license_block",
        "Data is from MAWPS (lang.ee.washington.edu/MAWPS) per the AWPS "
        "README. MAWPS license is unclear — curriculum.md §7.4 already "
        "flags this as the reason to avoid AddSub/MultiArith directly.",
    ),
    ("MultiArith", "multi_step"): (
        "license_block",
        "Same MAWPS provenance as AddSub (Roy & Roth 2015, distributed "
        "via the MAWPS repository). License unclear.",
    ),
    # ---- Geometry ----
    ("MathQA_Geometry", "geometry"): (
        "redundant",
        "Geometry slice of MathQA — dataset #4 on our priority list. "
        "Ingest from upstream MathQA with the geometry filter rather "
        "than via MD-ES.",
    ),
}


def load_arithmetic(data_path: Path) -> list[dict]:
    """Arithmetic ships as JSONL in arithmetic_1000.json (no _complete on
    GitHub — the full set is 2.3GB)."""
    items: list[dict] = []
    with (data_path / "I_Arithmetic" / "arithmetic_1000.json").open() as f:
        for line in f:
            line = line.strip()
            if line:
                items.append(json.loads(line))
    return items


def load_word_problems(data_path: Path) -> list[dict]:
    """Word problems ships as a JSON array in wordProblems_complete.json
    (1995 items total)."""
    with (data_path / "II_WordProblems" / "wordProblems_complete.json").open() as f:
        return json.load(f)


def load_geometry(data_path: Path) -> list[dict]:
    """Geometry ships as JSONL in geometry_complete.json (1698 items)."""
    items: list[dict] = []
    with (data_path / "III_Geometry" / "geometry_complete.json").open() as f:
        for line in f:
            line = line.strip()
            if line:
                items.append(json.loads(line))
    return items


def bucket(items: list[dict]) -> dict[tuple[str, str], list[dict]]:
    out: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for x in items:
        key = (x.get("source") or "?", x.get("subcategory") or "?")
        out[key].append(x)
    return out


def format_q(q: str, n: int = 130) -> str:
    q = q.strip().replace("\n", " ")
    return q if len(q) <= n else q[: n - 3] + "..."


def format_a(a) -> str:
    if isinstance(a, float) and a.is_integer():
        return str(int(a))
    return str(a)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--data-path",
        type=Path,
        required=True,
        help="Path to the cloned MD-ES `data/` directory.",
    )
    parser.add_argument(
        "--samples",
        type=int,
        default=8,
        help="Number of items to sample per (source, subcategory) bucket "
        "(default 8).",
    )
    parser.add_argument("--seed", type=int, default=20260521, help="RNG seed.")
    parser.add_argument(
        "--filter",
        default="",
        help="Substring filter on source (e.g. 'AddSub') or subcategory. "
        "Empty = all.",
    )
    args = parser.parse_args()

    if not args.data_path.is_dir():
        print(
            f"error: --data-path {args.data_path} is not a directory. "
            "Clone https://github.com/RamonKaspar/MathDataset-ElementarySchool "
            "and pass its data/ directory.",
            file=sys.stderr,
        )
        return 1

    arith = load_arithmetic(args.data_path)
    wp = load_word_problems(args.data_path)
    geom = load_geometry(args.data_path)

    sections: list[tuple[str, list[dict]]] = [
        ("I. Arithmetic", arith),
        ("II. Word Problems", wp),
        ("III. Geometry", geom),
    ]

    print("# MathDataset-ElementarySchool (MD-ES) — sampled items per bucket\n")
    print(
        f"Auto-generated by [audit_md_es.py](../audit_md_es.py); "
        f"{args.samples} samples per (source, subcategory) bucket, "
        f"seed={args.seed}. Re-run to refresh.\n"
    )
    print(
        "Pre-verdicts (in italics) are first-pass guesses; the audit pass "
        "in [md_es.md](md_es.md) checks each against the actual samples.\n"
    )
    print(
        "**Bucket key:** `(source, subcategory)`. MD-ES is a re-aggregation "
        "of 6 upstream datasets — source is what determines content shape "
        "and license provenance.\n"
    )

    rng = random.Random(args.seed)

    for title, items in sections:
        print(f"## {title}\n")
        buckets = bucket(items)
        # Sort within section by source then subcategory for stable
        # output.
        for key in sorted(buckets.keys()):
            source, subcat = key
            if args.filter and args.filter not in source and args.filter not in subcat:
                continue
            pre_verdict, note = PRE_VERDICTS.get(
                key, ("review", "(no pre-classification — newly added bucket)")
            )
            n_total = len(buckets[key])
            print(
                f"### `{source}` / `{subcat}` — *{pre_verdict}*  ({n_total} items)"
            )
            print(f"\n{note}\n")
            picks = rng.sample(buckets[key], min(args.samples, n_total))
            for x in picks:
                q = format_q(x["question"])
                a = format_a(x["answer"])
                print(f"- `{q}`  →  `{a}`")
            print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
