import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/mover_depth.dart';

void main() {
  // A 2×2 town hall at (4, 4): key 8, footprint cols 4–5, rows 4–5.
  const hall = (col: 4, row: 4, w: 2, h: 2);

  test('a walker on the road north of a wide building sorts behind it', () {
    // Tile (5, 3): col + row = 8 ties the hall's key, but it is north of it.
    expect(moverDepth(5.3, 3.4, [hall]), lessThan(8));
    // Tile (6, 3) is north-east and past the east edge: in front, and it
    // does not overlap the facade on screen either way.
    expect(moverDepth(6.2, 3, [hall]), greaterThan(8));
  });

  test('a walker west of the building sorts behind it', () {
    expect(moverDepth(3.4, 5.4, [hall]), lessThan(8));
  });

  test('walkers south or east of the building sort in front', () {
    expect(moverDepth(4.5, 6.4, [hall]), greaterThan(8));
    expect(moverDepth(6.4, 4.5, [hall]), greaterThan(8));
  });

  test('a building far away on the same diagonal is ignored', () {
    // (0, 8) is behind-by-rule for a walker at (5.3, 3.4)? No: the walker
    // is past its east edge. Use a walker north-west of a far building.
    const far = (col: 12, row: -4, w: 2, h: 2); // key 8, far to the right
    expect(moverDepth(5.3, 3.4, [far]), 5.3 + 3.4);
  });

  test('keys stay ordered among movers behind the same building', () {
    final a = moverDepth(5.3, 3.4, [hall]);
    final b = moverDepth(5.4, 3.4, [hall]);
    expect(a, lessThan(8));
    expect(b, lessThan(8));
    expect(a, b); // both pulled to the same rung just below the hall
  });

  test('isBehindFootprint follows the east/south edge rule', () {
    expect(isBehindFootprint(5.4, 3, hall), isTrue);
    expect(isBehindFootprint(5.6, 3, hall), isFalse);
    expect(isBehindFootprint(3, 5.6, hall), isFalse);
  });
}
