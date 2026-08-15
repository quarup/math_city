#!/usr/bin/env python3
"""Shrink a ux-sweep report's screenshots so the report can be committed.

A full both-band sweep of the whole catalogue is ~1000 PNGs at ~86 MB, which
is too much to put in git history. This resizes and colour-quantizes them in
place, keeping the filenames (so report.md and probe.jsonl need no edits).

    python3 tools/ux_sweep/shrink_shots.py ux_reports/2026-08-13-all-both

Measured on the 2026-08-13 full sweep (1003 shots, 540x1200 originals):

    original                      85.6 MB
    quantize only (q80)           15.0 MB
    WebP q80, full resolution     15.5 MB   <- worse than PNG, and renames files
    16-colour palette, full res   15.0 MB
    --max-dim 800 --quality 65     9.7 MB   <- the default here

Legibility was checked at 360x800 before adopting it: prompt text stays sharp,
truncated-prompt bugs are still obvious, and the colliding axis-label defects
still read as defects. Going much below this starts destroying the evidence
the report exists to show.

Run this AFTER build_report.py validates clean, then re-run build_report.py to
confirm every screenshot still resolves.
"""

import argparse
import os
import pathlib
import shutil
import subprocess
import sys

PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def die(msg):
    sys.exit(f"error: {msg}")


def check_tools():
    missing = [t for t in ("sips", "pngquant") if shutil.which(t) is None]
    if missing:
        die(
            f"missing required tool(s): {', '.join(missing)}\n"
            "  sips ships with macOS; install pngquant with `brew install pngquant`"
        )


def total_bytes(paths):
    return sum(p.stat().st_size for p in paths)


def fmt(n):
    """Report both units — a '10 MB' budget is ambiguous, so print both."""
    return f"{n:,} bytes ({n / 1048576:.2f} MiB / {n / 1000000:.2f} MB)"


def shrink_one(src, dst, max_dim, quality):
    """Resize then quantize. Returns True if dst is a usable PNG."""
    r = subprocess.run(
        ["sips", "-Z", str(max_dim), str(src), "--out", str(dst)],
        capture_output=True,
    )
    if r.returncode != 0 or not dst.exists():
        return False
    # pngquant exits non-zero when it cannot hit the quality target; the
    # resized-but-unquantized file it leaves behind is still valid, so we
    # only care that the result is a readable PNG.
    subprocess.run(
        ["pngquant", "--force", "--quality", f"0-{quality}", "--speed", "1",
         "--output", str(dst), str(dst)],
        capture_output=True,
    )
    try:
        with open(dst, "rb") as fh:
            return fh.read(8) == PNG_MAGIC and dst.stat().st_size > 0
    except OSError:
        return False


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("report_dir", help="a ux_reports/<date>-<scope>-<band> directory")
    ap.add_argument("--max-dim", type=int, default=800,
                    help="screenshot long edge in px (default: 800)")
    ap.add_argument("--quality", type=int, default=65,
                    help="pngquant max quality, 0-100 (default: 65)")
    ap.add_argument("--dry-run", action="store_true",
                    help="project the final size from a 1-in-10 sample, change nothing")
    ap.add_argument("--keep-originals", metavar="DIR",
                    help="move the originals here instead of deleting them")
    args = ap.parse_args()

    check_tools()

    root = pathlib.Path(args.report_dir)
    shots = root / "shots"
    if not shots.is_dir():
        die(f"no shots/ directory under {root}")

    originals = sorted(shots.glob("*.png"))
    if not originals:
        die(f"no PNGs in {shots}")
    before = total_bytes(originals)
    print(f"{len(originals)} screenshots, {fmt(before)}")

    work = root / "shots_shrunk"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir()

    try:
        sample = originals[::10] if args.dry_run else originals
        if args.dry_run:
            print(f"dry run: sampling {len(sample)} of {len(originals)}")

        failures = []
        for i, src in enumerate(sample, 1):
            if not shrink_one(src, work / src.name, args.max_dim, args.quality):
                failures.append(src.name)
            if i % 200 == 0:
                print(f"  ...{i}/{len(sample)}")

        if failures:
            die(f"{len(failures)} file(s) failed to convert, e.g. {failures[:3]}; "
                "originals left untouched")

        after_sample = total_bytes(sorted(work.glob("*.png")))

        if args.dry_run:
            projected = before * after_sample / total_bytes(sample)
            print(f"projected full size: {fmt(int(projected))}")
            print("(dry run — nothing changed)")
            return

        # Verify parity before destroying anything.
        got = {p.name for p in work.glob("*.png")}
        want = {p.name for p in originals}
        if got != want:
            die(f"filename mismatch after conversion "
                f"(missing {sorted(want - got)[:3]}); originals left untouched")

        if args.keep_originals:
            dest = pathlib.Path(args.keep_originals)
            if dest.exists():
                shutil.rmtree(dest)
            shots.rename(dest)
            print(f"originals moved to {dest}")
        else:
            shutil.rmtree(shots)
        work.rename(shots)
    finally:
        if work.exists():
            shutil.rmtree(work, ignore_errors=True)

    after = total_bytes(sorted(shots.glob("*.png")))
    print(f"shrunk to {fmt(after)}  ({after / before:.1%} of original)")
    print("now re-run build_report.py to confirm every screenshot still resolves")


if __name__ == "__main__":
    main()
