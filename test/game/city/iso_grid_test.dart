import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/game/city/iso_grid.dart';

void main() {
  group('IsoGrid geometry', () {
    const grid = IsoGrid(cols: 12, rows: 12);

    test('board bounding box matches a 2:1 dimetric 12x12 board', () {
      // (cols+rows)*tileWidth/2 wide, half that tall.
      expect(grid.boardWidth, 12 * 64.0);
      expect(grid.boardHeight, 6 * 64.0);
    });

    test('every tile center sits inside the board box', () {
      for (var row = 0; row < grid.rows; row++) {
        for (var col = 0; col < grid.cols; col++) {
          final (cx, cy) = grid.centerOf(col, row);
          expect(cx, inInclusiveRange(0, grid.boardWidth));
          expect(cy, inInclusiveRange(0, grid.boardHeight));
        }
      }
    });

    test('tileAt(centerOf(t)) round-trips for every tile', () {
      for (var row = 0; row < grid.rows; row++) {
        for (var col = 0; col < grid.cols; col++) {
          final (cx, cy) = grid.centerOf(col, row);
          expect(grid.tileAt(cx, cy), (col, row));
        }
      }
    });

    test('points near a tile center still resolve to that tile', () {
      final (cx, cy) = grid.centerOf(5, 7);
      // A small nudge within the diamond stays on the same tile.
      expect(grid.tileAt(cx + 4, cy + 2), (5, 7));
      expect(grid.tileAt(cx - 4, cy - 2), (5, 7));
    });

    test('points outside the board return null', () {
      expect(grid.tileAt(-50, -50), isNull);
      final farX = grid.boardWidth + 100;
      final farY = grid.boardHeight + 100;
      expect(grid.tileAt(farX, farY), isNull);
    });

    test('non-square boards round-trip too', () {
      const wide = IsoGrid(cols: 8, rows: 5, tileWidth: 48);
      for (var row = 0; row < wide.rows; row++) {
        for (var col = 0; col < wide.cols; col++) {
          final (cx, cy) = wide.centerOf(col, row);
          expect(wide.tileAt(cx, cy), (col, row));
        }
      }
    });
  });
}
