#!/usr/bin/env python3
"""Audit MathQA: sample items per `(category, sub_bucket)` bucket and
emit a Markdown report.

MathQA's top-level grouping is `category` (general / physics / gain /
geometry / other / probability), but `category` alone is too shallow —
within each category the items mix several math shapes (basic
arithmetic vs. exponentiation vs. encoded geometry formulas, etc.).
This audit sub-buckets each category by inspecting which ops appear in
the `annotated_formula` field, so a `(category, sub_bucket)` cell isolates
items of similar math shape.

Sub-bucket key (computed by ``classify_formula``):

- ``arith_basic``        formula uses only +/-/×/÷ family ops
- ``arith_power``        formula uses ``power(...)``
- ``arith_sqrt``         formula uses ``sqrt(...)``
- ``arith_log_fact``     formula uses ``log(...)`` or ``factorial(...)``
- ``arith_gcd_lcm``      formula uses ``gcd(...)`` or ``lcm(...)``
- ``geom_2d_encoded``    formula uses 2D-geometry ops (area / perimeter / diagonal)
- ``geom_3d_encoded``    formula uses 3D-geometry ops (volume / surface)
- ``gain_encoded``       formula uses gain / loss / interest ops
- ``physics_encoded``    formula uses speed / work / stream ops
- ``prob``               formula uses combination / permutation / union_prob / negate_prob
- ``trig``               formula uses sine / cosine / tangent / radians_to_degree
- ``misc_encoded``       formula uses sum_consecutive_number or count_interval

The bucket key is `(category, sub_bucket)`. Most items fall into the
arith_basic sub-bucket of their category — that's expected, since the
specialized opcodes (gain_percent, rectangle_area, …) were defined
broadly but used sparingly. The cross-tab matters for sampling: it
lets us see, e.g., the arith_basic items in `category=geometry`
separately from the geom_2d_encoded items, which is exactly the
"is this geometry slice actually all geometry?" question MD-ES
flagged.

Run from the repo root, with a local download of MathQA:

    mkdir -p /tmp/mathqa && cd /tmp/mathqa && \\
        curl -sSL -o MathQA.zip \\
            https://math-qa.github.io/math-QA/data/MathQA.zip && \\
        unzip -o MathQA.zip
    python3 tools/question_generation/audit_mathqa.py \\
        --data-path /tmp/mathqa > \\
        tools/question_generation/audits/mathqa_samples.md

The output is *just* the samples — the per-bucket verdicts and roll-up
live in tools/question_generation/audits/mathqa.md, which is hand-
edited around the samples.
"""

from __future__ import annotations

import argparse
import json
import random
import re
import sys
from collections import defaultdict
from pathlib import Path


# ---- Operation classification -------------------------------------------------

GEOM_2D_OPS = {
    "circle_area", "circumface", "circle_arc", "semi_circle_perimiter",
    "circle_sector_area",
    "rectangle_perimeter", "rectangle_area",
    "square_perimeter", "square_area",
    "trapezium_area", "rhombus_perimeter", "rhombus_area", "quadrilateral_area",
    "triangle_perimeter", "triangle_area", "triangle_area_three_edges",
    "side_by_diagonal", "diagonal",
    "square_edge_by_perimeter", "square_edge_by_area",
}
GEOM_3D_OPS = {
    "volume_cone", "volume_rectangular_prism", "volume_cube",
    "volume_sphere", "volume_cylinder",
    "surface_cone", "surface_cylinder", "surface_cube",
    "surface_rectangular_prism", "surface_sphere",
    "cube_edge_by_volume",
}
GAIN_OPS = {
    "percent", "p_after_gain", "p_after_loss",
    "price_after_gain", "price_after_loss",
    "from_percent", "gain_percent", "loss_percent", "negate_percent",
    "original_price_before_gain", "original_price_before_loss", "to_percent",
}
PHYSICS_OPS = {
    "speed", "combined_work", "find_work",
    "speed_ratio_steel_to_stream", "speed_in_still_water", "stream_speed",
}
PROB_OPS = {"union_prob", "negate_prob", "combination", "permutation", "choose"}
TRIG_OPS = {"sine", "cosine", "tangent", "radians_to_degree", "degree_to_radians"}
MISC_OPS = {"sum_consecutive_number", "count_interval"}

OP_RE = re.compile(r"([a-zA-Z_][a-zA-Z0-9_]*)\s*\(")


def all_ops(formula: str) -> set[str]:
    return set(OP_RE.findall(formula or ""))


