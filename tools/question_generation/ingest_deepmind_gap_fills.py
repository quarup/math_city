#!/usr/bin/env python3
"""Ingest DeepMind's rank #7 gap-fill submodules (per audit deepmind.md):

- ``comparison.closest``      → ``closest_to_target`` (G6 rationals)
- ``comparison.kth_biggest``  → ``kth_value_in_list`` (G6 rationals)
- ``comparison.sort``         → ``sort_rationals``    (G6 rationals)
- ``polynomials.evaluate``    → ``function_evaluate_at_point`` (G8 prealgebra)

These are runtime-blocked on three things that landed alongside this
ingester:

- **Value-MC normalisation** for closest / kth_biggest. DeepMind ships
  items with letter-keyed candidates ("(a) 1/6  (b) 28 ..." → "a"); we
  strip the letters at ingest, lift the labelled value into
  ``correct_answer``, and use the remaining values as distractors, so
  the items flow through the existing shuffled-value-MC widget unchanged.
  The "What is the nearest to T in X, Y, Z?" variant DeepMind also emits
  is already value-form and doesn't need this step.

- **AnswerFormat.commaList** for sort. The answer is a comma-separated
  ordered list; ``checkAnswer`` parses each entry as int/Fraction/Decimal
  and compares entry-wise. We emit ``answer_format: "commaList"`` so the
  runtime gates keypad off and forces MC even at the comfortable band.
  Distractor orderings: reverse, adjacent-swap, sign-flip (each generated
  systematically so MC remains pedagogical — the kid still has to spot
  the mis-orderings).

- **Math-notation prompt rewrite** for polynomials.evaluate. ``11*h``
  becomes ``11h`` (implicit multiplication); ``b**2`` becomes ``b²``;
  the ASCII hyphen-minus becomes U+2212. Cubics and higher are filtered
  out — out of G8 scope.

Re-runs are deterministic per ``--seed`` and idempotent (per-submodule
merge replaces only this submodule's rows in each output JSON).
"""

from __future__ import annotations

import argparse
import random
import re
import sys
from collections import defaultdict
from fractions import Fraction
from pathlib import Path

from deepmind_common import (
    OUTPUT_DIR,
    build_item,
    item_id,
    write_buckets,
)

MODULE_CLOSEST = "comparison.closest"
MODULE_KTH = "comparison.kth_biggest"
MODULE_SORT = "comparison.sort"
MODULE_POLY_EVAL = "polynomials.evaluate"

CONCEPT_CLOSEST = "closest_to_target"
CONCEPT_KTH = "kth_value_in_list"
CONCEPT_SORT = "sort_rationals"
CONCEPT_POLY_EVAL = "function_evaluate_at_point"

# Replace ASCII hyphen-minus with Unicode minus in every emitted prompt /
# answer / distractor string. Matches the convention set by Chunk 80
# (``arithmetic.add_or_sub``).
MINUS = "−"


def _normalise_minus(s: str) -> str:
    return s.replace("-", MINUS)


def _parse_value(token: str) -> Fraction | None:
    """Parse a single DeepMind value token (``"1/6"``, ``"-0.5"``, ``"3"``,
    ``"-0.048"``) as an exact :class:`fractions.Fraction`.

    Returns None on non-numeric input.
    """
    token = token.strip()
    if not token:
        return None
    # Decimal with optional sign and optional fractional part.
    m = re.fullmatch(r"(-?)(\d+)(?:\.(\d+))?", token)
    if m:
        sign = -1 if m.group(1) == "-" else 1
        whole = m.group(2)
        frac = m.group(3) or ""
        digits = whole + frac
        return Fraction(sign * int(digits), 10 ** len(frac))
    # Plain fraction a/b (numerator may be signed).
    m = re.fullmatch(r"(-?\d+)/(-?\d+)", token)
    if m:
        n = int(m.group(1))
        d = int(m.group(2))
        if d == 0:
            return None
        return Fraction(n, d)
    return None


