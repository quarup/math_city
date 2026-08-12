#!/usr/bin/env python3
"""Join a UX sweep's machine probe data with the agent's notes into report.md.

Deterministic and idempotent: re-run it after every batch. Resuming a sweep
is just "probe the remaining concepts, append notes, rebuild".

    build_report.py REPORT_DIR [--list-unreviewed]

Exits 2 if the report is incomplete -- see validate() for what that covers.

Reads
    REPORT_DIR/probe.jsonl      one line per concept, written by uxctl.py
    REPORT_DIR/notes/*.jsonl    one line per concept, written by the
                                reviewing agents -- one file per batch so
                                parallel reviewers never interleave writes:
                                {"id": ..., "verdict": "ok"|"improve"|"bug",
                                 "notes": "..."}
Writes
    REPORT_DIR/report.md
"""

from __future__ import annotations

import json
import sys
from collections import OrderedDict
from pathlib import Path
from typing import Any

VERDICT_ICON = {"ok": "✅", "improve": "🎨", "bug": "🐞"}

# Statuses uxctl sets on its own, without the agent having to look at
# anything. These are hard failures, not judgement calls.
HARD_FAIL = {
    "failed": "harness could not complete the probe",
    "correct_answer_rejected": "canonical answer graded WRONG",
    "distractor_accepted": "distractor graded CORRECT",
}


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    return [json.loads(ln) for ln in path.read_text().splitlines() if ln.strip()]


def md_escape(s: str | None) -> str:
    if not s:
        return ""
    return s.replace("|", "\\|").replace("\n", " ")