def classify_formula(formula: str) -> str:
    """Return the sub-bucket label for a single annotated_formula string.

    Specificity ladder: probability > trig > physics > gain > geometry-3D >
    geometry-2D > misc > advanced-arith (sqrt > power > log/fact > gcd/lcm)
    > arith_basic. So an item using ``divide(rectangle_area(...), 2)`` lands
    in ``geom_2d_encoded`` (not ``arith_basic``), because the geometry op
    is the more diagnostic signal.
    """
    ops = all_ops(formula)
    if ops & PROB_OPS:
        return "prob"
    if ops & TRIG_OPS:
        return "trig"
    if ops & PHYSICS_OPS:
        return "physics_encoded"
    if ops & GAIN_OPS:
        return "gain_encoded"
    if ops & GEOM_3D_OPS:
        return "geom_3d_encoded"
    if ops & GEOM_2D_OPS:
        return "geom_2d_encoded"
    if ops & MISC_OPS:
        return "misc_encoded"
    if "sqrt" in ops:
        return "arith_sqrt"
    if "power" in ops:
        return "arith_power"
    if ops & {"log", "factorial"}:
        return "arith_log_fact"
    if ops & {"gcd", "lcm"}:
        return "arith_gcd_lcm"
    return "arith_basic"


# ---- Pre-verdicts -------------------------------------------------------------
#
# (category, sub_bucket) → (verdict, one-line note). Verdicts:
#   variety       — math already covered by our generators; phrasing variety
#   gap-fill      — math not yet covered; high value
#   skip          — within K-8 in principle but per-item filter cost too high
#   out_of_scope  — outside CCSS K-8
PRE_VERDICTS: dict[tuple[str, str], tuple[str, str]] = {
    # ---- general (pre-algebra / mixed arithmetic / ratios) ----
    ("general", "arith_basic"): (
        "variety",
        "Mixed G6–G8 pre-algebra / ratio word problems. Variety candidate "
        "for `add_word_problems_within_100`, `add_sub_2step_word_problems`, "
        "`mult_div_word_2step`, `ratio_table`, `unit_rate_with_fractions`. "
        "Heavy filtering: drop items with K–5-out-of-range numbers, drop "
        "HS-level phrasings, drop items whose only correct option is "
        "'none of these'.",
    ),
    ("general", "arith_power"): (
        "variety",
        "Exponentiation items, K–8 reach only via G8 (8.EE.A.1) basic "
        "exponents. Most items here will be HS-level — filter required.",
    ),
    ("general", "arith_sqrt"): (
        "variety",
        "Square-root items; K–8 only via G8 (8.EE.A.2, perfect squares). "
        "Filter for perfect-square radicand.",
    ),
    ("general", "arith_log_fact"): (
        "out_of_scope",
        "Logarithms and factorials are HS+ in CCSS.",
    ),
    ("general", "arith_gcd_lcm"): (
        "variety",
        "G6 number theory (6.NS.B.4). Overlap with DeepMind gcd / lcm "
        "submodules — secondary source.",
    ),
    ("general", "geom_2d_encoded"): (
        "review",
        "Tiny — likely mis-categorized geometry items. Merge into geometry "
        "verdict during ingestion, or skip.",
    ),
    ("general", "geom_3d_encoded"): (
        "review",
        "Tiny — likely mis-categorized.",
    ),
    ("general", "prob"): (
        "review",
        "Tiny — likely mis-categorized.",
    ),

    # ---- physics (out-of-scope by category, but math may be K-8) ----
    ("physics", "arith_basic"): (
        "skip",
        "Physics word problems (d=rt, work, stream/current, projectile). "
        "Even when the underlying math is K–8 the framing is HS physics-"
        "class style; mismatch with our K–8 audience. Filter cost too high "
        "for the slice that remains.",
    ),
    ("physics", "physics_encoded"): (
        "skip",
        "Explicit speed / work / stream ops. Same HS-physics framing.",
    ),
    ("physics", "arith_power"): (
        "out_of_scope",
        "Likely projectile / freefall — HS.",
    ),
    ("physics", "arith_sqrt"): (
        "out_of_scope",
        "Likely projectile / freefall — HS.",
    ),
    ("physics", "geom_2d_encoded"): (
        "review",
        "Tiny — likely mis-categorized.",
    ),
    ("physics", "geom_3d_encoded"): (
        "review",
        "Tiny — likely mis-categorized.",
    ),

    # ---- gain (profit / loss / interest / discount → G7 percent applications) ----
    ("gain", "arith_basic"): (
        "variety",
        "G7 percent applications (7.RP.A.3 — discount, markup, tax, "
        "simple interest, percent change). Strong fit. Filter for "
        "exact-decimal answers and drop items where 'none of these' is "
        "the correct choice.",
    ),
    ("gain", "gain_encoded"): (
        "variety",
        "Same scope — explicit gain ops. Tiny bucket.",
    ),
    ("gain", "arith_power"): (
        "review",
        "Compound interest is HS; simple interest is G7. Need to inspect.",
    ),
    ("gain", "arith_sqrt"): (
        "out_of_scope",
        "Likely compound-interest reversing — HS.",
    ),
    ("gain", "geom_2d_encoded"): (
        "review",
        "Mis-categorized.",
    ),

    # ---- geometry (G6–G8 geometry — but MD-ES flagged 5–10% mislabeled) ----
    ("geometry", "arith_basic"): (
        "review",
        "65% of `geometry` items land here — formula is arithmetic-shaped, "
        "not encoded geometry. Some are valid (e.g. `area / length = width`); "
        "some are non-geometry mis-categorizations (MD-ES audit flagged a "
        "resistance-in-parallel item leaking in). Manual filter required.",
    ),
    ("geometry", "geom_2d_encoded"): (
        "variety",
        "Cleanest 2D-geometry slice. Strong fit for `area_rectangle_*`, "
        "`area_triangle`, `area_circle`, `circle_circumference`, "
        "`area_parallelogram_trapezoid`, `perimeter_polygon`. Variety on "
        "top of our existing G3–G7 area/perimeter generators.",
    ),
    ("geometry", "geom_3d_encoded"): (
        "variety",
        "3D geometry — fits `volume_rect_prism_formula`, `volume_unit_cubes`, "
        "`surface_area_from_net`, `volume_cylinder`, `volume_composite`. "
        "Variety on top of our G5–G6 generators.",
    ),
    ("geometry", "arith_sqrt"): (
        "gap-fill",
        "Likely Pythagorean theorem (G8 — `pythagorean_theorem`, "
        "`pythagorean_apply_3d`) and edge-from-area items. Worth ingesting "
        "if filtering for perfect-square radicands is clean.",
    ),
    ("geometry", "arith_power"): (
        "variety",
        "Area = side² / volume = side³ shaped without the encoded op. "
        "Variety on existing area/volume generators.",
    ),

    # ---- other (catch-all) ----
    ("other", "arith_basic"): (
        "review",
        "Catch-all. Need to sample to figure out what's actually here.",
    ),
    ("other", "prob"): (
        "review",
        "Probability items mis-categorized into 'other'?",
    ),

    # ---- probability (G7 — 7.SP.C) ----
    ("probability", "prob"): (
        "variety",
        "Explicit prob ops. G7 fit for `probability_simple_event`, "
        "`probability_compound_event`, `simulate_compound`. Note: "
        "permutation / combination beyond a few hundred items per category "
        "is HS — filter for K–8-range inputs.",
    ),
    ("probability", "arith_basic"): (
        "variety",
        "Probability items whose formula is raw arithmetic. Same scope.",
    ),
    ("probability", "arith_power"): (
        "variety",
        "Likely 'probability of event N times in a row' — independent-"
        "events compound probability. G7.",
    ),
    ("probability", "arith_log_fact"): (
        "out_of_scope",
        "Factorial-only probability is HS combinatorics depth.",
    ),
    ("probability", "geom_3d_encoded"): (
        "review",
        "Tiny — geometric probability?",
    ),
}