def _values_from_csv(s: str) -> list[str] | None:
    """Split a "X, Y, Z" run; verify every token parses. Return tokens
    (with their original surface form preserved) or None on parse fail."""
    parts = [p.strip() for p in s.split(",")]
    if any(not p for p in parts):
        return None
    if any(_parse_value(p) is None for p in parts):
        return None
    return parts


# ---------------------------------------------------------------------------
# comparison.closest
# ---------------------------------------------------------------------------

# Letter-MC form:   "Which is the {nearest|closest} to {target}? (a) X (b) Y ..."
CLOSEST_LETTER_RE = re.compile(
    r"^Which is the (?:nearest|closest) to (?P<target>[\-\d/.]+)\?"
    r"\s+(?P<choices>(?:\([a-z]\)\s+[\-\d/.]+\s*)+)$"
)
# Value-MC form:    "What is the {nearest|closest} to {target} in X, Y, Z?"
CLOSEST_VALUE_RE = re.compile(
    r"^What is the (?:nearest|closest) to (?P<target>[\-\d/.]+) in "
    r"(?P<csv>[\-\d/., ]+)\?$"
)
LETTER_CHOICE_RE = re.compile(r"\(([a-z])\)\s+([\-\d/.]+)")


def _parse_closest(prompt: str, answer: str) -> tuple[str, str, list[str]] | None:
    """Return (target, correct_value, other_values) or None if unparseable
    or the answer letter does not point to a value present in the choices."""
    m = CLOSEST_LETTER_RE.match(prompt)
    if m:
        target = m.group("target")
        choices = LETTER_CHOICE_RE.findall(m.group("choices"))
        letter_to_value = {lt: v for lt, v in choices}
        if answer not in letter_to_value:
            return None
        correct = letter_to_value[answer]
        others = [v for lt, v in choices if lt != answer]
        return target, correct, others

    m = CLOSEST_VALUE_RE.match(prompt)
    if m:
        target = m.group("target")
        values = _values_from_csv(m.group("csv"))
        if values is None or answer not in values:
            return None
        others = [v for v in values if v != answer]
        return target, answer, others
    return None


def _verify_closest(target: str, correct: str, others: list[str]) -> bool:
    """Check that ``correct`` truly minimises ``|v - target|`` among all
    candidates. DeepMind is reliable, but defence-in-depth is cheap."""
    t = _parse_value(target)
    c = _parse_value(correct)
    if t is None or c is None:
        return False
    best_dist = abs(c - t)
    for o in others:
        ov = _parse_value(o)
        if ov is None:
            return False
        if abs(ov - t) < best_dist:
            return False  # another candidate is strictly closer
    return True


def ingest_closest(n_target, rand):
    from mathematics_dataset.modules import comparison

    def ent(r):
        return r

    gen = comparison.train(ent)["closest"]
    buckets: dict[str, list[dict]] = defaultdict(list)
    stats = defaultdict(int)
    seen: set[str] = set()
    attempts = 0
    while len(buckets[CONCEPT_CLOSEST]) < n_target and attempts < n_target * 50:
        attempts += 1
        ex = gen()
        prompt = str(ex.question)
        answer = str(ex.answer)
        parsed = _parse_closest(prompt, answer)
        if parsed is None:
            stats["rejected_parse"] += 1
            continue
        target, correct, others = parsed
        if len(others) < 3:
            stats["rejected_too_few_choices"] += 1
            continue
        if not _verify_closest(target, correct, others):
            stats["rejected_verify"] += 1
            continue
        # Pick 3 distractors deterministically (sorted then shuffle) from
        # the other values so we don't surface 5-button MC.
        others_sorted = sorted(others, key=lambda v: (v, len(v)))
        rand_shuffled = list(others_sorted)
        rand.shuffle(rand_shuffled)
        distractors = rand_shuffled[:3]

        # Normalise the prompt to a value-MC form: the candidates appear as
        # the 4 MC buttons, so the prompt itself only needs the stem.
        new_prompt = _normalise_minus(
            f"Which is the closest to {target}?"
        )
        correct_str = _normalise_minus(correct)
        distractors_str = [_normalise_minus(d) for d in distractors]

        # Dedupe on content (target + correct + sorted distractors), not
        # the prompt stem alone — different items can share a stem.
        dedup_key = (
            new_prompt + "|" + correct_str + "|"
            + ",".join(sorted(distractors_str))
        )
        if dedup_key in seen:
            stats["rejected_duplicate"] += 1
            continue
        seen.add(dedup_key)

        explanation = [
            f"Among the choices, {correct_str} is the closest to "
            f"{_normalise_minus(target)}."
        ]

        buckets[CONCEPT_CLOSEST].append(
            build_item(
                id=item_id(prompt, prefix="closest"),
                concept_id=CONCEPT_CLOSEST,
                prompt=new_prompt,
                correct_answer=correct_str,
                distractors=distractors_str,
                explanation=explanation,
                source_module=MODULE_CLOSEST,
            )
        )
        stats["accepted"] += 1
    stats["attempts"] = attempts
    return dict(buckets), dict(stats)


