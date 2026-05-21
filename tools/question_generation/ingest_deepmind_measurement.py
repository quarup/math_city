#!/usr/bin/env python3
"""Ingest DeepMind `measurement.time` items into Math City JSON.

Maps to ``elapsed_time`` (G3). DeepMind emits three templates:

- "How many minutes are there between A and B?" → integer answer
- "What is N minutes after T?" → time string "H:MM AM/PM"
- "What is N minutes before T?" → time string "H:MM AM/PM"

The existing algorithmic ``elapsed_time`` generator emits time-string
answers (e.g. "2:55 PM"), so we ingest **only** the after/before
variants. The "how many minutes between" variant has a different
answer shape and would not round-trip through the existing
answer-checker — drop it.

DeepMind goes to 12-hour granularity (24-hour displacement clamped via
modulo); we drop items whose computed AM/PM crossing doesn't match the
stated answer, to filter out the corner cases that don't match
elapsed_time's 12-hour-clock framing.
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
    item_id,
    write_buckets,
)

MODULE = "measurement.time"


TIME_AFTER_RE = re.compile(
    r"^What is (\d+) minutes? after (\d{1,2}):(\d{2}) (AM|PM)\?$"
)
TIME_BEFORE_RE = re.compile(
    r"^What is (\d+) minutes? before (\d{1,2}):(\d{2}) (AM|PM)\?$"
)
TIME_ANSWER_RE = re.compile(r"^(\d{1,2}):(\d{2}) (AM|PM)$")


def _to_minutes_of_day(hour: int, minute: int, ampm: str) -> int:
    """12-hour-clock → 0..1439 minutes-since-midnight."""
    if ampm == "AM":
        h = 0 if hour == 12 else hour
    else:
        h = 12 if hour == 12 else hour + 12
    return h * 60 + minute


def _from_minutes_of_day(m: int) -> tuple[int, int, str]:
    """0..1439 (or wrapped via mod) → (12-hour-hour, minute, AM/PM)."""
    m = m % (24 * 60)
    h24 = m // 60
    minute = m % 60
    if h24 == 0:
        return 12, minute, "AM"
    if h24 < 12:
        return h24, minute, "AM"
    if h24 == 12:
        return 12, minute, "PM"
    return h24 - 12, minute, "PM"


def ingest_time(
    n_target: int,
    rand: random.Random,
) -> tuple[dict[str, list[dict]], dict[str, int]]:
    from mathematics_dataset.modules import measurement

    def entropy_fn(r):
        return r

    gen = measurement.train(entropy_fn)["time"]

    buckets: dict[str, list[dict]] = defaultdict(list)
    stats = defaultdict(int)
    seen_prompts: set[str] = set()
    attempts = 0
    # Generous budget — only the after/before variants are usable (~2/3 of
    # items are "how many minutes between" which we drop).
    max_attempts = n_target * 30

    while len(buckets.get("elapsed_time", [])) < n_target and attempts < max_attempts:
        attempts += 1
        ex = gen()
        prompt = str(ex.question)
        answer_str = str(ex.answer)

        m_after = TIME_AFTER_RE.match(prompt)
        m_before = TIME_BEFORE_RE.match(prompt)
        if not (m_after or m_before):
            # The "how many minutes between" variant or any other shape.
            stats["rejected_not_after_before"] += 1
            continue

        m_ans = TIME_ANSWER_RE.match(answer_str)
        if not m_ans:
            stats["rejected_answer_format"] += 1
            continue

        if m_after:
            delta_str, h_str, mn_str, ampm = m_after.groups()
            direction = 1
        else:
            delta_str, h_str, mn_str, ampm = m_before.groups()
            direction = -1
        delta = int(delta_str)
        start_h = int(h_str)
        start_mn = int(mn_str)
        start_minutes = _to_minutes_of_day(start_h, start_mn, ampm)
        end_minutes = start_minutes + direction * delta
        end_h, end_mn, end_ampm = _from_minutes_of_day(end_minutes)
        expected_answer = f"{end_h}:{end_mn:02d} {end_ampm}"
        if expected_answer != answer_str:
            stats["rejected_verify"] += 1
            continue

        # Tag — only one bucket.
        concept_id = "elapsed_time"
        if len(buckets[concept_id]) >= n_target:
            stats["bucket_full_skips"] += 1
            continue
        if prompt in seen_prompts:
            stats["rejected_duplicate"] += 1
            continue
        seen_prompts.add(prompt)

        # Distractors for time-string answers: ±5 / ±15 / ±60 minutes
        # around the correct answer (matches the algorithmic generator's
        # distractor strategy in array_grid_extra_generators.dart).
        offsets = [-5, 5, -15, 15, -60, 60, -30, 30]
        rand.shuffle(offsets)
        distractors_seen: set[str] = set()
        distractors: list[str] = []
        for off in offsets:
            h, mn, ap = _from_minutes_of_day(end_minutes + off)
            cand = f"{h}:{mn:02d} {ap}"
            if cand == expected_answer or cand in distractors_seen:
                continue
            distractors_seen.add(cand)
            distractors.append(cand)
            if len(distractors) == 3:
                break
        if len(distractors) < 3:
            stats["rejected_distractor_short"] += 1
            continue

        sign_word = "after" if direction > 0 else "before"
        explanation = [
            f"{delta} minutes {sign_word} {start_h}:{start_mn:02d} {ampm} "
            f"is {expected_answer}."
        ]

        item = build_item(
            id=item_id(prompt, prefix="time"),
            concept_id=concept_id,
            prompt=prompt,
            correct_answer=expected_answer,
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

    print("=== measurement.time ===", file=sys.stderr)
    buckets, stats = ingest_time(args.items_per_concept, rand)
    for cid, items in sorted(buckets.items()):
        print(f"  {cid:36s} {len(items):4d}", file=sys.stderr)
    for k, v in stats.items():
        print(f"  [stat] {k:28s} {v}", file=sys.stderr)
    write_buckets(buckets, source_module=MODULE, dry_run=args.dry_run)
    return 0


if __name__ == "__main__":
    sys.exit(main())