# ---- Item formatting ----------------------------------------------------------

def parse_options(options_field: str) -> list[str]:
    """Split MathQA's 'a ) 24 , b ) 120 , c ) 625 , d ) 720 , e ) 1024' format."""
    parts = re.split(r"\s*,\s*[a-e]\s*\)\s*", options_field or "")
    if parts:
        parts[0] = re.sub(r"^\s*[a-e]\s*\)\s*", "", parts[0])
    return [p.strip() for p in parts]


def correct_value(item: dict) -> str:
    """Return the actual answer string (not just 'a'/'b'/...)."""
    letter = (item.get("correct") or "").strip().lower()
    if letter not in "abcde":
        return f"<bad-letter:{letter!r}>"
    idx = "abcde".index(letter)
    opts = parse_options(item.get("options", ""))
    if idx >= len(opts):
        return f"<missing-option:{letter}>"
    return opts[idx]


def format_problem(text: str) -> str:
    """Normalize whitespace; truncate for sample display."""
    t = re.sub(r"\s+", " ", text or "").strip()
    if len(t) > 280:
        t = t[:277] + "…"
    return t


# ---- Bucketing ----------------------------------------------------------------

def bucket(items: list[dict]) -> dict[tuple[str, str], list[dict]]:
    out: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for it in items:
        key = (it.get("category", "?"), classify_formula(it.get("annotated_formula", "")))
        out[key].append(it)
    return out


def load_all(data_path: Path) -> list[dict]:
    items: list[dict] = []
    splits = ["train.json", "dev.json", "test.json", "challenge_test.json"]
    for name in splits:
        path = data_path / name
        if not path.is_file():
            print(f"warn: missing {path} — skipping", file=sys.stderr)
            continue
        with path.open() as fh:
            split = json.load(fh)
        for it in split:
            it["_split"] = name.replace(".json", "")
        items.extend(split)
    return items