# ---------------------------------------------------------------------------
# comparison.kth_biggest
# ---------------------------------------------------------------------------

KTH_LETTER_RE = re.compile(
    r"^Which is the (?:(?P<ordinal>[a-z]+)\s+)?(?P<direction>biggest|smallest)"
    r"\s+value\?\s+(?P<choices>(?:\([a-z]\)\s+[\-\d/.]+\s*)+)$"
)
KTH_VALUE_RE = re.compile(
    r"^What is the (?:(?P<ordinal>[a-z]+)\s+)?(?P<direction>biggest|smallest)"
    r"\s+value in (?P<csv>[\-\d/., ]+)\?$"
)

ORDINAL_TO_K = {
    "first": 1, "second": 2, "third": 3, "fourth": 4, "fifth": 5,
    "sixth": 6, "seventh": 7, "eighth": 8, "ninth": 9, "tenth": 10,
}


def _parse_kth(prompt: str, answer: str):
    """Return (ordinal_phrase, direction, correct, others) or None.

    The ordinal phrase is the empty string when DeepMind omits it (k=1
    items use just "Which is the biggest value?"); callers re-render the
    prompt accordingly.
    """
    m = KTH_LETTER_RE.match(prompt)
    if m:
        ordinal_raw = m.group("ordinal")
        direction = m.group("direction")
        ordinal, k = _normalise_ordinal(ordinal_raw)
        if k is None:
            return None
        choices = LETTER_CHOICE_RE.findall(m.group("choices"))
        letter_to_value = {lt: v for lt, v in choices}
        if answer not in letter_to_value:
            return None
        correct = letter_to_value[answer]
        others = [v for lt, v in choices if lt != answer]
        return ordinal, direction, k, correct, others

    m = KTH_VALUE_RE.match(prompt)
    if m:
        ordinal_raw = m.group("ordinal")
        direction = m.group("direction")
        ordinal, k = _normalise_ordinal(ordinal_raw)
        if k is None:
            return None
        values = _values_from_csv(m.group("csv"))
        if values is None or answer not in values:
            return None
        others = [v for v in values if v != answer]
        return ordinal, direction, k, answer, others
    return None


def _normalise_ordinal(raw: str | None) -> tuple[str, int | None]:
    """Map DeepMind's ordinal phrase to (display_phrase, k). When raw is
    None or empty the item is implicitly k=1 — return ``("", 1)``."""
    if raw is None or raw == "":
        return "", 1
    raw = raw.lower()
    k = ORDINAL_TO_K.get(raw)
    if k is None:
        return raw, None
    return raw, k


def _verify_kth(k: int, direction: str, correct: str,
                others: list[str]) -> bool:
    """Verify the answer is truly the kth (biggest|smallest) among the
    combined candidate set."""
    all_strs = [correct] + others
    parsed = [(s, _parse_value(s)) for s in all_strs]
    if any(v is None for _, v in parsed):
        return False
    # Sort descending for "biggest", ascending for "smallest".
    parsed.sort(key=lambda sv: sv[1], reverse=(direction == "biggest"))
    if k > len(parsed):
        return False
    # k is 1-indexed; the kth pick must equal ``correct``.
    return parsed[k - 1][0] == correct


