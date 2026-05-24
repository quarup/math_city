import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/placement_rules.dart';

/// 1×1 footprint at `(col, row)` — the Phase 7 case.
GridFootprint _at(int col, int row, {int w = 1, int h = 1}) =>
    GridFootprint(col: col, row: row, width: w, height: h);

PlacementCheck _check(
  GridFootprint candidate, {
  List<GridFootprint> existing = const [],
  int gridWidth = 12,
  int gridHeight = 12,
}) => checkPlacement(
  gridWidth: gridWidth,
  gridHeight: gridHeight,
  existing: existing,
  candidate: candidate,
);

void main() {
  group('GridFootprint', () {
    test('tiles enumerates the whole footprint', () {
      expect(_at(2, 3, w: 2, h: 2).tiles().toSet(), {
        (2, 3),
        (3, 3),
        (2, 4),
        (3, 4),
      });
    });

    test('perimeter is the orthogonal ring, no diagonals', () {
      // A 1×1 at (5,5): exactly its 4 orthogonal neighbors.
      expect(_at(5, 5).perimeter().toSet(), {
        (5, 4),
        (5, 6),
        (4, 5),
        (6, 5),
      });
      // Corners (4,4) etc. are NOT included.
      expect(_at(5, 5).perimeter().toSet().contains((4, 4)), isFalse);
    });
  });

  group('checkPlacement — bounds & overlap', () {
    test('first placement on an empty grid is legal', () {
      expect(_check(_at(5, 5)).isLegal, isTrue);
    });

    test('negative coordinates are out of bounds', () {
      expect(
        _check(_at(-1, 5)).rejection,
        PlacementRejection.outOfBounds,
      );
    });

    test('footprint spilling past an edge is out of bounds', () {
      // 2×2 anchored so it pokes past the right/bottom edge of a 6×6 grid.
      expect(
        _check(
          _at(5, 5, w: 2, h: 2),
          gridWidth: 6,
          gridHeight: 6,
        ).rejection,
        PlacementRejection.outOfBounds,
      );
    });

    test('overlapping an existing building is rejected', () {
      expect(
        _check(_at(5, 5), existing: [_at(5, 5)]).rejection,
        PlacementRejection.overlap,
      );
    });
  });

  group('checkPlacement — touching is allowed', () {
    test('placing adjacent to one building is legal', () {
      expect(_check(_at(5, 5), existing: [_at(5, 6)]).isLegal, isTrue);
    });

    test('an L of three around a corner still leaves both open sides', () {
      // Candidate (5,5) touches (6,5) and (5,6); each still has free sides.
      expect(
        _check(_at(5, 5), existing: [_at(6, 5), _at(5, 6)]).isLegal,
        isTrue,
      );
    });
  });

  group('checkPlacement — self box-in', () {
    test('placing into a fully-surrounded hole boxes the candidate in', () {
      // (5,5) hole ringed on all four orthogonal sides.
      final ring = [_at(4, 5), _at(6, 5), _at(5, 4), _at(5, 6)];
      expect(
        _check(_at(5, 5), existing: ring).rejection,
        PlacementRejection.wouldBoxInSelf,
      );
    });

    test('grid edge does not count as an open side', () {
      // Corner (0,0): its only in-bounds neighbors (1,0) and (0,1) are taken;
      // the other two "sides" are off-grid and must not count as road access.
      expect(
        _check(_at(0, 0), existing: [_at(1, 0), _at(0, 1)]).rejection,
        PlacementRejection.wouldBoxInSelf,
      );
    });
  });

  group('checkPlacement — two-way neighbor box-in', () {
    test('taking a neighbor’s last open side is rejected', () {
      // Center (5,5) is hemmed on three sides; only (5,6) is open. Placing
      // there seals the center even though the candidate itself has room.
      final existing = [_at(5, 5), _at(4, 5), _at(6, 5), _at(5, 4)];
      final result = _check(_at(5, 6), existing: existing);
      expect(result.rejection, PlacementRejection.wouldBoxInNeighbor);
    });

    test('a far-away pre-boxed building never blames the new placement', () {
      // Even if some unrelated building were sealed in elsewhere, placing on
      // open ground that abuts nothing is legal — we only re-check neighbors
      // the candidate actually touches.
      final existing = [_at(5, 6)];
      expect(_check(_at(0, 0), existing: existing).isLegal, isTrue);
    });
  });

  group('checkPlacement — moves (exclude the moved building)', () {
    test('moving onto a tile that overlaps only the mover itself is legal', () {
      // Two buildings: the "mover" at (5,5) and a bystander at (8,8). Moving
      // the mover to (5,6) with itself excluded from `existing` is legal.
      final result = checkPlacement(
        gridWidth: 12,
        gridHeight: 12,
        existing: [_at(8, 8)], // mover excluded
        candidate: _at(5, 6),
      );
      expect(result.isLegal, isTrue);
    });
  });

  group('checkPlacement — multi-tile footprint', () {
    test('a 2×2 on open ground is legal', () {
      expect(_check(_at(5, 5, w: 2, h: 2)).isLegal, isTrue);
    });

    test('a 2×2 ringed on all eight edge tiles is boxed in', () {
      // The 2×2 candidate occupies (5,5),(6,5),(5,6),(6,6); ring every
      // orthogonal perimeter tile so it has no open side.
      final ring = [
        _at(5, 4), _at(6, 4), // above
        _at(5, 7), _at(6, 7), // below
        _at(4, 5), _at(4, 6), // left
        _at(7, 5), _at(7, 6), // right
      ];
      expect(
        _check(_at(5, 5, w: 2, h: 2), existing: ring).rejection,
        PlacementRejection.wouldBoxInSelf,
      );
    });
  });
}
