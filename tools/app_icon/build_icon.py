#!/usr/bin/env python3
"""Generate the Math City launcher icon, launch-screen images and tile art.

One geometry, three consumers:

* ``assets/images/tiles/*.svg`` -- the six tile drawings the home screen's
  intro animates (the icon's house is ``house.svg``; the others are the
  neighbours that pop in around it). Rendered in-app by flutter_svg.
* Android: ``mipmap-*/ic_launcher*.png`` (legacy icon, adaptive foreground /
  background / monochrome layers) plus ``mipmap-anydpi-v26/ic_launcher.xml``.
  The adaptive foreground doubles as the Android 12+ launch-screen icon.
* iOS: every size in ``AppIcon.appiconset/Contents.json`` and the three
  ``LaunchImage`` scales.

The drawing is the "F2" tile from the 2026-09-30 icon mocks: a cottage on a
thin chunk of land, in the board's 2:1 dimetric projection, zoomed so the
house fills the launcher's 72 dp visible circle (the 108 dp adaptive canvas
minus its masked margin).

Rasterising uses macOS QuickLook (``qlmanage``), which renders an SVG at the
pixel size written in its ``width``/``height`` attributes -- but flattens it
onto opaque white. Transparent layers are therefore rendered twice, on black
and on white, and the true alpha recovered from the difference (Pillow and
numpy from the sprite-pipeline venv). Opaque outputs (the iOS icons, which
App Store validation wants without alpha) are rendered once on the sky.

    tools/sprite_pipeline/.venv/bin/python tools/app_icon/build_icon.py

Idempotent; re-run after editing anything in this file.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TILES_DIR = REPO / "assets" / "images" / "tiles"
ANDROID_RES = REPO / "android" / "app" / "src" / "main" / "res"
IOS_ASSETS = REPO / "ios" / "Runner" / "Assets.xcassets"

# ---------------------------------------------------------------------------
# Palette (matches lib/presentation/theme and the wordmark)
# ---------------------------------------------------------------------------
INK = "#1E2A38"
GRASS, GRASS_DK = "#7CB342", "#689F38"
SOIL, SOIL_DK = "#A1887F", "#8D6E63"
CREAM, CREAM_DK = "#F6E7B8", "#E3CC8C"
TEAL_L, TEAL_D = "#CFEEE8", "#9DD5CB"
ROOF, ROOF_DK = "#F2A33A", "#D9822B"
WIN, WHITE = "#5DB7E8", "#FFFFFF"
SKY_TOP, SKY_BOTTOM = "#5DB7E8", "#A4DDC9"

# ---------------------------------------------------------------------------
# Geometry. Icon canvas is 108 units (Android's adaptive-icon dp canvas); the
# launcher shows the inner 72. SAFE scales the mock's F2 drawing so the house
# fills that circle instead of the full square.
# ---------------------------------------------------------------------------
CANVAS = 108
SAFE = 0.85
TILE_W = 42 * SAFE          # half tile width, units
TILE_H = TILE_W / 2         # half tile height
UNIT_Z = 36 * SAFE          # units per 1.0 of height
CX = 54.0
CY = 54 + 8.5 * SAFE        # tile centre sits a little below the canvas centre
THICK = 0.25                # chunk thickness in height units
STROKE = 2.0


class Iso:
    """2:1 dimetric projection emitting SVG primitives."""

    def __init__(self, cx: float, cy: float) -> None:
        self.cx, self.cy = cx, cy

    def p(self, x: float, y: float, z: float = 0.0) -> tuple[float, float]:
        return (self.cx + (x - y) * TILE_W, self.cy + (x + y) * TILE_H - z * UNIT_Z)

    @staticmethod
    def _pts(pts: list[tuple[float, float]]) -> str:
        return " ".join(f"{x:.2f},{y:.2f}" for x, y in pts)

    def poly(self, pts, fill: str, k: float = 1.0) -> str:
        return (
            f'<polygon points="{self._pts(pts)}" fill="{fill}" stroke="{INK}" '
            f'stroke-width="{STROKE * k:.2f}" stroke-linejoin="round"/>'
        )

    def line(self, a, b, color: str = INK, k: float = 1.0) -> str:
        return (
            f'<line x1="{a[0]:.2f}" y1="{a[1]:.2f}" x2="{b[0]:.2f}" y2="{b[1]:.2f}" '
            f'stroke="{color}" stroke-width="{STROKE * k:.2f}" stroke-linecap="round"/>'
        )

    def circ(self, c, r: float, fill: str) -> str:
        return (
            f'<circle cx="{c[0]:.2f}" cy="{c[1]:.2f}" r="{r:.2f}" fill="{fill}" '
            f'stroke="{INK}" stroke-width="{STROKE:.2f}"/>'
        )

    # -- pieces -----------------------------------------------------------
    def tile(self, fill: str = GRASS, thick: float = THICK) -> str:
        s, p = 0.5, self.p
        out = ""
        if thick:
            out += self.poly([p(s, -s), p(s, s), p(s, s, -thick), p(s, -s, -thick)], SOIL_DK)
            out += self.poly([p(-s, s), p(s, s), p(s, s, -thick), p(-s, s, -thick)], SOIL)
        out += self.poly([p(-s, -s), p(s, -s), p(s, s), p(-s, s)], fill)
        return out

    def road(self) -> str:
        """Road running along the tile's y axis (upper-right to lower-left)."""
        s, w, p = 0.5, 0.18, self.p
        out = self.poly([p(-w, -s, 0.005), p(w, -s, 0.005), p(w, s, 0.005), p(-w, s, 0.005)], "#9E9E9E", 0.6)
        out += self.line(p(0, -s + 0.08, 0.01), p(0, s - 0.08, 0.01), CREAM, 0.6)
        return out

    def box(self, x0, y0, x1, y1, h, left=CREAM, right=CREAM_DK, top=None) -> str:
        p = self.p
        out = self.poly([p(x0, y1), p(x1, y1), p(x1, y1, h), p(x0, y1, h)], left)
        out += self.poly([p(x1, y0), p(x1, y1), p(x1, y1, h), p(x1, y0, h)], right)
        if top:
            out += self.poly([p(x0, y0, h), p(x1, y0, h), p(x1, y1, h), p(x0, y1, h)], top)
        return out

    def gable(self, x0, y0, x1, y1, h, r, front=ROOF, back=ROOF_DK, gable=CREAM_DK, chimney=True) -> str:
        p, ym, e = self.p, (y0 + y1) / 2, 0.08
        out = self.poly([p(x0, y0 - e, h), p(x1, y0 - e, h), p(x1, ym, h + r), p(x0, ym, h + r)], back)
        if chimney:
            cx0, cy0 = x0 + 0.16, ym - 0.22
            out += self.box(cx0, cy0, cx0 + 0.12, cy0 + 0.12, h + r + 0.12, CREAM_DK, "#C9AD6E", SOIL_DK)
        out += self.poly([p(x0, y1 + e, h), p(x1, y1 + e, h), p(x1, ym, h + r), p(x0, ym, h + r)], front)
        out += self.poly([p(x1, y0, h), p(x1, y1, h), p(x1, ym, h + r)], gable)
        return out

    def win_r(self, x1, ya, yb, za, zb, fill=WIN) -> str:
        p = self.p
        return self.poly([p(x1, ya, za), p(x1, yb, za), p(x1, yb, zb), p(x1, ya, zb)], fill, 0.75)

    def win_l(self, y1, xa, xb, za, zb, fill=WIN) -> str:
        p = self.p
        return self.poly([p(xa, y1, za), p(xb, y1, za), p(xb, y1, zb), p(xa, y1, zb)], fill, 0.75)

    def tree(self, x, y, r, h=0.5, fill="#5BBF7A") -> str:
        base, top = self.p(x, y, 0), self.p(x, y, h)
        return self.line(base, top, "#6D4C41", 1.2) + self.circ(top, r, fill)