def _synth_compare_distractor(
    correct: str, existing: list[str], rand: random.Random,
) -> str | None:
    """Synthesise one extra plausible distractor for a 3-choice item.

    Strategy: jitter the correct value by ±1 (if integer), flip its sign
    (if signed), or fall back to a small whole-number guess that isn't
    already present.
    """
    cv = _parse_value(correct)
    if cv is None:
        return None
    taken = {correct} | set(existing)

    def _emit(v: Fraction) -> str | None:
        if v.denominator == 1:
            s = str(int(v))
        else:
            s = f"{v.numerator}/{v.denominator}"
        return s if s not in taken else None

    # ±1, ±2, sign-flip — first non-collision wins.
    for delta in (1, -1, 2, -2):
        cand = _emit(cv + delta)
        if cand:
            return cand
    cand = _emit(-cv)
    if cand:
        return cand
    for i in range(1, 50):
        cand = _emit(Fraction(rand.choice((-1, 1)) * i))
        if cand:
            return cand
    return None


def ingest_kth(n_target, rand):
    from mathematics_dataset.modules import comparison

    def ent(r):
        return r

    gen = comparison.train(ent)["kth_biggest"]
    buckets: dict[str, list[dict]] = defaultdict(list)
    stats = defaultdict(int)
    seen: set[str] = set()
    attempts = 0
    while len(buckets[CONCEPT_KTH]) < n_target and attempts < n_target * 60:
        attempts += 1
        ex = gen()
        prompt = str(ex.question)
        answer = str(ex.answer)
        parsed = _parse_kth(prompt, answer)
        if parsed is None:
            stats["rejected_parse"] += 1
            continue
        ordinal, direction, k, correct, others = parsed
        if len(others) < 2:
            stats["rejected_too_few_choices"] += 1
            continue
        if not _verify_kth(k, direction, correct, others):
            stats["rejected_verify"] += 1
            continue
        # Pick up to 3 distractors from the listed candidates; if DeepMind
        # only gave us 2 (3-choice items are common), synthesise a third
        # by perturbing the correct value (jitter for integers, swapping
        # sign for negatives — anything plausible in the comparison space).
        others_sorted = sorted(others, key=lambda v: (v, len(v)))
        rand_shuffled = list(others_sorted)
        rand.shuffle(rand_shuffled)
        distractors = rand_shuffled[:3]
        if len(distractors) < 3:
            extra = _synth_compare_distractor(correct, distractors, rand)
            if extra is None:
                stats["rejected_distractor_short"] += 1
                continue
            distractors.append(extra)

        # Re-emit the prompt in letter-free form: the 4 MC buttons carry
        # the candidate values, so we only need the question stem +
        # ordinal+direction. For k=1 items DeepMind drops the ordinal
        # entirely; preserve that ("Which is the biggest value?").
        ordinal_phrase = f"{ordinal} " if ordinal else ""
        new_prompt = (
            f"Which is the {ordinal_phrase}{direction} value?"
        )
        correct_str = _normalise_minus(correct)
        distractors_str = [_normalise_minus(d) for d in distractors]

        # Dedupe on the *content* (correct + sorted distractors), not the
        # stem — many items share "Which is the biggest value?".
        dedup_key = (
            new_prompt + "|" + correct_str + "|"
            + ",".join(sorted(distractors_str))
        )
        if dedup_key in seen:
            stats["rejected_duplicate"] += 1
            continue
        seen.add(dedup_key)

        explanation = [
            f"Ordered, the {ordinal_phrase}{direction} value is {correct_str}."
        ]

        buckets[CONCEPT_KTH].append(
            build_item(
                id=item_id(prompt, prefix="kth"),
                concept_id=CONCEPT_KTH,
                prompt=new_prompt,
                correct_answer=correct_str,
                distractors=distractors_str,
                explanation=explanation,
                source_module=MODULE_KTH,
            )
        )
        stats["accepted"] += 1
    stats["attempts"] = attempts
    return dict(buckets), dict(stats)


