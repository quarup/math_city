import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/game/city/land_window.dart';

void main() {
  group('computeLandWindow', () {
    test('bounds a single set of tiles tightly', () {
      final w = computeLandWindow({(-4, -4), (7, 7), (0, 0)}, null);
      expect((w.minCol, w.minRow), (-4, -4));
      expect((w.maxCol, w.maxRow), (7, 7));
      expect((w.cols, w.rows), (12, 12));
    });

    test('grows monotonically — never shrinks below the previous window', () {
      final start = computeLandWindow({(-4, -4), (7, 7)}, null);
      // A later frame whose tiles are a strict subset must not shrink.
      final next = computeLandWindow({(0, 0)}, start);
      expect(next.sameAs(start), isTrue);
    });

    test('expands outward when new land is bought past the edge', () {
      final start = computeLandWindow({(0, 0), (7, 7)}, null);
      final grown = computeLandWindow({(11, 0)}, start);
      expect(grown.minCol, 0);
      expect(grown.maxCol, 11);
      expect(grown.maxRow, 7);
    });

    test('sameAs distinguishes offset and size', () {
      const a = LandWindow(minCol: 0, minRow: 0, cols: 4, rows: 4);
      const b = LandWindow(minCol: 0, minRow: 0, cols: 4, rows: 4);
      const c = LandWindow(minCol: -4, minRow: 0, cols: 8, rows: 4);
      expect(a.sameAs(b), isTrue);
      expect(a.sameAs(c), isFalse);
    });
  });
}