def cottage(g: Iso, left=CREAM, right=CREAM_DK, roof=ROOF, roof_dk=ROOF_DK) -> str:
    x0, y0, x1, y1, h, r = -0.36, -0.31, 0.36, 0.31, 0.6, 0.38
    out = g.box(x0, y0, x1, y1, h, left, right)
    out += g.win_l(y1, -0.24, -0.08, 0.2, 0.44) + g.win_l(y1, 0.12, 0.28, 0.02, 0.44, INK)
    out += g.win_r(x1, -0.2, -0.04, 0.2, 0.44) + g.win_r(x1, 0.06, 0.22, 0.2, 0.44)
    out += g.gable(x0, y0, x1, y1, h, r, roof, roof_dk, right)
    return out


def school(g: Iso) -> str:
    x0, y0, x1, y1, h = -0.42, -0.24, 0.42, 0.24, 0.5
    out = g.box(x0, y0, x1, y1, h)
    out += g.win_l(y1, -0.3, -0.18, 0.16, 0.38) + g.win_l(y1, -0.06, 0.06, 0.16, 0.38)
    out += g.win_l(y1, 0.2, 0.32, 0.02, 0.38, INK)
    out += g.gable(x0, y0, x1, y1, h, 0.3, "#2EB5A0", "#239A88", CREAM_DK, chimney=False)
    pole, tip = g.p(0, 0, h + 0.3), g.p(0, 0, h + 0.7)
    out += g.line(pole, tip)
    out += g.poly([tip, (tip[0] + TILE_W * 0.3, tip[1] + TILE_W * 0.08), (tip[0], tip[1] + TILE_W * 0.16)], ROOF, 0.75)
    return out