# ---- Main ---------------------------------------------------------------------

# Category order in the report. Categories not listed here come after, in
# the order they appear in the data.
CATEGORY_ORDER = ["general", "physics", "gain", "geometry", "other", "probability"]

# Sub-bucket order within each category. Same rationale as CATEGORY_ORDER.
SUB_BUCKET_ORDER = [
    "arith_basic",
    "arith_power",
    "arith_sqrt",
    "arith_log_fact",
    "arith_gcd_lcm",
    "geom_2d_encoded",
    "geom_3d_encoded",
    "gain_encoded",
    "physics_encoded",
    "prob",
    "trig",
    "misc_encoded",
]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--data-path",
        type=Path,
        default=Path("/tmp/mathqa"),
        help="Path to the directory containing MathQA's train.json / "
        "dev.json / test.json / challenge_test.json (default /tmp/mathqa).",
    )
    parser.add_argument(
        "--samples",
        type=int,
        default=8,
        help="Number of items to sample per (category, sub_bucket) bucket "
        "(default 8).",
    )
    parser.add_argument("--seed", type=int, default=20260521, help="RNG seed.")
    parser.add_argument(
        "--filter",
        default="",
        help="Substring filter on category or sub-bucket label. Empty = all.",
    )
    args = parser.parse_args()

    if not args.data_path.is_dir():
        print(
            f"error: --data-path {args.data_path} is not a directory. "
            "Download MathQA.zip from https://math-qa.github.io/ and unzip "
            "to that path.",
            file=sys.stderr,
        )
        return 1

    items = load_all(args.data_path)
    buckets = bucket(items)

    rng = random.Random(args.seed)

    print("# MathQA — sampled items per `(category, sub_bucket)` bucket\n")
    print(
        f"Auto-generated by [audit_mathqa.py](../audit_mathqa.py); "
        f"{args.samples} samples per `(category, sub_bucket)` bucket, "
        f"seed={args.seed}. Re-run to refresh.\n"
    )
    print(
        "Pre-verdicts (in italics) are first-pass guesses; the audit pass "
        "in [mathqa.md](mathqa.md) checks each against the actual samples.\n"
    )
    print(
        "**Bucket key:** `(category, sub_bucket)`. `category` is MathQA's "
        "top-level field; `sub_bucket` is computed by inspecting which ops "
        "appear in `annotated_formula` (see the script's "
        "`classify_formula` docstring for the ladder).\n"
    )
    print(
        "**Item display:** problem text → correct option (decoded from "
        "a/b/c/d/e), plus the `annotated_formula` for shape inspection.\n"
    )
    n_total = sum(len(v) for v in buckets.values())
    print(f"**Total items across all four splits:** {n_total:,}\n")

    # Roll-up table at the top so the verdict doc has it handy.
    print("## Cross-tab — counts per `(category, sub_bucket)`\n")
    cats = CATEGORY_ORDER + sorted(set(c for c, _ in buckets) - set(CATEGORY_ORDER))
    subs = SUB_BUCKET_ORDER + sorted(set(s for _, s in buckets) - set(SUB_BUCKET_ORDER))
    header = "| category | " + " | ".join(subs) + " | total |"
    sep = "|" + ("---|" * (len(subs) + 2))
    print(header)
    print(sep)
    for c in cats:
        row = [len(buckets.get((c, s), [])) for s in subs]
        if sum(row) == 0:
            continue
        row_strs = [str(v) if v else "·" for v in row]
        print(f"| {c} | " + " | ".join(row_strs) + f" | **{sum(row):,}** |")
    print()

    print("---\n")
    print("## Samples per bucket\n")
    for c in cats:
        # Header only if at least one sub-bucket exists in this category.
        rows = [s for s in subs if buckets.get((c, s))]
        if not rows:
            continue
        print(f"### Category: `{c}`\n")
        for s in rows:
            key = (c, s)
            if args.filter and args.filter not in c and args.filter not in s:
                continue
            items_here = buckets[key]
            pre_v, note = PRE_VERDICTS.get(
                key,
                ("review", "(no pre-classification — newly added bucket)"),
            )
            print(f"#### `({c}, {s})` — *{pre_v}*  ({len(items_here):,} items)\n")
            print(f"{note}\n")
            picks = rng.sample(items_here, min(args.samples, len(items_here)))
            for it in picks:
                q = format_problem(it.get("Problem", ""))
                a_letter = (it.get("correct") or "").strip().lower()
                a = correct_value(it)
                f = (it.get("annotated_formula") or "").strip()
                print(f"- `{q}`  →  `{a_letter}` (`{a}`)")
                print(f"  - formula: `{f}`")
            print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
