/// Pure isometric (2:1 dimetric) grid geometry. Deliberately free of any
/// Flutter / Flame imports so the screen↔grid round-trip can be unit-tested.
///
/// Tile diamonds are [tileWidth] wide and `tileWidth / 2` tall. The board is
/// laid out so tile `(col, row)` centers sit on a regular lattice and the
/// whole board fits inside `[0, boardWidth] × [0, boardHeight]` in local
/// space (origin shifted so no coordinate is negative).
class IsoGrid {
  const IsoGrid({
    required this.cols,
    required this.rows,
    this.tileWidth = 64,
  });

  final int cols;
  final int rows;
  final double tileWidth;

  double get tileHeight => tileWidth / 2;
  double get _halfW => tileWidth / 2;
  double get _halfH => tileWidth / 4;

  /// Horizontal origin shift so the left-most diamond's edge sits at x = 0.
  double get _originX => rows * _halfW;

  /// Vertical origin shift so the top diamond's edge sits at y = 0.
  double get _originY => _halfH;

  /// Local-space bounding box of every diamond on the board.
  double get boardWidth => (cols + rows) * _halfW;
  double get boardHeight => (cols + rows) * _halfH;

  /// Center of tile `(col, row)` in local board space.
  (double, double) centerOf(int col, int row) =>
      (_originX + (col - row) * _halfW, _originY + (col + row) * _halfH);

  /// The grid tile containing local point `(x, y)`, or null if the point is
  /// outside the board. Inverse of [centerOf].
  (int, int)? tileAt(double x, double y) {
    final dx = x - _originX;
    final dy = y - _originY;
    // a = col - row, b = col + row.
    final a = dx / _halfW;
    final b = dy / _halfH;
    final col = ((a + b) / 2).round();
    final row = ((b - a) / 2).round();
    if (col < 0 || col >= cols || row < 0 || row >= rows) return null;
    return (col, row);
  }
}