# ---------------------------------------------------------------------------
# comparison.sort
# ---------------------------------------------------------------------------

SORT_RE = re.compile(
    r"^(?:Sort|Put)\s+(?P<csv>[\-\d/., ]+?)"
    r"(?:\s+in\s+(?P<direction>increasing|ascending|decreasing|descending)"
    r"(?:\s+order)?)?\.$"
)


def _verify_sort(values: list[str], answer_list: list[str],
                  direction: str) -> bool:
    """Check that ``answer_list`` is exactly the sort of ``values``."""
    if sorted(values) != sorted(answer_list):
        return False
    parsed = [(s, _parse_value(s)) for s in values]
    if any(v is None for _, v in parsed):
        return False
    parsed.sort(key=lambda sv: sv[1], reverse=(direction == "descending"))
    return [s for s, _ in parsed] == answer_list


def _build_sort_distractor_orderings(
    correct_list: list[str], direction: str, rand: random.Random,
) -> list[str]:
    """Return 3 incorrect orderings of the same values, each as a
    comma-string. Strategies, applied in order until 3 distinct candidates
    are collected:

    - **reversed** — flip ascending↔descending
    - **adjacent swaps** — swap each pair in turn
    - **fully shuffled** — for the fallback / 3+ value list cases
    """
    candidates: list[list[str]] = []
    seen: set[tuple[str, ...]] = {tuple(correct_list)}

    def add(ordering: list[str]) -> None:
        key = tuple(ordering)
        if key in seen:
            return
        seen.add(key)
        candidates.append(ordering)

    # Reversed.
    add(list(reversed(correct_list)))

    # Adjacent-swap variants.
    if len(correct_list) >= 2:
        positions = list(range(len(correct_list) - 1))
        rand.shuffle(positions)
        for i in positions:
            swapped = list(correct_list)
            swapped[i], swapped[i + 1] = swapped[i + 1], swapped[i]
            add(swapped)
            if len(candidates) >= 3:
                break

    # Fully random shuffles as last resort.
    safety = 0
    while len(candidates) < 3 and safety < 40:
        safety += 1
        shuffled = list(correct_list)
        rand.shuffle(shuffled)
        add(shuffled)

    if len(candidates) < 3:
        return []  # not enough distinct orderings — caller filters
    return [", ".join(_normalise_minus(s) for s in c) for c in candidates[:3]]


def ingest_sort(n_target, rand):
    from mathematics_dataset.modules import comparison

    def ent(r):
        return r

    gen = comparison.train(ent)["sort"]
    buckets: dict[str, list[dict]] = defaultdict(list)
    stats = defaultdict(int)
    seen: set[str] = set()
    attempts = 0
    while len(buckets[CONCEPT_SORT]) < n_target and attempts < n_target * 50:
        attempts += 1
        ex = gen()
        prompt = str(ex.question)
        answer = str(ex.answer)
        m = SORT_RE.match(prompt)
        if m is None:
            stats["rejected_parse"] += 1
            continue
        values_csv = m.group("csv")
        direction_raw = (m.group("direction") or "ascending").lower()
        direction = "ascending" if direction_raw in {
            "increasing", "ascending"
        } else "descending"
        values = _values_from_csv(values_csv)
        if values is None:
            stats["rejected_parse"] += 1
            continue
        answer_list = _values_from_csv(answer)
        if answer_list is None:
            stats["rejected_answer_parse"] += 1
            continue
        if not _verify_sort(values, answer_list, direction):
            stats["rejected_verify"] += 1
            continue
        if len(answer_list) < 3:
            # 2-value sorts are essentially compare_pair items — skip.
            stats["rejected_too_short"] += 1
            continue

        correct_str = ", ".join(_normalise_minus(s) for s in answer_list)
        distractors = _build_sort_distractor_orderings(
            answer_list, direction, rand,
        )
        if len(distractors) < 3:
            stats["rejected_distractor_short"] += 1
            continue

        # Re-emit the prompt with normalised punctuation. Direction stays
        # textual ("in ascending order.") so the kid knows which way to go.
        values_norm = ", ".join(_normalise_minus(v) for v in values)
        order_phrase = (
            "ascending order" if direction == "ascending" else "descending order"
        )
        new_prompt = f"Sort {values_norm} in {order_phrase}."

        if new_prompt in seen:
            stats["rejected_duplicate"] += 1
            continue
        seen.add(new_prompt)

        explanation = [
            f"In {order_phrase}: {correct_str}.",
        ]

        item = build_item(
            id=item_id(prompt, prefix="sort"),
            concept_id=CONCEPT_SORT,
            prompt=new_prompt,
            correct_answer=correct_str,
            distractors=distractors,
            explanation=explanation,
            source_module=MODULE_SORT,
        )
        item["answer_format"] = "commaList"
        buckets[CONCEPT_SORT].append(item)
        stats["accepted"] += 1
    stats["attempts"] = attempts
    return dict(buckets), dict(stats)


