#!/usr/bin/env python3
"""Driver for the Math City UX sweep.

Talks to the kDebugMode-only control port in `lib/services/debug_harness.dart`
over `adb forward`, and to the emulator itself for screenshots.

The point of this script is that a whole concept probe -- open the question,
screenshot it, answer it right, check the green screen, replay the *same*
question via its seed, answer it wrong, screenshot the red screen -- is a
single subprocess call that prints one JSON line. The reviewing agent then
only has to look at two images and write down what it thinks.

Usage
-----
    uxctl.py ping
    uxctl.py concepts [SCOPE]
    uxctl.py probe --out DIR [--band both|mc|keypad] [--resume] SCOPE
    uxctl.py back

SCOPE is a comma-separated list of any of:
    all                     every implemented concept
    3.3                     a curriculum.md section number
    add_sub                 a category id
    "Addition"              a case-insensitive category-name substring
    add_within_10           a single concept id
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zlib
from pathlib import Path
from typing import Any

PORT = int(os.environ.get("UX_SWEEP_PORT", "8081"))
BASE = f"http://127.0.0.1:{PORT}"
SERIAL = os.environ.get("ANDROID_SERIAL", "emulator-5554")
ADB = os.environ.get(
    "ADB", str(Path.home() / "Library/Android/sdk/platform-tools/adb")
)


# ---------------------------------------------------------------------------
# adb / http plumbing
# ---------------------------------------------------------------------------


def adb(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [ADB, "-s", SERIAL, *args],
        capture_output=True,
        text=True,
        check=check,
    )


def ensure_forward() -> None:
    """Idempotent: re-running just overwrites the same rule."""
    subprocess.run(
        [ADB, "-s", SERIAL, "forward", f"tcp:{PORT}", f"tcp:{PORT}"],
        capture_output=True,
        text=True,
        check=False,
    )


def call(path: str, payload: dict[str, Any] | None = None) -> dict[str, Any]:
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(
        BASE + path,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST" if data is not None else "GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.URLError as e:
        return {"ok": False, "error": f"control port unreachable: {e}"}
    except TimeoutError:
        return {"ok": False, "error": "control port timed out"}


def wait_ready(timeout_s: int = 120) -> bool:
    """Block until the app is past the splash screen."""
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        r = call("/ping")
        if r.get("ok") and r.get("homeReady"):
            return True
        time.sleep(1)
    return False


# ---------------------------------------------------------------------------
# screenshots
# ---------------------------------------------------------------------------


def screenshot(dest: Path, max_dim: int) -> None:
    """`exec-out screencap` yields 0 bytes on this setup; go via a file."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    remote = "/sdcard/__uxsweep.png"
    adb("shell", "screencap", "-p", remote)
    adb("pull", remote, str(dest))
    adb("shell", "rm", "-f", remote, check=False)
    if max_dim and shutil.which("sips"):
        subprocess.run(
            ["sips", "-Z", str(max_dim), str(dest)],
            capture_output=True,
            check=False,
        )


# ---------------------------------------------------------------------------
# scope resolution
# ---------------------------------------------------------------------------


def flat_catalog() -> list[dict[str, Any]]:
    r = call("/concepts")
    if not r.get("ok"):
        die(f"could not list concepts: {r.get('error')}")
    out: list[dict[str, Any]] = []
    for cat in r["categories"]:
        for c in cat["concepts"]:
            out.append(
                {
                    "id": c["id"],
                    "name": c["name"],
                    "grade": c["grade"],
                    "row": c["row"],
                    # >0 means some questions for this concept are drawn
                    # from the bundled dataset rather than the generator,
                    # so a single probe isn't necessarily representative.
                    "datasetPool": c.get("datasetPool", 0),
                    "categoryId": cat["id"],
                    "categoryName": cat["name"],
                    "section": cat["section"],
                    "categoryOrder": cat["order"],
                }
            )
    return out


