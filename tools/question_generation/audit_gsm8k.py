#!/usr/bin/env python3
"""Audit GSM8K: bucket items by candidate target sub-concept, roll up
operation / line-count / theme distributions, and emit a Markdown report.

The report is the input to a manual classification pass. Per primary
bucket (= candidate target sub-concept ID), the auditor reads the
sampled items and decides whether GSM8K is a good source for that
sub-concept, and what filtering recipe ingestion will need.

GSM8K is structurally different from DeepMind's mathematics_dataset:
it's a single flat pool of ~8.8K word problems, not pre-sliced into
submodules. The slicing here is therefore *our* construction —
heuristics over the question text + the inline ``<<expr=result>>``
calculator annotations in each rationale.

Run from the repo root:

    python3 tools/question_generation/audit_gsm8k.py \\
        > tools/question_generation/audits/gsm8k_samples.md

First run downloads ~10 MB of JSONL into
``tools/question_generation/.cache/gsm8k/`` (gitignored, re-downloadable).
Subsequent runs reuse the cache.

The output is *just* the samples + roll-ups — the classification
verdicts live in ``tools/question_generation/audits/gsm8k.md``, hand-edited
around the samples.
"""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import sys
import urllib.request
from collections import Counter
from pathlib import Path
from typing import Callable

CACHE_DIR = Path(__file__).resolve().parent / ".cache" / "gsm8k"
GSM8K_BASE_URL = (
    "https://raw.githubusercontent.com/openai/grade-school-math/"
    "master/grade_school_math/data/"
)
SPLITS = ("train", "test")  # main split only — socratic adds nothing for audit


# ---------------------------------------------------------------------------
# Feature extraction
# ---------------------------------------------------------------------------

# Calculator annotations: <<expr=result>>. result is *almost* always int.
ANN_RE = re.compile(r"<<([^=]+)=([^>]+)>>")
# Final answer terminator. Documented invariant: always integer.
FINAL_RE = re.compile(r"####\s*(-?[\d,\.]+)")
# Multiplicative-comparison phrasing — "twice as", "3 times as many", etc.
MULT_COMPARE_RE = re.compile(
    r"\b(times as|twice as|thrice as|times more|times fewer|"
    r"times the (number|amount|cost|price|weight|size))\b",
    re.I,
)
# A bare fraction in the question text (e.g. "2/3 of the apples"). Excludes
# dates / ratios (1:2) / decimals.
FRACTION_Q_RE = re.compile(r"(?<![\d/])([2-9])/([2-9])(?![\d/])")
PERCENT_RE = re.compile(r"(\d+\s*%|\bpercent\b|\bpercentage\b)", re.I)
DECIMAL_VAL_RE = re.compile(r"-?\d+\.\d+")
MONEY_RE = re.compile(r"\$|\bdollar|\bcent|¢", re.I)
# Algebraic setup in the rationale: "Let x be...", "Let C be...".
ALGEBRA_LET_RE = re.compile(r"^\s*Let\s+[A-Za-z]\b", re.M)
RATIO_RE = re.compile(r"\bratio(s)?\b", re.I)
REMAINDER_RE = re.compile(r"\b(remainder|left over|leftover)\b", re.I)


def _ops_from_annotations(anns: list[tuple[str, str]]) -> set[str]:
    """Return the set of operators used across the rationale's annotations.

    Tricky bit: a leading minus on a literal (e.g. ``-3 + 5``) is the unary
    sign, not subtraction. We only count ``-`` as subtraction if it appears
    between two operands.
    """
    ops: set[str] = set()
    for expr, _ in anns:
        e = expr.strip()
        if "+" in e:
            ops.add("+")
        # Subtraction = '-' that's NOT at the very start of the expression.
        if re.search(r"\S\s*-", e):
            ops.add("-")
        if "*" in e:
            ops.add("*")
        if "/" in e:
            ops.add("/")
    return ops


def _rationale_line_count(answer: str) -> int:
    """Count non-blank rationale lines, excluding the '#### N' terminator."""
    return sum(
        1
        for ln in answer.split("\n")
        if ln.strip() and not ln.strip().startswith("####")
    )


def _parse_final(answer: str) -> float | None:
    m = FINAL_RE.search(answer)
    if not m:
        return None
    try:
        return float(m.group(1).replace(",", ""))
    except ValueError:
        return None