TREE_R = 9 * SAFE


def tile_house(g: Iso) -> str:
    return g.tile() + cottage(g) + g.tree(-0.42, 0.4, TREE_R, 0.45)


def tile_house_teal(g: Iso) -> str:
    return g.tile() + cottage(g, TEAL_L, TEAL_D, "#2EB5A0", "#239A88")


def tile_park(g: Iso) -> str:
    return g.tile(GRASS_DK) + g.tree(-0.18, -0.2, TILE_W * 0.24, 0.55) + g.tree(0.2, 0.06, TILE_W * 0.2, 0.45, "#3DA85F")


def tile_school(g: Iso) -> str:
    return g.tile() + school(g)


def tile_road(g: Iso) -> str:
    return g.tile() + g.road()


def tile_grass(g: Iso) -> str:
    return g.tile() + g.tree(0.1, 0.05, TILE_W * 0.22, 0.5)


TILES = {
    "house": tile_house,
    "house_teal": tile_house_teal,
    "park": tile_park,
    "school": tile_school,
    "road": tile_road,
    "grass": tile_grass,
}

SVG_NS = 'xmlns="http://www.w3.org/2000/svg"'


def svg(inner: str, viewbox: str = f"0 0 {CANVAS} {CANVAS}", size: int | None = None) -> str:
    dims = f' width="{size}" height="{size}"' if size else ""
    return f'<svg {SVG_NS} viewBox="{viewbox}"{dims}>{inner}</svg>\n'


def sky_rect() -> str:
    return (
        '<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="{SKY_TOP}"/><stop offset="1" stop-color="{SKY_BOTTOM}"/>'
        f'</linearGradient></defs><rect width="{CANVAS}" height="{CANVAS}" fill="url(#sky)"/>'
    )


def monochrome(inner: str) -> str:
    """Every fill and stroke black: Android 13 themed icons use the alpha only."""
    import re

    inner = re.sub(r'fill="#[0-9A-Fa-f]{6}"', 'fill="#000000"', inner)
    return re.sub(r'stroke="#[0-9A-Fa-f]{6}"', 'stroke="#000000"', inner)


# ---------------------------------------------------------------------------
# Rasterising
# ---------------------------------------------------------------------------

RENDER_PX = 1024  # QuickLook mis-crops small renders; render big, then downscale


def _ql_render(svg_text: str, tmp: Path) -> "Image.Image":
    from PIL import Image  # sprite-pipeline venv

    src = tmp / "icon.svg"
    src.write_text(svg_text)
    subprocess.run(
        ["qlmanage", "-t", "-s", str(RENDER_PX), "-o", str(tmp), str(src)],
        check=True, capture_output=True,
    )
    return Image.open(tmp / "icon.svg.png").convert("RGB")


