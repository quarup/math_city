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

void main() {
  test('no buildings means no roads', () {
    expect(_roads(const []), isEmpty);
  });

  test('a lone building gets a one-tile road frame around it', () {
    final roads = _roads([_at(5, 5)]);
    // 3×3 block (4..6) minus the building tile = 8 road tiles.
    expect(roads.length, 8);
    expect(roads, contains((4, 4)));
    expect(roads, contains((5, 4)));
    expect(roads, contains((6, 6)));
    // The building tile itself is never road.
    expect(roads, isNot(contains((5, 5))));
    // Nothing beyond the frame is paved.
    expect(roads, isNot(contains((3, 5))));
    expect(roads, isNot(contains((7, 5))));
  });

  test('a corner building clamps its frame to the grid', () {
    final roads = _roads([_at(0, 0)]);
    expect(roads, {(0, 1), (1, 0), (1, 1)});
  });

  test('the gap between two buildings is paved', () {
    final roads = _roads([_at(2, 2), _at(5, 2)]);
    // Built-up box cols 2..5 row 2, expanded to cols 1..6, rows 1..3.
    expect(roads.length, 6 * 3 - 2); // box area minus the two buildings
    expect(roads, contains((3, 2))); // the gap between them
    expect(roads, contains((4, 2)));
    expect(roads, contains((1, 1))); // frame corner
    expect(roads, isNot(contains((2, 2))));
    expect(roads, isNot(contains((5, 2))));
    expect(roads, isNot(contains((0, 2)))); // outside the built-up box
  });

  test('building tiles are never roads, even multi-tile footprints', () {
    final roads = _roads([_at(5, 5, w: 2, h: 2)]);
    // Footprint (5,5),(6,5),(5,6),(6,6); box expanded to cols 4..7, rows 4..7.
    expect(roads.length, 4 * 4 - 4);
    for (final t in [(5, 5), (6, 5), (5, 6), (6, 6)]) {
      expect(roads, isNot(contains(t)));
    }
    expect(roads, contains((4, 4)));
    expect(roads, contains((7, 7)));
  });

  test('every building is fronted by at least one road tile', () {
    // The road-access invariant guarantees an open orthogonal neighbor; that
    // neighbor must end up paved.
    final buildings = [_at(3, 3), _at(8, 8), _at(0, 11)];
    final roads = _roads(buildings);
    for (final b in buildings) {
      final fronted = b.perimeter().any(roads.contains);
      expect(fronted, isTrue, reason: 'building at (${b.col},${b.row})');
    }
  });
}