def features(item: dict) -> dict:
    q = item["question"]
    a = item["answer"]
    anns = ANN_RE.findall(a)
    final_val = _parse_final(a)
    return {
        "n_ann": len(anns),
        "n_lines": _rationale_line_count(a),
        "ops": _ops_from_annotations(anns),
        "has_mult_compare": bool(MULT_COMPARE_RE.search(q)),
        "has_fraction_q": bool(FRACTION_Q_RE.search(q)),
        "has_percent": bool(PERCENT_RE.search(q + " " + a)),
        "has_decimal_step": any(DECIMAL_VAL_RE.search(res) for _, res in anns),
        "has_money": bool(MONEY_RE.search(q)),
        "has_ratio": bool(RATIO_RE.search(q)),
        "has_remainder": bool(REMAINDER_RE.search(q)),
        "has_algebra_let": bool(ALGEBRA_LET_RE.search(a)),
        "final_val": final_val,
        "final_is_int": (
            final_val is not None and final_val == int(final_val)
        ),
    }


# ---------------------------------------------------------------------------
# Primary buckets — one per candidate target sub-concept.
#
# Ordering matters: first matching bucket wins. So put more specific
# (narrower) buckets ahead of broader ones.
# ---------------------------------------------------------------------------

# Per-bucket detector functions. Each takes the feature dict and returns
# True if the item belongs in this bucket.

def _is_add_word_problems_within_100(f: dict) -> bool:
    """G2: single-step ± word problems, answer ≤ 100.

    GSM8K's rationale convention annotates only the hardest step, but the
    rationale text always has at least one *additional* setup line, so true
    single-step items don't exist in the corpus. This bucket is included to
    surface that finding in the audit; it should resolve to ~0 items.
    """
    return (
        f["n_lines"] == 1
        and f["n_ann"] == 1
        and f["ops"].issubset({"+", "-"}) and f["ops"]
        and f["final_val"] is not None
        and abs(f["final_val"]) <= 100
        and not f["has_fraction_q"]
        and not f["has_decimal_step"]
        and not f["has_percent"]
    )


def _is_add_sub_2step_word_problems(f: dict) -> bool:
    """G2: 2-step ± word problems, integer answer ≤ 1000."""
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
    """G4: "X has 3 times as many Y as Z" framing."""
    return (
        f["has_mult_compare"]
        and f["final_is_int"]
        and not f["has_algebra_let"]
    )


def _is_mult_div_word_2step(f: dict) -> bool:
    """G4: multi-step word problems involving × and/or ÷."""
    return (
        2 <= f["n_lines"] <= 4
        and bool(f["ops"] & {"*", "/"})
        and f["final_is_int"]
        and not f["has_fraction_q"]
        and not f["has_percent"]
        and not f["has_algebra_let"]
    )


def _is_fraction_word_problems(f: dict) -> bool:
    """G5: word problems with explicit fractions in the question text."""
    return (
        f["has_fraction_q"]
        and f["final_is_int"]
        and not f["has_algebra_let"]
    )


def _is_word_problem_two_step_eq(f: dict) -> bool:
    """G7 (gap-fill candidate): rationale uses algebraic setup (Let x...).

    Not in §7.2's GSM8K mapping but the audit surfaces a clear fit.
    """
    return (
        f["has_algebra_let"]
        and f["final_is_int"]
    )


def _is_interpret_remainder_word(f: dict) -> bool:
    """G4 (borderline): "remainder" / "left over" framing."""
    return (
        f["has_remainder"]
        and "/" in f["ops"]
        and f["final_is_int"]
    )


# Buckets in match-priority order. Each item is assigned to the FIRST
# bucket whose detector returns True. The trailing `('other', ...)` is
# the catch-all.
BUCKETS: list[tuple[str, str, Callable[[dict], bool]]] = [
    # (bucket_id, grade_label, detector)
    ("add_word_problems_within_100", "G2", _is_add_word_problems_within_100),
    ("word_problem_two_step_eq", "G7", _is_word_problem_two_step_eq),
    ("mult_compare_word", "G4", _is_mult_compare_word),
    ("fraction_word_problems", "G5", _is_fraction_word_problems),
    ("interpret_remainder_word", "G4", _is_interpret_remainder_word),
    ("add_sub_2step_word_problems", "G2", _is_add_sub_2step_word_problems),
    ("mult_div_word_2step", "G4", _is_mult_div_word_2step),
]


def classify(f: dict) -> tuple[str, str]:
    for bucket_id, grade, detector in BUCKETS:
        if detector(f):
            return bucket_id, grade
    return ("other", "—")


