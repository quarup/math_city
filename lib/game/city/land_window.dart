/// The rectangular slice of the infinite land plane the board currently
/// renders: the bounding box (in world tiles) of the owned land plus its pale
/// purchasable frontier. The presentation layer translates world tiles into
/// this window's local coords (subtract `minCol`/`minRow`) for the renderer,
/// and back on tap.
///
/// The window grows **monotonically** — land is buy-only, so once a tile is in
/// view it stays in view and the local origin only moves outward. That keeps
/// the camera-compensation math simple (the offset delta is always one-signed).
///
/// Pure value type — no Flutter / Flame imports.
library;

class LandWindow {
  const LandWindow({
    required this.minCol,
    required this.minRow,
    required this.cols,
    required this.rows,
  });

  /// World-tile coordinate of the window's top-left (min) corner. Subtract this
  /// from a world tile to get its window-local coordinate.
  final int minCol;
  final int minRow;

  /// Window size in tiles.
  final int cols;
  final int rows;

  int get maxCol => minCol + cols - 1;
  int get maxRow => minRow + rows - 1;

  bool sameAs(LandWindow other) =>
      minCol == other.minCol &&
      minRow == other.minRow &&
      cols == other.cols &&
      rows == other.rows;
}

/// The block-aligned bounding window over [tiles] (owned ∪ buyable world
/// tiles), grown monotonically from [previous] so the window never shrinks.
/// [tiles] must be non-empty — a city always owns its starting blocks.
LandWindow computeLandWindow(Iterable<(int, int)> tiles, LandWindow? previous) {
  var minC = previous?.minCol;
  var minR = previous?.minRow;
  var maxC = previous?.maxCol;
  var maxR = previous?.maxRow;
  for (final (c, r) in tiles) {
    minC = (minC == null || c < minC) ? c : minC;
    minR = (minR == null || r < minR) ? r : minR;
    maxC = (maxC == null || c > maxC) ? c : maxC;
    maxR = (maxR == null || r > maxR) ? r : maxR;
  }
  return LandWindow(
    minCol: minC!,
    minRow: minR!,
    cols: maxC! - minC + 1,
    rows: maxR! - minR + 1,
  );
}