def rasterize(svg_inner: str, size: int, out: Path, viewbox: str = f"0 0 {CANVAS} {CANVAS}", opaque: bool = False) -> None:
    if shutil.which("qlmanage") is None:
        sys.exit("qlmanage not found: this script rasterises with macOS QuickLook.")
    import numpy as np
    from PIL import Image

    out.parent.mkdir(parents=True, exist_ok=True)
    vb = viewbox.split()
    backdrop = lambda color: f'<rect x="{vb[0]}" y="{vb[1]}" width="{vb[2]}" height="{vb[3]}" fill="{color}"/>'
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        if opaque:
            # The caller's drawing already paints its own ground (a leading
            # rect confuses QuickLook's viewBox cropping).
            im = _ql_render(svg(svg_inner, viewbox, RENDER_PX), tmp)
        else:
            on_black = np.asarray(_ql_render(svg(backdrop("#000000") + svg_inner, viewbox, RENDER_PX), tmp), dtype=np.float32)
            on_white = np.asarray(_ql_render(svg(backdrop("#FFFFFF") + svg_inner, viewbox, RENDER_PX), tmp), dtype=np.float32)
            # Straight-alpha compositing: white - black = 255 * (1 - alpha).
            alpha = np.clip(1 - (on_white - on_black).mean(axis=2) / 255, 0, 1)
            safe = np.where(alpha > 1e-3, alpha, 1)[..., None]
            rgb = np.clip(on_black / safe, 0, 255)
            im = Image.fromarray(np.dstack([rgb, alpha * 255]).astype(np.uint8))
        if size != RENDER_PX:
            im = im.resize((size, size), Image.LANCZOS)
        im.save(out, optimize=True)


def main() -> None:
    g = Iso(CX, CY)
    tiles = {name: draw(g) for name, draw in TILES.items()}
    house = tiles["house"]

    # 1. in-app tile art
    TILES_DIR.mkdir(parents=True, exist_ok=True)
    for name, inner in tiles.items():
        (TILES_DIR / f"{name}.svg").write_text(svg(inner))
    print(f"tiles: {len(tiles)} svg -> {TILES_DIR.relative_to(REPO)}")

    inner_box = f"{(CANVAS - 72) / 2:g} {(CANVAS - 72) / 2:g} 72 72"
    composite = sky_rect() + house

    # 2. Android
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, scale in densities.items():
        d = ANDROID_RES / f"mipmap-{name}"
        rasterize(composite, round(48 * scale), d / "ic_launcher.png", inner_box, opaque=True)
        layer = round(CANVAS * scale)
        rasterize(house, layer, d / "ic_launcher_foreground.png")
        rasterize(sky_rect(), layer, d / "ic_launcher_background.png", opaque=True)
        rasterize(monochrome(house), layer, d / "ic_launcher_monochrome.png")
    (ANDROID_RES / "mipmap-anydpi-v26").mkdir(exist_ok=True)
    (ANDROID_RES / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
        '</adaptive-icon>\n'
    )
    print("android: 5 densities x 4 pngs + adaptive xml")

    # 3. iOS app icon: every entry in Contents.json, opaque
    iconset = IOS_ASSETS / "AppIcon.appiconset"
    manifest = json.loads((iconset / "Contents.json").read_text())
    done: set[str] = set()
    for entry in manifest["images"]:
        fn = entry["filename"]
        if fn in done:
            continue
        pts = float(entry["size"].split("x")[0])
        px = round(pts * float(entry["scale"].rstrip("x")))
        rasterize(composite, px, iconset / fn, inner_box, opaque=True)
        done.add(fn)
    print(f"ios: {len(done)} app icons")

    # 4. iOS launch image: the tile alone, 288 pt, matching Android 12's
    #    launch-screen icon size so both platforms enter the intro on one frame
    launch = IOS_ASSETS / "LaunchImage.imageset"
    for scale in (1, 2, 3):
        suffix = "" if scale == 1 else f"@{scale}x"
        rasterize(house, 288 * scale, launch / f"LaunchImage{suffix}.png")
    print("ios: 3 launch images")


if __name__ == "__main__":
    main()