# ---------------------------------------------------------------------------
# polynomials.evaluate
# ---------------------------------------------------------------------------

# "Let z(h) = 203 - 11*h. Calculate z(12)."
POLY_EVAL_RE = re.compile(
    r"^Let\s+(?P<fname>[a-z])\((?P<var>[a-z])\)\s*=\s*(?P<body>[^\.]+?)\.\s+"
    r"(?:Calculate|Determine|Give|What is|Compute|Evaluate)\s+"
    r"(?P<fname2>[a-z])\((?P<input>-?\d+)\)\?*\.?$",
    re.IGNORECASE,
)

# Maximum exponent: 2 keeps simple quadratics; drop cubics+ per design.
MAX_EXPONENT = 2
# Caps on coefficients and input value — DeepMind defaults go far past
# anything reasonable for a kid doing this mentally; cap to keep arithmetic
# feasible without paper.
MAX_COEFF_ABS = 50
MAX_INPUT_ABS = 20
MAX_ANSWER_ABS = 5000


# Translate "a*x**n" into "ax^n" (visual) and "a*x**n" into AST for evaluation.

def _strip_explicit_mul(body: str) -> str:
    """``11*h`` → ``11h``;  ``-11*h`` → ``-11h``.  Leave ``**2`` alone."""
    # Match coefficient * variable (the variable is a single letter,
    # optionally followed by **N).
    return re.sub(r"(\d)\*([a-z])", r"\1\2", body)


def _superscript_powers(body: str) -> str:
    """``h**2`` → ``h²``;  ``h**3`` → ``h³``.  Only digits 0-9 supported."""
    table = str.maketrans("0123456789", "⁰¹²³⁴⁵⁶⁷⁸⁹")

    def repl(m):
        return m.group(1) + m.group(2).translate(table)

    return re.sub(r"([a-z])\*\*(\d+)", repl, body)


def _parse_poly_body(body: str, var: str) -> list[tuple[int, int]] | None:
    """Parse a polynomial body of the form ``a*x**n + b*x + c`` and return
    a list of (coefficient, exponent) terms, or None on failure / out of
    scope. Each coefficient is an exact int; exponents are non-negative
    ints; ``MAX_EXPONENT`` is enforced.
    """
    body = body.replace(" ", "")
    if not body:
        return None
    # Split into signed terms by inserting "+" before each "-" that's not
    # at the very start. Resulting tokens still carry their sign.
    if body[0] == "+":
        body = body[1:]
    tokens: list[str] = []
    buf = body[0]
    for ch in body[1:]:
        if ch in "+-":
            tokens.append(buf)
            buf = ""
            if ch == "-":
                buf = "-"
        else:
            buf += ch
    if buf:
        tokens.append(buf)

    terms: list[tuple[int, int]] = []
    for tok in tokens:
        if not tok or tok in "+-":
            return None
        # Patterns we accept:
        #   "5", "-5", "5*x**2", "-5*x**2", "x**2", "-x**2", "5*x", "x", "-x".
        m = re.fullmatch(
            r"(?P<sign>[+-]?)(?P<coef>\d+)?\*?(?P<var>[a-z])?"
            r"(?:\*\*(?P<exp>\d+))?",
            tok,
        )
        if m is None or m.group(0) == "":
            return None
        sign = -1 if m.group("sign") == "-" else 1
        coef_str = m.group("coef")
        var_token = m.group("var")
        exp_str = m.group("exp")
        # Pure constant.
        if var_token is None:
            if coef_str is None:
                return None
            terms.append((sign * int(coef_str), 0))
            continue
        if var_token != var:
            return None
        coef = sign * (int(coef_str) if coef_str is not None else 1)
        exp = int(exp_str) if exp_str is not None else 1
        terms.append((coef, exp))
    return terms


