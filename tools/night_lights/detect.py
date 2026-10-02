#!/usr/bin/env python3
"""Find candidate window regions on every building sprite.

A window on these sprites is not a colour, it is a shape: a small patch of
glass — warm and already lit, dark, or the teal of a curtain wall — whose
outline is a parallelogram with vertical sides and top and bottom edges on
one of the projection's two facade slopes (±½). Roofs, stone and paving
share the colours but not the shape, which is what the old "warm and bright
pixel" rule got wrong.

Each candidate gets a simple polygon (four corners for a plain window,
never more than six), a class and a default on / off. The review
page shows all of them; a person has the last word (overrides.json).

    tools/sprite_pipeline/.venv/bin/python tools/night_lights/detect.py
    tools/sprite_pipeline/.venv/bin/python tools/night_lights/detect.py --debug out/ apartment_v1
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import nl_common as nl  # noqa: E402

# Sizes are in sprite pixels (192 px per tile).
MIN_AREA = 14
MAX_AREA = 1400
# A pane bigger than this is a wall of glass: cut it into cells.
CELL_SPLIT_AREA = 700
SLOPES = (0.5, -0.5)


def classify(rgba: np.ndarray) -> dict[str, np.ndarray]:
    """Per-pixel glass classes as boolean masks."""
    rgb = rgba[..., :3]
    opaque = rgba[..., 3] > 200
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    h = hsv[..., 0].astype(np.int32)  # 0..179
    s = hsv[..., 1].astype(np.int32)
    v = hsv[..., 2].astype(np.int32)
    r = rgb[..., 0].astype(np.int32)
    b = rgb[..., 2].astype(np.int32)
    warm = (h >= 9) & (h <= 34) & (v >= 200) & (s >= 55) & (s <= 215) & (r - b >= 45)
    teal = (h >= 78) & (h <= 112) & (s >= 55) & (v >= 85) & (v <= 235)
    # Dark glass is not a colour either — a shaded wall is just as grey. It
    # is a patch darker than what surrounds it: the pane inside its frame.
    weight = opaque.astype(np.float32)
    value = v.astype(np.float32)
    around = cv2.GaussianBlur(value * weight, (0, 0), 7) / np.maximum(
        cv2.GaussianBlur(weight, (0, 0), 7), 1e-3
    )
    dark = (around - value > 9) & (s < 95) & (v < 150)
    dark = cv2.morphologyEx(
        (dark & opaque & ~teal).astype(np.uint8), cv2.MORPH_OPEN, np.ones((2, 2), np.uint8)
    ) > 0
    return {
        "warm": warm & opaque,
        "teal": teal & opaque,
        "dark": dark,
    }


def split_panes(component: np.ndarray, rgba: np.ndarray) -> list[np.ndarray]:
    """Cut a wall of glass into its panes along the mullions (the thin
    lines darker or lighter than the glass around them)."""
    value = cv2.cvtColor(rgba[..., :3], cv2.COLOR_RGB2HSV)[..., 2].astype(np.float32)
    smooth = cv2.GaussianBlur(value, (0, 0), 2.5)
    bars = np.abs(value - smooth) > 5
    panes = component & ~bars
    panes = cv2.morphologyEx(
        panes.astype(np.uint8), cv2.MORPH_OPEN, np.ones((2, 2), np.uint8)
    )
    count, labels, stats, _ = cv2.connectedComponentsWithStats(panes, 4)
    out = []
    for i in range(1, count):
        area = int(stats[i, cv2.CC_STAT_AREA])
        if area < 18 or area > CELL_SPLIT_AREA:
            continue
        pane = cv2.dilate((labels == i).astype(np.uint8), np.ones((3, 3), np.uint8))
        out.append((pane > 0) & component)
    return out


def sheared_box(ys: np.ndarray, xs: np.ndarray, slope: float):
    """Bounding box of the pixels in (x, y - slope·x) space."""
    yy = ys - slope * xs
    return xs.min(), xs.max() + 1, yy.min(), yy.max() + 1


def fit(ys: np.ndarray, xs: np.ndarray) -> tuple[float, float, tuple]:
    """Best parallelogram fit: (fill ratio, slope, box)."""
    best = (0.0, SLOPES[0], (0, 0, 0, 0))
    area = float(len(xs))
    for slope in SLOPES:
        x0, x1, y0, y1 = sheared_box(ys, xs, slope)
        fill = area / max((x1 - x0) * (y1 - y0), 1.0)
        if fill > best[0]:
            best = (fill, slope, (x0, x1, y0, y1))
    return best


def lies_flat(ys, xs, slope) -> bool:
    """Whether the region is a patch of ground rather than of wall: a
    window's sides are vertical, a paving stone's follow the other facade
    slope, so in sheared space its left edge runs off at 45°."""
    yy = np.round(ys - slope * xs).astype(np.int32)
    rows = np.unique(yy)
    if len(rows) < 5:
        return True
    left = np.array([xs[yy == r].min() for r in rows], dtype=np.float32)
    right = np.array([xs[yy == r].max() for r in rows], dtype=np.float32)
    lean_left = np.polyfit(rows, left, 1)[0]
    lean_right = np.polyfit(rows, right, 1)[0]
    return abs(lean_left) > 0.5 and abs(lean_right) > 0.5 and lean_left * lean_right > 0


def trimmed_parallelogram(ys, xs, slope) -> list[float]:
    """The region as a clean parallelogram: its sheared box with the
    ragged two percent trimmed off each side."""
    yy = ys - slope * xs
    x0, x1 = np.percentile(xs, 2), np.percentile(xs, 98) + 1
    y0, y1 = np.percentile(yy, 2), np.percentile(yy, 98) + 1
    return parallelogram((x0, x1, y0, y1), slope)


def parallelogram(box, slope) -> list[float]:
    x0, x1, y0, y1 = box
    return [
        round(float(v), 1)
        for v in (
            x0, y0 + slope * x0,
            x1, y0 + slope * x1,
            x1, y1 + slope * x1,
            x0, y1 + slope * x0,
        )
    ]


def detect(name: str) -> dict:
    rgba = nl.load_rgba(name)
    h, w = rgba.shape[:2]
    classes = classify(rgba)
    found = []
    for kind, mask in classes.items():
        # Close one pixel so the panes of a window join across their bars.
        closed = cv2.morphologyEx(
            mask.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8)
        )
        count, labels, stats, _ = cv2.connectedComponentsWithStats(closed, 8)
        for i in range(1, count):
            area = int(stats[i, cv2.CC_STAT_AREA])
            if area < MIN_AREA:
                continue
            ys, xs = np.nonzero(labels == i)
            fill, slope, box = fit(ys.astype(np.float32), xs.astype(np.float32))
            bw, bh = box[1] - box[0], box[3] - box[2]
            if kind == "teal" and area > 120 and lies_flat(
                ys.astype(np.float32), xs.astype(np.float32), slope
            ):
                # Water, a solar panel, a glass roof: teal, but lying down.
                continue
            if area > CELL_SPLIT_AREA and kind == "dark" and fill >= 0.75 and area <= 2600:
                # A shop front: one big dark pane in a clean frame.
                found.append(
                    dict(kind=kind, area=area, fill=fill, slope=slope, w=bw, h=bh,
                         p=trimmed_parallelogram(
                             ys.astype(np.float32), xs.astype(np.float32), slope),
                         cell=False)
                )
                continue
            if area > CELL_SPLIT_AREA:
                if kind != "teal":
                    continue
                for pane in split_panes(labels == i, rgba):
                    pys, pxs = np.nonzero(pane)
                    pfill, pslope, pbox = fit(
                        pys.astype(np.float32), pxs.astype(np.float32)
                    )
                    if pfill < 0.45:
                        continue
                    poly = nl.tidy_polygon(pane)
                    if poly is None:
                        continue
                    found.append(
                        dict(kind=kind, area=int(pane.sum()), fill=pfill,
                             slope=pslope, w=pbox[1] - pbox[0],
                             h=pbox[3] - pbox[2], p=poly, cell=True)
                    )
                continue
            if area > MAX_AREA or bw < 3 or bh < 4:
                continue
            aspect = bw / bh
            if fill < 0.5 or aspect < 0.18 or aspect > 3.2:
                continue
            if kind == "dark" and (area < 24 or area > 600 or min(bw, bh) < 4):
                continue
            if kind == "warm":
                # A lit window has a bright, washed-out core; a wooden bench
                # or a terracotta tile is the same orange all the way through.
                hsv = cv2.cvtColor(rgba[..., :3], cv2.COLOR_RGB2HSV)
                core = (hsv[ys, xs, 2] >= 232) & (hsv[ys, xs, 1] <= 150)
                if core.mean() < 0.12:
                    continue
                if lies_flat(ys.astype(np.float32), xs.astype(np.float32), slope):
                    continue
            poly = nl.tidy_polygon(labels == i)
            if poly is None:
                continue
            found.append(
                dict(kind=kind, area=area, fill=fill, slope=slope, w=bw, h=bh,
                     p=poly, cell=False)
            )

    # Windows repeat: count neighbours of the same size on the same facade.
    for a in found:
        a["twins"] = sum(
            1
            for b in found
            if b is not a
            and b["slope"] == a["slope"]
            and abs(b["w"] - a["w"]) <= 0.35 * a["w"] + 1
            and abs(b["h"] - a["h"]) <= 0.35 * a["h"] + 1
        )

    regions = []
    seen = set()
    for c in found:
        cx, cy = nl.region_centroid(c["p"])
        rid = f"{round(cx)}_{round(cy)}"
        if rid in seen:
            continue
        seen.add(rid)
        if c["kind"] == "warm":
            on = c["fill"] >= 0.55 and c["area"] >= 16
        elif c["kind"] == "teal":
            on = c["cell"] or (c["fill"] >= 0.6 and c["twins"] >= 1)
        else:
            on = c["fill"] >= 0.66 and (c["twins"] >= 1 or c["area"] > CELL_SPLIT_AREA)
        regions.append(
            {
                "id": rid,
                "k": "w",
                "class": c["kind"],
                "on": bool(on),
                "p": c["p"],
            }
        )
    return {"size": [w, h], "regions": regions}


def debug_image(name: str, entry: dict, scale: int) -> Image.Image:
    rgba = nl.load_rgba(name)
    on = [r for r in entry["regions"] if r["on"]]
    lit = nl.bake_lit(rgba, on, name)
    preview = nl.night_preview(rgba, lit)
    big = cv2.resize(preview, None, fx=scale, fy=scale, interpolation=cv2.INTER_NEAREST)
    for region in entry["regions"]:
        if region["on"]:
            continue
        pts = (np.array(region["p"]).reshape(-1, 2) * scale).astype(np.int32)
        cv2.polylines(big, [pts], True, (230, 70, 70), 1, cv2.LINE_AA)
    return Image.fromarray(big)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="*", help="sprites to run (default: all)")
    ap.add_argument("--debug", help="write night previews here instead of saving")
    ap.add_argument("--scale", type=int, default=2)
    args = ap.parse_args()
    names = args.names or nl.sprite_names()
    result = {}
    for name in names:
        result[name] = detect(name)
        on = sum(r["on"] for r in result[name]["regions"])
        print(f"{name:34s} {on:3d} on / {len(result[name]['regions']):3d}")
    if args.debug:
        out = Path(args.debug)
        out.mkdir(parents=True, exist_ok=True)
        for name in names:
            debug_image(name, result[name], args.scale).save(out / f"{name}.png")
        return
    existing = nl.read_json(nl.CANDIDATES_JSON, {})
    existing.update(result)
    nl.write_json(nl.CANDIDATES_JSON, existing, compact=True)
    print(f"wrote {nl.CANDIDATES_JSON.relative_to(nl.ROOT)} ({len(existing)} sprites)")


if __name__ == "__main__":
    main()