def validate(
    root: Path,
    probes: dict[str, dict[str, Any]],
    notes: dict[str, dict[str, Any]],
    unreviewed: list[str],
) -> list[str]:
    """Every way a sweep can silently under-cover, checked in one place.

    Returns human-readable problem lines; empty means the report is
    trustworthy. A sweep fails quietly in more ways than "an agent forgot
    to write a note", so each of these is worth its own check.
    """
    problems: list[str] = []

    # 1. Did the probe pass cover the whole scope? Only scope.json knows
    #    what was asked for -- probe.jsonl alone always looks complete.
    scope_path = root / "scope.json"
    if not scope_path.exists():
        problems.append(
            "no scope.json — cannot verify the probe covered the whole "
            "scope (probed with an older uxctl?)"
        )
    else:
        scope = json.loads(scope_path.read_text())
        missing = [i for i in scope.get("ids", []) if i not in probes]
        if missing and scope.get("limit"):
            problems.append(
                f"{len(missing)} of {len(scope['ids'])} scoped concepts not "
                f"probed — expected, --limit {scope['limit']} was used"
            )
        elif missing:
            problems.append(
                f"{len(missing)} scoped concepts were NEVER PROBED "
                f"(probe pass incomplete): {', '.join(missing[:10])}"
                + (f" (+{len(missing) - 10} more)" if len(missing) > 10 else "")
            )

    # 2. Probed but never reviewed.
    if unreviewed:
        problems.append(
            f"{len(unreviewed)} probed concepts have no note: "
            f"{', '.join(unreviewed[:10])}"
            + (f" (+{len(unreviewed) - 10} more)" if len(unreviewed) > 10 else "")
        )

    # 3. Notes that don't correspond to anything probed — a typo or a
    #    hallucinated id silently counts as coverage otherwise.
    orphans = [i for i in notes if i not in probes]
    if orphans:
        problems.append(
            f"{len(orphans)} notes reference unknown ids: "
            f"{', '.join(orphans[:10])}"
        )

    # 4. Malformed verdicts, and findings with no text (useless to act on).
    bad_verdict = [
        i for i, n in notes.items() if n.get("verdict") not in VERDICT_ICON
    ]
    if bad_verdict:
        problems.append(
            f"{len(bad_verdict)} notes have an invalid verdict: "
            f"{', '.join(bad_verdict[:10])}"
        )
    empty_finding = [
        i
        for i, n in notes.items()
        if n.get("verdict") in {"bug", "improve"} and not (n.get("notes") or "").strip()
    ]
    if empty_finding:
        problems.append(
            f"{len(empty_finding)} notes flag a problem but say nothing: "
            f"{', '.join(empty_finding[:10])}"
        )

    # 5. Screenshots promised by probe.jsonl but absent from disk.
    missing_shots = [
        f"{i}:{key}"
        for i, r in probes.items()
        for key in ("mcShot", "keypadShot", "wrongShot")
        if r.get(key) and not (root / r[key]).exists()
    ]
    if missing_shots:
        problems.append(
            f"{len(missing_shots)} referenced screenshots are missing: "
            f"{', '.join(missing_shots[:10])}"
        )

    return problems


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    flags = {a for a in sys.argv[1:] if a.startswith("-")}
    if len(args) != 1 or flags - {"--list-unreviewed"}:
        print(
            "usage: build_report.py REPORT_DIR [--list-unreviewed]",
            file=sys.stderr,
        )
        return 1
    root = Path(args[0])
    list_only = "--list-unreviewed" in flags

    # Later lines win, so a re-probe supersedes an earlier attempt.
    probes: OrderedDict[str, dict[str, Any]] = OrderedDict()
    for rec in read_jsonl(root / "probe.jsonl"):
        probes[rec["id"]] = rec
    notes: dict[str, dict[str, Any]] = {}
    for path in [root / "notes.jsonl", *sorted((root / "notes").glob("*.jsonl"))]:
        for n in read_jsonl(path):
            notes[n["id"]] = n

    by_cat: OrderedDict[str, list[dict[str, Any]]] = OrderedDict()
    for rec in sorted(
        probes.values(), key=lambda r: (r.get("categoryOrder", 99), r.get("row", 0))
    ):
        by_cat.setdefault(rec["categoryId"], []).append(rec)

    total = len(probes)
    reviewed = sum(1 for i in probes if i in notes)
    # A `failed` probe has no screenshots, so there is nothing for a
    # reviewer to look at -- it's already surfaced as a hard failure and
    # shouldn't be nagged about as a coverage gap.
    unreviewed = [
        i
        for i, r in probes.items()
        if i not in notes and r.get("status") != "failed"
    ]
    if list_only:
        for i in unreviewed:
            print(i)
        return 0

    problems = validate(root, probes, notes, unreviewed)

    counts = {"ok": 0, "improve": 0, "bug": 0}
    for i in probes:
        v = notes.get(i, {}).get("verdict")
        if v in counts:
            counts[v] += 1
    for rec in probes.values():
        if rec.get("status") in HARD_FAIL and notes.get(rec["id"]) is None:
            counts["bug"] += 1

    bands = sorted({r.get("band", "?") for r in probes.values()})
    # Only give a band its own column if something was actually captured in
    # it -- a keypad-only or MC-only run shouldn't carry an empty column.
    has_mc = any(r.get("mcShot") for r in probes.values())
    has_keypad = any(
        r.get("keypadShot") or r.get("keypadForcedMc") for r in probes.values()
    )

    out: list[str] = []
    out.append(f"# UX sweep — {root.name}")
    out.append("")
    out.append(f"- Input mode: **{', '.join(bands)}**")
    out.append(f"- Concepts probed: **{total}** ({reviewed} reviewed)")
    out.append(
        f"- {VERDICT_ICON['ok']} {counts['ok']} clean · "
        f"{VERDICT_ICON['improve']} {counts['improve']} could improve · "
        f"{VERDICT_ICON['bug']} {counts['bug']} bug"
    )
    if problems:
        out.append("")
        out.append("> [!WARNING]")
        out.append("> **This report is incomplete.**")
        for p in problems:
            out.append(f"> - {p}")
        out.append(
            "> "
            "\n> Re-probe with `--resume` and/or re-run the review step "
            f"(`build_report.py {root.name} --list-unreviewed`), then "
            "rebuild."
        )
    out.append("")
    out.append(
        "Each question screenshot is the exact screen the player sees. The "
        "wrong-answer screenshot is that same question, replayed from its "
        "seed and answered with a distractor."
    )
    out.append("")
    if has_mc and has_keypad:
        out.append(
            "**One wrong-answer screenshot covers both input modes.** The "
            "band never reaches the result screen — it renders from the "
            "question, the submitted answer and the outcome, and in debug "
            "mode bricks are always 0 and the unlock event null. Same seed "
            "→ same question → same distractor → same red screen. "
            "_keypad → MC_ in the keypad column means the question forced "
            "multiple choice (`multipleChoiceOnly`, or a text-shaped "
            "answer format), so that screen is the MC one."
        )
        out.append("")
    out.append(
        'The green "Correct!" screen is verified programmatically and not '
        "captured — it is identical for every concept."
    )
    out.append("")

    # -- findings first: the reason anyone opens this file ---------------
    flagged = [
        r
        for r in probes.values()
        if notes.get(r["id"], {}).get("verdict") in {"bug", "improve"}
        or r.get("status") in HARD_FAIL
    ]
    if flagged:
        out.append("## Findings")
        out.append("")
        out.append("| | Concept | Finding |")
        out.append("|---|---|---|")
        for r in flagged:
            n = notes.get(r["id"], {})
            icon = VERDICT_ICON.get(n.get("verdict", "bug"), "🐞")
            text = n.get("notes", "")
            if r.get("status") in HARD_FAIL:
                text = f"**{HARD_FAIL[r['status']]}.** {text}".strip()
            out.append(
                f"| {icon} | [{md_escape(r['name'])}](#{r['id']}) "
                f"`{r['id']}` | {md_escape(text)} |"
            )
        out.append("")

    # -- per-category detail ---------------------------------------------
    for cat_id, recs in by_cat.items():
        head = recs[0]
        out.append(f"## {head['section']} {head['categoryName']} (`{cat_id}`)")
        out.append("")
        shot_cols = (["Question (MC)"] if has_mc else []) + (
            ["Question (keypad)"] if has_keypad else []
        )
        out.append(f"| | Concept | {' | '.join(shot_cols)} | Wrong answer | Notes |")
        out.append("|---|---|" + "---|" * (len(shot_cols) + 2))
        for r in recs:
            n = notes.get(r["id"], {})
            verdict = n.get("verdict")
            if r.get("status") in HARD_FAIL:
                icon = "🐞"
            elif verdict:
                icon = VERDICT_ICON.get(verdict, "")
            else:
                icon = "⏳"

            cells: list[str] = []
            if has_mc:
                cells.append(
                    f'<img src="{r["mcShot"]}" width="180">'
                    if r.get("mcShot")
                    else "—"
                )
            if has_keypad:
                if r.get("keypadShot"):
                    cells.append(f'<img src="{r["keypadShot"]}" width="180">')
                elif r.get("keypadForcedMc"):
                    cells.append("_keypad → MC_")
                else:
                    cells.append("—")
            # Anchor rides the first cell so the findings table can link here.
            cells[0] = f'<a id="{r["id"]}"></a>' + cells[0]
            cells.append(
                f'<img src="{r["wrongShot"]}" width="180">'
                if r.get("wrongShot")
                else "—"
            )

            note_bits: list[str] = []
            if r.get("status") in HARD_FAIL:
                note_bits.append(f"**{HARD_FAIL[r['status']]}**")
            if r.get("error"):
                note_bits.append(f"`{md_escape(r['error'])}`")
            if r.get("renderErrors"):
                first = md_escape(r["renderErrors"][0])[:200]
                note_bits.append(
                    f"**{len(r['renderErrors'])} render error(s):** `{first}`"
                )
            if r.get("replayStable") is False:
                note_bits.append("**seed replay was not stable**")
            if n.get("notes"):
                note_bits.append(md_escape(n["notes"]))
            if not note_bits:
                note_bits.append("" if verdict else "_not yet reviewed_")

            out.append(
                f"| {icon} | **{md_escape(r['name'])}**<br>`{r['id']}`<br>"
                f"G{r.get('grade', '?')}"
                f"{' · ' + r['diagram'] if r.get('diagram') else ''}"
                f"{' · dataset' if r.get('datasetPool') else ''} "
                f"| {' | '.join(cells)} | {' · '.join(note_bits)} |"
            )
        out.append("")

    (root / "report.md").write_text("\n".join(out) + "\n")
    print(f"wrote {root / 'report.md'} — {total} concepts, {reviewed} reviewed")

    problems = validate(root, probes, notes, unreviewed)
    if not problems:
        print("validation: OK — every scoped concept probed and reviewed")
        return 0

    print(f"validation: {len(problems)} PROBLEM(S)")
    for p in problems:
        print(f"  - {p}")
    print(
        "  This report is incomplete. Re-probe with --resume and/or re-run "
        "the review step, then rebuild."
    )
    # Non-zero so a caller can gate on full coverage without parsing text.
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