# ---------------------------------------------------------------------------
# Data loading (cached download)
# ---------------------------------------------------------------------------

def ensure_cached(split: str, *, force: bool = False) -> Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    fname = f"{split}.jsonl"
    dest = CACHE_DIR / fname
    if dest.exists() and not force:
        return dest
    url = GSM8K_BASE_URL + fname
    print(f"Downloading {url} -> {dest}", file=sys.stderr)
    urllib.request.urlretrieve(url, dest)
    return dest


def load_items() -> list[dict]:
    items: list[dict] = []
    for split in SPLITS:
        path = ensure_cached(split)
        with open(path) as fh:
            for line in fh:
                items.append(json.loads(line))
    return items


# ---------------------------------------------------------------------------
# Report rendering
# ---------------------------------------------------------------------------

def _md_table(headers: list[str], rows: list[list]) -> str:
    out = ["| " + " | ".join(headers) + " |"]
    out.append("|" + "|".join("---" for _ in headers) + "|")
    for r in rows:
        out.append("| " + " | ".join(str(c) for c in r) + " |")
    return "\n".join(out)


def _fmt_ops(ops: set[str]) -> str:
    if not ops:
        return "(none)"
    order = {"+": 0, "-": 1, "*": 2, "/": 3}
    return ", ".join(sorted(ops, key=lambda o: order[o]))


