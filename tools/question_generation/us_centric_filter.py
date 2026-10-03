#!/usr/bin/env python3
"""Drop bundled dataset items that only make sense to a US reader.

Math City is played by kids anywhere, so a word problem priced in
dollars, measured in feet or pounds, or set at Thanksgiving in Texas is
out. GSM8K (US-authored) is the source of nearly all such items; the
DeepMind items are synthetic and never trip the filter.

Two uses:

- **Ingest-time:** ``ingest_gsm8k.py`` (and the DeepMind writer in
  ``deepmind_common.py``) call :func:`item_us_centric_reason` and skip
  any item it flags, so re-ingestion applies the same rule.
- **In place:** running this file filters the already-bundled JSONs
  under ``assets/data/dataset_questions/``. Kept items stay
  byte-identical: each file is re-serialised with its own detected
  indent / ``ensure_ascii`` setting, and a file whose formatting can't
  be reproduced exactly is left alone. Idempotent — a second run is a
  no-op.

Usage::

    python3 tools/question_generation/us_centric_filter.py [--dry-run] [--verbose]

The rule errs toward dropping: a false positive costs one item out of
hundreds; a false negative puts "$" or "miles" in front of a child who
has never used either.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parents[2] / "assets" / "data" / "dataset_questions"

_NUM_WORDS = (
    r"one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|"
    r"fifteen|twenty|thirty|forty|fifty|hundred|thousand"
)

# US states and big cities. Names that double as common first names in
# GSM8K (Dallas, Denver, Washington, Georgia, Virginia, Indiana, Austin,
# Phoenix, ...) are left out on purpose: "If Dallas has 21 marbles" is
# a person.
_US_PLACES = (
    r"Alabama|Alaska|Arizona|Arkansas|California|Colorado|Connecticut|"
    r"Delaware|Florida|Hawaii|Idaho|Illinois|Iowa|Kansas|Kentucky|"
    r"Louisiana|Maryland|Massachusetts|Michigan|Minnesota|Mississippi|"
    r"Missouri|Nebraska|Nevada|New Hampshire|New Jersey|New Mexico|"
    r"New York|North Carolina|North Dakota|Ohio|Oklahoma|Oregon|"
    r"Pennsylvania|Rhode Island|South Carolina|South Dakota|Tennessee|"
    r"Texas|Utah|Vermont|West Virginia|Wisconsin|Wyoming|"
    r"Chicago|Los Angeles|San Francisco|San Diego|Boston|Seattle|"
    r"Las Vegas|Miami|Houston|Philadelphia|Detroit|Atlanta|Orlando|"
    r"Manhattan|Brooklyn|the Bronx|Salt Lake City|Boise|Washington,? D\.?C\.?|"
    r"Disneyland|Disney World|Grand Canyon|Yellowstone"
)

# (reason, compiled pattern). The first match wins and its reason is
# reported. Patterns are case-insensitive unless they set (?-i).
_RULES: list[tuple[str, re.Pattern[str]]] = [
    # ── US money ───────────────────────────────────────────────────────
    ("US money", re.compile(r"\$|¢|\bdollars?\b|(?<!\bper )\bcents?\b|\bpenn(?:y|ies)\b"
                            r"|\bnickels?\b|\bdimes?\b|\d+\s+bucks\b", re.I)),
    # "quarter" the coin, not the fraction / fiscal quarter / quarter-hour:
    # skip it when written "three quarters", "one-quarter", "first quarter",
    # or followed by of / as / the / past / hour.
    ("US money (quarter coin)", re.compile(
        r"(?<!three )(?<!3 )(?<!-)(?<!first )(?<!second )(?<!third )"
        r"(?<!fourth )(?<!last )(?<!next )"
        r"\bquarters?\b(?!\s+(?:of|as|the|past|hour|an hour|mile)\b)(?!-)",
        re.I,
    )),
    # ── US customary units ─────────────────────────────────────────────
    ("US units (inch)", re.compile(r"\binch(?:es)?\b", re.I)),
    # Feet / foot as length. "on foot" is the only non-length use exempted;
    # an animal's feet would be caught too (when in doubt, drop).
    ("US units (foot)", re.compile(r"\bfeet\b|(?<!\bon )\bfoot\b", re.I)),
    # Yard as a length, not a garden: a number before it, or "yards long",
    # "square yards", "12 yard by 9 yard".
    ("US units (yard)", re.compile(
        rf"\b(?:\d[\d,.]*|{_NUM_WORDS})[\s-]+yards?\b"
        r"|\byards?\s+(?:long|wide|tall|high|deep|away|by|per)\b"
        r"|\bsquare yards?\b|\bin yards\b|\b(?:a|half a) yard of\b",
        re.I,
    )),
    ("US units (mile)", re.compile(r"\bmiles?\b|\bmph\b|\bmpg\b", re.I)),
    ("US units (pound)", re.compile(r"\bpounds?\b|\blbs?\b\.?", re.I)),
    ("US units (ounce)", re.compile(r"\bounces?\b|\boz\b|\bfl\.? oz\b", re.I)),
    ("US units (gallon/quart/pint)", re.compile(r"\bgallons?\b|\bquarts?\b|\bpints?\b", re.I)),
    # A cup as a measure ("2 cups of flour", "measuring cups"); a cup of
    # something you drink is a count and stays.
    ("US units (cup)", re.compile(
        r"\bmeasuring cups?\b"
        r"|\bcups?\s+of\s+(?!(?:coffee|tea|water|hot chocolate|cocoa)\b)",
        re.I,
    )),
    ("US units (acre)", re.compile(r"\bacres?\b", re.I)),
    # Temperatures: any °F, or a bare "N degrees" in a temperature context
    # (GSM8K means Fahrenheit there). Celsius is fine.
    ("US units (Fahrenheit)", re.compile(r"°\s*F\b|℉|\bfahrenheit\b", re.I)),
    # ── US culture ─────────────────────────────────────────────────────
    ("US culture (sport)", re.compile(
        r"\bbaseball\b|\bfootball\b|\bsuper bowl\b|\bNFL\b|\bMLB\b|"
        r"\btouchdowns?\b|\bquarterbacks?\b|\bhome runs?\b|\bLittle League\b",
        re.I,
    )),
    ("US culture (holiday)", re.compile(
        r"\bthanksgiving\b|\bhalloween\b|\btrick[- ]or[- ]treat\w*|\beaster\b|"
        r"\bchristmas\b|\b(?:4th|fourth) of july\b|\bjuly (?:4th|4|fourth)\b|"
        r"\bindependence day\b|\bmemorial day\b|\blabor day\b|"
        r"\bpresidents'? day\b",
        re.I,
    )),
    ("US culture (store)", re.compile(
        r"\bwal-?mart\b|(?-i:\bTarget\b)|\bcostco\b|\bkmart\b|\bhome depot\b|"
        r"\bmacy'?s\b|\b(?:yard|garage) sale\b",
        re.I,
    )),
    ("US culture (place)", re.compile(
        rf"(?-i:\b(?:{_US_PLACES})\b)|\bU\.S\.A?\.?|\bUSA\b|\bunited states\b|\bamerica(?:n|ns)?\b",
        re.I,
    )),
]

_TEMP_CONTEXT = re.compile(r"\btemperature|\bweather\b|\bthermometer\b|\bdegrees? outside\b", re.I)
_BARE_DEGREES = re.compile(r"\d\s*(?:degrees?\b|°)(?!\s*C\b)(?!\s*celsius)", re.I)


def us_centric_reason(text: str) -> str | None:
    """Why ``text`` reads as US-only, or None if it travels.

    Returns a short human-readable reason such as ``"US money"`` or
    ``"US units (mile)"``.
    """
    for reason, pattern in _RULES:
        if pattern.search(text):
            return reason
    if _TEMP_CONTEXT.search(text) and _BARE_DEGREES.search(text):
        return "US units (Fahrenheit)"
    return None


def item_us_centric_reason(item: dict) -> str | None:
    """:func:`us_centric_reason` over a bundled item's prompt + explanation."""
    text = "\n".join([item.get("prompt", ""), *item.get("explanation", [])])
    return us_centric_reason(text)