def _eval_poly(terms: list[tuple[int, int]], x: int) -> int:
    total = 0
    for c, e in terms:
        total += c * (x ** e)
    return total


def _format_term(coef: int, exp: int, var: str, is_first: bool) -> str:
    """Format one term ``coef * var^exp`` with sign joined as a leading
    operator. ``is_first`` controls whether a positive leading coefficient
    drops its '+'.
    """
    abs_c = abs(coef)
    if exp == 0:
        body = str(abs_c)
    elif exp == 1:
        body = var if abs_c == 1 else f"{abs_c}{var}"
    else:
        sup = str(exp).translate(
            str.maketrans("0123456789",
                          "⁰¹²³⁴⁵⁶⁷⁸⁹"),
        )
        body = f"{var}{sup}" if abs_c == 1 else f"{abs_c}{var}{sup}"
    if is_first:
        return f"{MINUS}{body}" if coef < 0 else body
    sep = f" {MINUS} " if coef < 0 else " + "
    return sep + body


def _format_polynomial(terms: list[tuple[int, int]], var: str) -> str:
    # Drop zero-coefficient terms; keep at most one constant.
    nonzero = [(c, e) for c, e in terms if c != 0]
    if not nonzero:
        return "0"
    # Sort descending by exponent for canonical layout.
    nonzero.sort(key=lambda ce: -ce[1])
    parts = [_format_term(c, e, var, is_first=(i == 0))
             for i, (c, e) in enumerate(nonzero)]
    return "".join(parts)


def _build_poly_distractors(terms, x, correct, rand):
    """Three integer distractors representing common misconception
    answers:

    - ``f(-x)`` — used the wrong-sign input.
    - ``|coef of x| * x + const`` — forgot to square (for quadratic items).
    - ``correct ± small jitter`` — arithmetic slip.
    """
    candidates: list[int] = []

    def add(v: int) -> None:
        if v == correct or v in candidates:
            return
        if abs(v) > MAX_ANSWER_ABS:
            return
        candidates.append(v)

    # f(-x)
    add(_eval_poly(terms, -x))
    # Forgot to square: replace exponent>=2 terms with c*x.
    if any(e >= 2 for _, e in terms):
        linear_terms = [(c, 1 if e >= 1 else 0) for c, e in terms]
        add(_eval_poly(linear_terms, x))
    # Sign-flipped answer.
    add(-correct)
    # Off-by-one slips.
    for delta in (1, -1, 2, -2, 5, -5):
        add(correct + delta)
        if len(candidates) >= 6:
            break
    # Random jitter as final fallback.
    safety = 0
    while len(candidates) < 3 and safety < 30:
        safety += 1
        add(correct + rand.choice((-1, 1)) * rand.randint(1, 20))
    if len(candidates) < 3:
        return []
    rand.shuffle(candidates)
    return [str(v) for v in candidates[:3]]


