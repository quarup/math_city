#!/usr/bin/env python3
"""The review page for building lights: http://127.0.0.1:8765

Shows every building sprite at night with its detected window regions.
Click a region to switch it on or off, use the wand or the box to add what
the detector missed, and mark the sprite reviewed. Every change is saved to
overrides.json and baked into assets/buildings/ at once, so the app (and
`git diff`) always shows the current state.

    tools/sprite_pipeline/.venv/bin/python tools/night_lights/serve.py
"""
from __future__ import annotations

import io
import json
import sys
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build  # noqa: E402
import nl_common as nl  # noqa: E402

PORT = 8765


def wand(name: str, x: int, y: int, tolerance: int) -> list[float] | None:
    """Magic wand: the patch of similar colour around (x, y), as a polygon.
    The fill runs on a lightly smoothed copy so paint texture does not stop
    it, and it gives up on anything bigger than a shop front."""
    rgba = nl.load_rgba(name)
    h, w = rgba.shape[:2]
    if not (0 <= x < w and 0 <= y < h) or rgba[y, x, 3] < 40:
        return None
    smooth = cv2.bilateralFilter(rgba[..., :3], 5, 30, 3)
    mask = np.zeros((h + 2, w + 2), np.uint8)
    # Transparent pixels are walls for the fill.
    mask[1:-1, 1:-1][rgba[..., 3] < 40] = 1
    tol = (tolerance,) * 3
    cv2.floodFill(
        smooth.copy(), mask, (x, y), 0, tol, tol,
        4 | cv2.FLOODFILL_MASK_ONLY | cv2.FLOODFILL_FIXED_RANGE | (2 << 8),
    )
    patch = mask[1:-1, 1:-1] == 2
    if patch.sum() < 6 or patch.sum() > 6000:
        return None
    patch = cv2.morphologyEx(
        patch.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8)
    )
    return nl.tidy_polygon(patch > 0)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):  # quiet
        pass

    def _send(self, code: int, body: bytes, kind: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, data, code=200) -> None:
        self._send(code, json.dumps(data).encode(), "application/json")

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?")[0]
        if path == "/":
            self._send(200, (nl.HERE / "review.html").read_bytes(), "text/html")
        elif path == "/api/state":
            candidates = nl.read_json(nl.CANDIDATES_JSON, {})
            overrides = nl.read_json(nl.OVERRIDES_JSON, {})
            self._json(
                {
                    "tint": [80, 95, 160],
                    "sprites": {
                        name: {
                            "size": candidates.get(name, {}).get("size"),
                            "regions": build.all_regions(name, candidates, overrides),
                            "reviewed": bool(overrides.get(name, {}).get("reviewed")),
                        }
                        for name in nl.sprite_names()
                    },
                }
            )
        elif path.startswith("/sprites/"):
            file = nl.SPRITES / Path(path).name
            if file.exists():
                self._send(200, file.read_bytes(), "image/png")
            else:
                self._send(404, b"", "text/plain")
        elif path.startswith("/api/lit/"):
            # Every region lit, on or off: the page clips to the ones that
            # are on, so a toggle needs no round trip.
            name = Path(path).stem
            candidates = nl.read_json(nl.CANDIDATES_JSON, {})
            overrides = nl.read_json(nl.OVERRIDES_JSON, {})
            regions = build.all_regions(name, candidates, overrides)
            lit = nl.bake_lit(nl.load_rgba(name), regions, name)
            buffer = io.BytesIO()
            Image.fromarray(lit).save(buffer, format="PNG")
            self._send(200, buffer.getvalue(), "image/png")
        else:
            self._send(404, b"not found", "text/plain")

    def do_POST(self) -> None:  # noqa: N802
        length = int(self.headers.get("Content-Length", 0))
        payload = json.loads(self.rfile.read(length) or b"{}")
        path = self.path
        if path.startswith("/api/save/"):
            name = Path(path).name
            overrides = nl.read_json(nl.OVERRIDES_JSON, {})
            overrides[name] = {
                "set": payload.get("set", {}),
                "kind": payload.get("kind", {}),
                "shape": payload.get("shape", {}),
                "added": payload.get("added", []),
                "reviewed": bool(payload.get("reviewed")),
            }
            nl.write_json(nl.OVERRIDES_JSON, dict(sorted(overrides.items())))
            candidates = nl.read_json(nl.CANDIDATES_JSON, {})
            lights = nl.read_json(nl.LIGHTS_JSON, {})
            count = build.build_sprite(name, candidates, overrides, lights)
            nl.write_json(nl.LIGHTS_JSON, dict(sorted(lights.items())), compact=True)
            self._json({"ok": True, "regions": count})
        elif path.startswith("/api/wand/"):
            name = Path(path).name
            polygon = wand(
                name, int(payload["x"]), int(payload["y"]), int(payload.get("tol", 18))
            )
            self._json({"p": polygon})
        else:
            self._json({"ok": False}, 404)


def main() -> None:
    if not nl.CANDIDATES_JSON.exists():
        sys.exit("run detect.py first: no candidates.json")
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    url = f"http://127.0.0.1:{PORT}"
    print(f"night-lights review: {url}  (Ctrl-C to stop)")
    if "--no-open" not in sys.argv:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