def render(items: list[dict], *, samples_per_bucket: int, seed: int) -> str:
    rng = random.Random(seed)
    n = len(items)

    # Classify
    enriched = []
    for it in items:
        f = features(it)
        bucket_id, grade = classify(f)
        enriched.append((bucket_id, grade, f, it))

    out: list[str] = []

    # ---- Header ----
    out.append("# GSM8K — audit samples (auto-generated)")
    out.append("")
    out.append(
        "Auto-generated by [`audit_gsm8k.py`](../audit_gsm8k.py). "
        "**Do not hand-edit** — regenerate with:"
    )
    out.append("")
    out.append("```sh")
    out.append(
        "python3 tools/question_generation/audit_gsm8k.py "
        "> tools/question_generation/audits/gsm8k_samples.md"
    )
    out.append("```")
    out.append("")
    out.append(
        "Hand-edited verdicts live in [`gsm8k.md`](gsm8k.md). Auditor "
        "uses this file's samples + roll-ups to confirm or override the "
        "automatic bucket assignments."
    )
    out.append("")
    out.append(
        f"**Corpus:** GSM8K main split, train + test = **{n}** items "
        "(MIT, OpenAI 2021)."
    )
    out.append("")

    # ---- TL;DR roll-up ----
    out.append("## Primary-bucket roll-up")
    out.append("")
    out.append(
        "Each item is assigned to the first bucket whose detector "
        "returns True (see `BUCKETS` in the script). Bucket IDs map to "
        "candidate target sub-concepts in `curriculum.md` §3."
    )
    out.append("")
    counts = Counter(b for b, *_ in enriched)
    rows = []
    bucket_order = [b for b, _, _ in BUCKETS] + ["other"]
    for b in bucket_order:
        c = counts.get(b, 0)
        grade = next((g for bid, g, _ in BUCKETS if bid == b), "—")
        rows.append([f"`{b}`", grade, c, f"{c / n * 100:.1f}%"])
    out.append(_md_table(["Bucket", "Grade", "Count", "Share"], rows))
    out.append("")

    # ---- Secondary roll-ups ----
    out.append("## Secondary roll-ups")
    out.append("")
    out.append("### Rationale line count")
    out.append("")
    out.append(
        "Tighter step-count proxy than `<<...>>` annotation count, "
        "since GSM8K's convention is to annotate only the hardest step."
    )
    out.append("")
    line_dist = Counter(f["n_lines"] for _, _, f, _ in enriched)
    rows = [
        [k, line_dist[k], f"{line_dist[k] / n * 100:.1f}%"]
        for k in sorted(line_dist)
    ]
    out.append(_md_table(["Lines", "Count", "Share"], rows))
    out.append("")

    out.append("### Annotation count (<<expr=result>> per rationale)")
    out.append("")
    ann_dist = Counter(f["n_ann"] for _, _, f, _ in enriched)
    rows = [
        [k, ann_dist[k], f"{ann_dist[k] / n * 100:.1f}%"]
        for k in sorted(ann_dist)
    ]
    out.append(_md_table(["Annotations", "Count", "Share"], rows))
    out.append("")

    out.append("### Operation mix")
    out.append("")
    op_dist = Counter(_fmt_ops(f["ops"]) for _, _, f, _ in enriched)
    rows = [
        [k, op_dist[k], f"{op_dist[k] / n * 100:.1f}%"]
        for k, _ in op_dist.most_common()
    ]
    out.append(_md_table(["Ops used", "Count", "Share"], rows))
    out.append("")

    out.append("### Theme / framing prevalence")
    out.append("")
    theme_rows = []
    theme_specs = [
        ("money ($ / dollar / cent)", lambda f: f["has_money"]),
        ("percent (% / percent)", lambda f: f["has_percent"]),
        ("explicit fraction in question (a/b)", lambda f: f["has_fraction_q"]),
        ("decimal in intermediate step", lambda f: f["has_decimal_step"]),
        ("multiplicative comparison phrasing", lambda f: f["has_mult_compare"]),
        ("ratio in question", lambda f: f["has_ratio"]),
        ("remainder in question", lambda f: f["has_remainder"]),
        ("algebraic Let-x in rationale", lambda f: f["has_algebra_let"]),
        ("integer final answer", lambda f: f["final_is_int"]),
    ]
    for label, predicate in theme_specs:
        c = sum(1 for _, _, f, _ in enriched if predicate(f))
        theme_rows.append([label, c, f"{c / n * 100:.1f}%"])
    out.append(_md_table(["Feature", "Count", "Share"], theme_rows))
    out.append("")

    out.append("### Final-answer magnitude (bucketed)")
    out.append("")
    mag_buckets = [
        ("≤10", lambda v: v is not None and abs(v) <= 10),
        ("11–100", lambda v: v is not None and 10 < abs(v) <= 100),
        ("101–1000", lambda v: v is not None and 100 < abs(v) <= 1000),
        ("1001–10000", lambda v: v is not None and 1000 < abs(v) <= 10000),
        (">10000", lambda v: v is not None and abs(v) > 10000),
        ("(none parsed)", lambda v: v is None),
    ]
    rows = []
    for label, pred in mag_buckets:
        c = sum(1 for _, _, f, _ in enriched if pred(f["final_val"]))
        rows.append([label, c, f"{c / n * 100:.1f}%"])
    out.append(_md_table(["Range", "Count", "Share"], rows))
    out.append("")

    # ---- Samples per primary bucket ----
    out.append("## Sample items per bucket")
    out.append("")
    out.append(
        f"`{samples_per_bucket}` items per bucket, sampled deterministically "
        f"with `seed={seed}`."
    )
    out.append("")

    by_bucket: dict[str, list] = {}
    for tup in enriched:
        by_bucket.setdefault(tup[0], []).append(tup)

    for b in bucket_order:
        pool = by_bucket.get(b, [])
        grade = next((g for bid, g, _ in BUCKETS if bid == b), "—")
        out.append(f"### `{b}` ({grade}) — {len(pool)} items")
        out.append("")
        if not pool:
            out.append("_Empty bucket._")
            out.append("")
            continue
        sampled = rng.sample(pool, min(samples_per_bucket, len(pool)))
        for _, _, f, it in sampled:
            out.append(
                f"- **n_lines** {f['n_lines']}, **n_ann** {f['n_ann']}, "
                f"**ops** {_fmt_ops(f['ops'])}, "
                f"**final** {f['final_val']!s}, "
                f"**money** {'Y' if f['has_money'] else 'N'}, "
                f"**%** {'Y' if f['has_percent'] else 'N'}"
            )
            out.append("")
            out.append("  **Q:** " + it["question"].replace("\n", " "))
            out.append("")
            out.append("  **A:**")
            out.append("")
            out.append("  ```")
            for ln in it["answer"].split("\n"):
                out.append("  " + ln)
            out.append("  ```")
            out.append("")

    return "\n".join(out)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--samples",
        type=int,
        default=5,
        help="Number of items to sample per primary bucket (default: 5).",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for sample selection (default: 42).",
    )
    parser.add_argument(
        "--force-download",
        action="store_true",
        help="Re-download GSM8K JSONL even if cached.",
    )
    args = parser.parse_args()

    if args.force_download:
        for split in SPLITS:
            ensure_cached(split, force=True)

    items = load_items()
    report = render(items, samples_per_bucket=args.samples, seed=args.seed)
    sys.stdout.write(report)
    if not report.endswith("\n"):
        sys.stdout.write("\n")


if __name__ == "__main__":
    main()
