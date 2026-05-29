import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/placement_rules.dart';
import 'package:math_city/domain/city/road_network.dart';

GridFootprint _at(int col, int row, {int w = 1, int h = 1}) =>
    GridFootprint(col: col, row: row, width: w, height: h);

Set<(int, int)> _roads(
  List<GridFootprint> buildings, {
  int gridWidth = 12,
  int gridHeight = 12,
}) => generateRoads(
  gridWidth: gridWidth,
  gridHeight: gridHeight,
  buildings: buildings,
);

/// True if [roads] is a single orthogonally-connected network (or empty).
bool _isConnected(Set<(int, int)> roads) {
  if (roads.isEmpty) return true;
  const ortho = [(0, -1), (0, 1), (-1, 0), (1, 0)];
  final seen = <(int, int)>{roads.first};
  final stack = <(int, int)>[roads.first];
  while (stack.isNotEmpty) {
    final (c, r) = stack.removeLast();
    for (final (dc, dr) in ortho) {
      final n = (c + dc, r + dr);
      if (roads.contains(n) && seen.add(n)) stack.add(n);
    }
  }
  return seen.length == roads.length;
}

void main() {
  test('no buildings means no roads', () {
    expect(_roads(const []), isEmpty);
  });

  test('a lone building gets a connected 8-tile hug ring', () {
    final roads = _roads([_at(5, 5)]);
    expect(roads, {
      (4, 4),
      (5, 4),
      (6, 4),
      (4, 5),
      (6, 5),
      (4, 6),
      (5, 6),
      (6, 6),
    });
    expect(roads, isNot(contains((5, 5)))); // the building itself
    expect(_isConnected(roads), isTrue);
  });

  test('a corner building clamps its ring to the grid', () {
    expect(_roads([_at(0, 0)]), {(1, 0), (0, 1), (1, 1)});
  });

  test('touching buildings share one outline, no interior fill', () {
    final roads = _roads([_at(5, 5), _at(6, 5)]);
    expect(roads, {
      (4, 4),
      (5, 4),
      (6, 4),
      (7, 4),
      (4, 5),
      (7, 5),
      (4, 6),
      (5, 6),
      (6, 6),
      (7, 6),
    });
    expect(roads, isNot(contains((5, 5))));
    expect(roads, isNot(contains((6, 5))));
    expect(_isConnected(roads), isTrue);
  });

  test('the gap between buildings two apart is paved (same island)', () {
    final roads = _roads([_at(5, 5), _at(8, 5)]);
    // Both gap tiles are Moore-adjacent to a building, so both pave and the
    // two rings touch into one network — no separate connector needed.
    expect(roads, contains((6, 5)));
    expect(roads, contains((7, 5)));
    expect(_isConnected(roads), isTrue);
  });

  test('distant islands are threaded together, not bbox-filled', () {
    final roads = _roads([_at(3, 3), _at(3, 9)]);
    // One connected network...
    expect(_isConnected(roads), isTrue);
    // ...with a thin connector crossing the gap in one of the ring columns...
    expect([(2, 6), (3, 6), (4, 6)].any(roads.contains), isTrue);
    // ...but open space off to the side stays green (the whole point).
    expect(roads, isNot(contains((6, 6))));
    expect(roads, isNot(contains((0, 6))));
  });

  test('multi-tile footprints are ringed, never paved over', () {
    final roads = _roads([_at(5, 5, w: 2, h: 2)]);
    for (final t in [(5, 5), (6, 5), (5, 6), (6, 6)]) {
      expect(roads, isNot(contains(t)));
    }
    expect(roads, contains((4, 4))); // ring corner
    expect(roads, contains((7, 7)));
    expect(_isConnected(roads), isTrue);
  });

  test('every building is fronted by at least one road tile', () {
    final buildings = [_at(2, 2), _at(8, 8), _at(0, 11)];
    final roads = _roads(buildings);
    for (final b in buildings) {
      expect(
        b.perimeter().any(roads.contains),
        isTrue,
        reason: 'building at (${b.col},${b.row})',
      );
    }
    expect(_isConnected(roads), isTrue);
  });
}
