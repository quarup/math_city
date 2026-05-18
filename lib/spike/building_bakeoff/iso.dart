// Isometric projection helpers for the bake-off harness.
//
// Standard 2:1 isometric tile: a 1x1 grid cell projects to a diamond of width
// [tileW] and height [tileW / 2]. World-Y (height) extrudes straight up by
// [tileH] per unit.

import 'package:flutter/widgets.dart';

class Iso {
  const Iso({this.tileW = 64, this.tileH = 64});

  /// Diamond width on screen (one grid step in either horizontal grid axis).
  final double tileW;

  /// World-Y extrusion: one unit of height = [tileH] vertical pixels on screen.
  final double tileH;

  /// Tile half-width: horizontal distance from diamond centre to edge.
  double get halfW => tileW / 2;

  /// Tile half-height: vertical distance from diamond centre to top/bottom point.
  double get halfH => tileW / 4;

  /// Project an integer grid cell `(gx, gy)` to screen-space, given an origin
  /// (the screen position of the (0, 0) cell centre).
  ///
  /// Standard iso:
  /// `x_screen = (gx - gy) * halfW`, `y_screen = (gx + gy) * halfH`.
  Offset grid(Offset origin, double gx, double gy, {double z = 0}) {
    return Offset(
      origin.dx + (gx - gy) * halfW,
      origin.dy + (gx + gy) * halfH - z * tileH,
    );
  }

  /// The four corners of the diamond at grid cell `(gx, gy)` (ground plane).
  /// Order: top, right, bottom, left.
  List<Offset> diamond(Offset origin, double gx, double gy) {
    final c = grid(origin, gx + 0.5, gy + 0.5);
    return [
      c.translate(0, -halfH),
      c.translate(halfW, 0),
      c.translate(0, halfH),
      c.translate(-halfW, 0),
    ];
  }
}