def resolve_scope(scope: str, catalog: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if scope.strip().lower() == "all":
        return catalog

    picked: list[dict[str, Any]] = []
    seen: set[str] = set()
    for raw in scope.split(","):
        term = raw.strip()
        if not term:
            continue
        matches = [c for c in catalog if _matches(term, c)]
        if not matches:
            die(f'scope term "{term}" matched no implemented concept')
        for m in matches:
            if m["id"] not in seen:
                seen.add(m["id"])
                picked.append(m)
    return picked


def _matches(term: str, c: dict[str, Any]) -> bool:
    low = term.lower()
    if c["id"] == term:
        return True
    if c["categoryId"] == term:
        return True
    if c["section"] == term:
        return True
    # Bare "3" would match nothing useful; require the "3.N" form above,
    # or a name substring of at least 3 chars so "3" doesn't match all.
    if len(low) >= 3 and low in c["categoryName"].lower():
        return True
    return False


# ---------------------------------------------------------------------------
# probing
# ---------------------------------------------------------------------------


def seed_for(concept_id: str, salt: int) -> int:
    return zlib.crc32(f"{salt}:{concept_id}".encode()) % 1_000_000


def probe_one(
    meta: dict[str, Any], band: str, out_dir: Path, salt: int, max_dim: int
) -> dict[str, Any]:
    """Probe one concept.

    The question screen is captured once per requested band -- MC and the
    keypad lay the answer area out completely differently, and the keypad's
    extra-chars row is derived from the answer, so both are worth seeing.

    The wrong-answer screen is captured **once**, whatever the bands. The
    band never reaches `ResultScreen`: it renders from the question, the
    submitted answer, and the outcome, and in debug mode bricks are always
    0 and the unlock event always null. Same seed -> same question -> same
    distractor -> byte-identical red screen (verified on device; only the
    status-bar clock differs).
    """
    cid = meta["id"]
    seed = seed_for(cid, salt)
    rec: dict[str, Any] = dict(meta)
    rec.update({"band": band, "seed": seed, "status": "ok", "renderErrors": []})

    primary = "keypad" if band == "keypad" else "mc"
    extra = ["keypad"] if band == "both" else []

    def open_at(b: str) -> dict[str, Any] | None:
        r = call("/open", {"conceptId": cid, "band": b, "seed": seed})
        rec["renderErrors"] += r.get("errors") or []
        if not r.get("ok"):
            rec.update({"status": "failed", "error": r.get("error")})
            return None
        return r

    # --- pass 1: primary band -- screenshot, then answer it right -------
    opened = open_at(primary)
    if opened is None:
        return rec

    shot = Path("shots") / f"{cid}__{primary}.png"
    screenshot(out_dir / shot, max_dim)
    rec[f"{primary}Shot"] = str(shot)
    rec[f"{primary}InputMode"] = opened.get("inputMode")

    rec.update(
        {
            "prompt": opened.get("prompt"),
            "correctAnswer": opened.get("correctAnswer"),
            "displayedChoices": opened.get("displayedChoices"),
            "answerFormat": opened.get("answerFormat"),
            "answerShape": opened.get("answerShape"),
            "multipleChoiceOnly": opened.get("multipleChoiceOnly"),
            "diagram": opened.get("diagram"),
            "explanation": opened.get("explanation"),
            "explanationDiagram": opened.get("explanationDiagram"),
        }
    )

    right = call("/answer", {"correct": True})
    rec["rightOutcome"] = right.get("outcome")
    rec["rightGraded"] = right.get("gradedCorrect")
    rec["renderErrors"] += right.get("errors") or []
    if not right.get("ok"):
        rec.update({"status": "failed", "error": right.get("error")})
        return rec
    if not right.get("gradedCorrect"):
        # The harness submitted question.correctAnswer verbatim and the
        # checker still rejected it -- a real generator/checker bug.
        rec["status"] = "correct_answer_rejected"

    # --- pass 2: same seed, same question, answer it wrong --------------
    reopened = open_at(primary)
    if reopened is None:
        return rec
    rec["replayStable"] = reopened.get("prompt") == rec["prompt"]

    wrong = call("/answer", {"correct": False})
    rec["wrongSubmitted"] = wrong.get("submitted")
    rec["wrongOutcome"] = wrong.get("outcome")
    rec["renderErrors"] += wrong.get("errors") or []
    if not wrong.get("ok"):
        rec.update({"status": "failed", "error": wrong.get("error")})
        return rec
    if wrong.get("gradedCorrect"):
        # A distractor was accepted as correct -- also a real bug.
        rec["status"] = "distractor_accepted"

    w_shot = Path("shots") / f"{cid}__wrong.png"
    screenshot(out_dir / w_shot, max_dim)
    rec["wrongShot"] = str(w_shot)

    # --- pass 3: the other band's question screen, picture only ---------
    for b in extra:
        other = open_at(b)
        if other is None:
            return rec
        mode = other.get("inputMode")
        rec[f"{b}InputMode"] = mode
        if mode != b:
            # `multipleChoiceOnly`, or a text-shaped answer format, forces
            # MC even at the comfortable band -- the screen is then the one
            # we already captured, so don't store a duplicate.
            rec["keypadForcedMc"] = True
            continue
        shot = Path("shots") / f"{cid}__{b}.png"
        screenshot(out_dir / shot, max_dim)
        rec[f"{b}Shot"] = str(shot)

    return rec


def cmd_probe(args: argparse.Namespace) -> int:
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    probe_path = out_dir / "probe.jsonl"

    if not wait_ready():
        die("app never reported homeReady -- is `flutter run` up?")

    catalog = flat_catalog()
    targets = resolve_scope(args.scope, catalog)

    # Manifest of what the scope *should* cover, written before any probing.
    # Without it a probe pass that dies halfway leaves a probe.jsonl that
    # looks complete -- build_report.py has nothing to compare against.
    # Always records the full resolved scope, even under --limit, so a
    # truncated smoke run can never masquerade as full coverage.
    (out_dir / "scope.json").write_text(
        json.dumps(
            {
                "scope": args.scope,
                "band": args.band,
                "limit": args.limit,
                "ids": [t["id"] for t in targets],
            },
            indent=2,
        )
    )

    done: set[str] = set()
    if args.resume and probe_path.exists():
        for line in probe_path.read_text().splitlines():
            if line.strip():
                rec = json.loads(line)
                if rec.get("status") != "failed":
                    done.add(rec["id"])
        targets = [t for t in targets if t["id"] not in done]

    if args.limit:
        targets = targets[: args.limit]

    with probe_path.open("a") as fh:
        for meta in targets:
            rec = probe_one(meta, args.band, out_dir, args.salt, args.max_dim)
            fh.write(json.dumps(rec) + "\n")
            fh.flush()
            print(json.dumps(rec), flush=True)

    call("/back")
    return 0


# ---------------------------------------------------------------------------
# entry
# ---------------------------------------------------------------------------


def die(msg: str) -> None:
    print(f"uxctl: {msg}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    p = argparse.ArgumentParser(prog="uxctl")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("ping")
    sub.add_parser("back")

    pc = sub.add_parser("concepts")
    pc.add_argument("scope", nargs="?", default="all")

    pp = sub.add_parser("probe")
    pp.add_argument("scope")
    pp.add_argument("--out", required=True)
    pp.add_argument(
        "--band",
        choices=["both", "mc", "keypad"],
        default="both",
        help="which input mode(s) to capture the question screen in",
    )
    pp.add_argument("--resume", action="store_true")
    pp.add_argument("--limit", type=int, default=0)
    pp.add_argument("--salt", type=int, default=0)
    pp.add_argument(
        "--max-dim",
        type=int,
        default=1200,
        help="downscale screenshots to this long edge (0 = keep 1080x2400)",
    )

    args = p.parse_args()
    ensure_forward()

    if args.cmd == "ping":
        print(json.dumps(call("/ping")))
        return 0
    if args.cmd == "back":
        print(json.dumps(call("/back")))
        return 0
    if args.cmd == "concepts":
        catalog = flat_catalog()
        print(json.dumps(resolve_scope(args.scope, catalog), indent=2))
        return 0
    return cmd_probe(args)


if __name__ == "__main__":
    raise SystemExit(main())