def ingest_poly_eval(n_target, rand):
    from mathematics_dataset.modules import polynomials

    def ent(r):
        return r

    gen = polynomials.train(ent)["evaluate"]
    buckets: dict[str, list[dict]] = defaultdict(list)
    stats = defaultdict(int)
    seen: set[str] = set()
    attempts = 0
    while (
        len(buckets[CONCEPT_POLY_EVAL]) < n_target
        and attempts < n_target * 100
    ):
        attempts += 1
        ex = gen()
        prompt = str(ex.question)
        answer = str(ex.answer)
        m = POLY_EVAL_RE.match(prompt)
        if m is None:
            stats["rejected_parse"] += 1
            continue
        if m.group("fname") != m.group("fname2"):
            stats["rejected_name_mismatch"] += 1
            continue
        fname = m.group("fname")
        var = m.group("var")
        body = m.group("body").strip()
        try:
            x = int(m.group("input"))
        except ValueError:
            stats["rejected_input_nonint"] += 1
            continue
        try:
            ans = int(answer)
        except ValueError:
            stats["rejected_answer_nonint"] += 1
            continue

        terms = _parse_poly_body(body, var)
        if terms is None:
            stats["rejected_body_parse"] += 1
            continue
        if any(e > MAX_EXPONENT for _, e in terms):
            stats["rejected_too_high_degree"] += 1
            continue
        if any(abs(c) > MAX_COEFF_ABS for c, _ in terms):
            stats["rejected_coef_too_big"] += 1
            continue
        if abs(x) > MAX_INPUT_ABS:
            stats["rejected_input_too_big"] += 1
            continue
        if abs(ans) > MAX_ANSWER_ABS:
            stats["rejected_answer_too_big"] += 1
            continue
        if _eval_poly(terms, x) != ans:
            stats["rejected_verify"] += 1
            continue

        poly_str = _format_polynomial(terms, var)
        input_str = f"{MINUS}{abs(x)}" if x < 0 else str(x)
        new_prompt = (
            f"Let {fname}({var}) = {poly_str}. "
            f"Calculate {fname}({input_str})."
        )

        if new_prompt in seen:
            stats["rejected_duplicate"] += 1
            continue
        seen.add(new_prompt)

        distractors = _build_poly_distractors(terms, x, ans, rand)
        if len(distractors) < 3:
            stats["rejected_distractor_short"] += 1
            continue

        answer_str = f"{MINUS}{abs(ans)}" if ans < 0 else str(ans)
        distractors_norm = [
            (f"{MINUS}{d[1:]}" if d.startswith("-") else d) for d in distractors
        ]

        explanation = [
            f"Substitute {var} = {input_str}:",
            f"{fname}({input_str}) = {answer_str}.",
        ]

        buckets[CONCEPT_POLY_EVAL].append(
            build_item(
                id=item_id(prompt, prefix="polyeval"),
                concept_id=CONCEPT_POLY_EVAL,
                prompt=new_prompt,
                correct_answer=answer_str,
                distractors=distractors_norm,
                explanation=explanation,
                source_module=MODULE_POLY_EVAL,
            )
        )
        stats["accepted"] += 1
    stats["attempts"] = attempts
    return dict(buckets), dict(stats)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

INGESTERS = (
    ("closest", MODULE_CLOSEST, ingest_closest),
    ("kth_biggest", MODULE_KTH, ingest_kth),
    ("sort", MODULE_SORT, ingest_sort),
    ("polynomials_evaluate", MODULE_POLY_EVAL, ingest_poly_eval),
)


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
        choices=[name for name, _, _ in INGESTERS] + ["all"],
        default="all",
    )
    args = parser.parse_args()

    rand = random.Random(args.seed)
    random.seed(args.seed)

    for name, module, fn in INGESTERS:
        if args.only != "all" and args.only != name:
            continue
        print(f"\n=== {module} ===", file=sys.stderr)
        buckets, stats = fn(args.items_per_concept, rand)
        for cid, items in sorted(buckets.items()):
            print(f"  {cid:36s} {len(items):4d}", file=sys.stderr)
        for k, v in stats.items():
            print(f"  [stat] {k:28s} {v}", file=sys.stderr)
        write_buckets(buckets, source_module=module, dry_run=args.dry_run)

    return 0


if __name__ == "__main__":
    sys.exit(main())
