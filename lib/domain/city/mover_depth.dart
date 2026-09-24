/// Painter's-order key for a small mover (walker, car) among multi-tile
/// buildings.
///
/// The board sorts everything by `col + row`; a building uses its top-left
/// tile, which is right for buildings against buildings but wrong for a
/// point next to a wide building: a walker on the road north of a 2×2 town
/// hall at `(c+1, r−1)` sums to `c+r`, so it ties or beats the hall and is
/// painted over its facade. Iso occlusion for a point against a box is
/// simple, though — the point is **in front** of the box only if it is
/// past the box's east edge or past its south edge; anywhere else (north,
/// west, or their corner) it is behind. So a mover keeps `col + row` as its
/// key and is pulled just below the key of any building it is behind and
/// could overlap on screen.
///
/// Pure Dart — no Flutter / Flame.
library;

/// A building footprint in tile units: top-left tile and size.
typedef Footprint = ({int col, int row, int w, int h});

/// Slack, in tile-x units (`col − row`), added to a building's screen extent
/// when deciding whether a mover could overlap it.
const double _overlapMargin = 0.3;

/// How far below a building's key a mover it is behind sorts.
const double _behindStep = 0.01;

/// Whether a point at `(col, row)` is behind [b]: not past its east edge
/// (`col ≥ b.col + b.w − ½`) and not past its south edge.
bool isBehindFootprint(double col, double row, Footprint b) =>
    col < b.col + b.w - 0.5 && row < b.row + b.h - 0.5;

/// Whether a point could share screen columns with [b]: screen x grows with
/// `col − row`, and [b] spans `[b.col − b.row − b.h, b.col − b.row + b.w]`.
bool overlapsFootprintOnScreen(double col, double row, Footprint b) {
  final x = col - row;
  final centre = b.col - b.row + (b.w - b.h) / 2;
  return (x - centre).abs() < (b.w + b.h) / 2 + _overlapMargin;
}

/// Sort key for a mover at fractional `(col, row)` among [buildings] keyed by
/// their top-left `col + row`.
double moverDepth(double col, double row, Iterable<Footprint> buildings) {
  var key = col + row;
  for (final b in buildings) {
    final bKey = (b.col + b.row).toDouble();
    if (key < bKey) continue;
    if (!isBehindFootprint(col, row, b)) continue;
    if (!overlapsFootprintOnScreen(col, row, b)) continue;
    key = bKey - _behindStep;
  }
  return key;
}