# ---------------------------------------------------------------------------
# In-place filter over the bundled JSONs
# ---------------------------------------------------------------------------

def _detect_format(raw: str, doc: dict) -> dict | None:
    """The json.dumps kwargs that reproduce ``raw`` exactly, or None."""
    for indent in (2, 1, 4):
        for ensure_ascii in (False, True):
            kwargs = {"indent": indent, "ensure_ascii": ensure_ascii}
            if json.dumps(doc, **kwargs) + "\n" == raw:
                return kwargs
    return None


def filter_bundled(data_dir: Path, *, dry_run: bool, verbose: bool) -> int:
    print(f"{'file':40s} {'before':>6s} {'after':>6s} {'dropped':>7s}")
    for path in sorted(data_dir.glob("*.json")):
        raw = path.read_text(encoding="utf-8")
        doc = json.loads(raw)
        items = doc["items"]
        kept, dropped = [], []
        for item in items:
            reason = item_us_centric_reason(item)
            (dropped if reason else kept).append((item, reason))
        if dropped:
            print(f"{path.name:40s} {len(items):6d} {len(kept):6d} {len(dropped):7d}")
            if verbose:
                for item, reason in dropped:
                    print(f"    - [{reason}] {item['id']}: {item['prompt'][:100]}")
        if not dropped or dry_run:
            continue
        fmt = _detect_format(raw, doc)
        if fmt is None:
            print(f"  ! {path.name}: formatting not reproducible; left untouched",
                  file=sys.stderr)
            continue
        doc["items"] = [item for item, _ in kept]
        path.write_text(json.dumps(doc, **fmt) + "\n", encoding="utf-8")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--data-dir", type=Path, default=DATA_DIR)
    parser.add_argument("--dry-run", action="store_true",
                        help="Report what would be dropped without writing.")
    parser.add_argument("--verbose", action="store_true",
                        help="List every dropped item with its reason.")
    args = parser.parse_args()
    return filter_bundled(args.data_dir, dry_run=args.dry_run, verbose=args.verbose)


if __name__ == "__main__":
    sys.exit(main())
