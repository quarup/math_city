import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/street_lamps.dart';

void main() {
  group('lampSpots', () {
    final street = {for (var c = -6; c <= 9; c++) (c, 0)};
    LampSpot? at(Set<(int, int)> roads, int c, int r) =>
        lampSpots(roads).where((s) => s.col == c && s.row == r).firstOrNull;

    test('every other tile of a straight street, swapping sides', () {
      final spots = lampSpots(street).where((s) => s.col > -6).toList();
      expect(spots.map((s) => s.col), [-4, -2, 0, 2, 4, 6, 8]);
      expect(spots.every((s) => s.alongEast && s.de == 0), isTrue);
      for (final s in spots) {
        expect(s.ds.abs(), kLampOffset);
      }
      // Sides alternate lamp by lamp.
      for (var i = 1; i < spots.length; i++) {
        expect(spots[i].ds, -spots[i - 1].ds);
      }
    });

    test('a north-south street puts them east and west, alternating', () {
      final spots = lampSpots({for (var r = -1; r <= 9; r++) (3, r)});
      // Both ends are dead ends, lit from their far side.
      expect(spots.map((s) => s.row), [-1, 1, 3, 5, 7, 9]);
      final along = spots.where((s) => s.row > -1 && s.row < 9).toList();
      expect(along.every((s) => !s.alongEast && s.ds == 0), isTrue);
      expect(along.every((s) => s.de.abs() == kLampOffset), isTrue);
      for (var i = 1; i < along.length; i++) {
        expect(along[i].de, -along[i - 1].de);
      }
    });

    test('lamps form a checkerboard: never on two tiles side by side', () {
      final grid = {
        for (var c = 0; c < 8; c++)
          for (var r = 0; r < 8; r++)
            if (c.isEven || r.isEven) (c, r),
      };
      final spots = lampSpots(grid);
      expect(spots, isNotEmpty);
      expect(spots.every((s) => (s.col + s.row).isEven), isTrue);
    });

    test('a T-junction is lit from its one kerb', () {
      // Street along row 0, a side street going south from (2, 0).
      final roads = {...street, for (var r = 1; r <= 6; r++) (2, r)};
      final lamp = at(roads, 2, 0)!;
      expect((lamp.de, lamp.ds), (0, -kLampOffset));
      expect(lamp.alongEast, isTrue);
    });

    test('a two-tile-wide road is lit along both its edges', () {
      final wide = {
        for (var c = 0; c <= 9; c++) ...[(c, 0), (c, 1)],
      };
      final spots = lampSpots(wide).where((s) => s.col > 0 && s.col < 9);
      expect(spots, hasLength(8));
      for (final s in spots) {
        // The north row from its north kerb, the south row from its south.
        expect(s.ds, s.row == 0 ? -kLampOffset : kLampOffset);
        expect(s.de, 0);
      }
    });

    test('a crossing stays clear', () {
      final cross = {
        for (var c = -3; c <= 3; c++) (c, 0),
        for (var r = -3; r <= 3; r++) (0, r),
      };
      expect(at(cross, 0, 0), isNull);
    });

    test('a bend is lit from one of its outer sides', () {
      // East along row 0, then south down column 2: the bend is (2, 0).
      final bend = {(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)};
      final lamp = at(bend, 2, 0)!;
      expect(
        (lamp.de, lamp.ds),
        anyOf((kLampOffset, 0.0), (0.0, -kLampOffset)),
      );
    });

    test('a dead end is lit from its far end', () {
      final east = at(street, -6, 0)!; // the way in is east: lamp at the west
      expect((east.de, east.ds), (-kLampOffset, 0));
      expect(east.alongEast, isFalse);
      final south = at({for (var r = 0; r <= 5; r++) (1, r)}, 1, 5)!;
      expect((south.de, south.ds), (0, kLampOffset));
    });

    test('a lone tile has no lamp', () {
      expect(lampSpots({(4, 4)}), isEmpty);
    });

    test('a lamp keeps its place when the street grows', () {
      final longer = {...street, for (var c = 10; c <= 20; c++) (c, 0)};
      final before = lampSpots(street).where((s) => s.col < 8).toSet();
      final after = lampSpots(longer).where((s) => s.col < 8).toSet();
      expect(after, before);
    });

    test('no two lamps stand closer than the minimum gap', () {
      // A winding road: bends put lamps on tiles that touch at a corner.
      final winding = {
        for (var c = 0; c <= 3; c++) (c, 0),
        for (var r = 1; r <= 3; r++) (3, r),
        for (var c = 4; c <= 6; c++) (c, 3),
        for (var r = 4; r <= 6; r++) (6, r),
        for (var c = 0; c <= 5; c++) (c, 6),
        for (var r = 1; r <= 5; r++) (0, r),
      };
      final ringTown = {
        for (var c = 0; c <= 6; c++)
          for (var r = 0; r <= 6; r++)
            if (c.isEven || r.isEven) (c, r),
      };
      for (final roads in [winding, ringTown]) {
        final spots = lampSpots(roads);
        expect(spots.length, greaterThan(4));
        for (var i = 0; i < spots.length; i++) {
          for (var j = i + 1; j < spots.length; j++) {
            final a = spots[i];
            final b = spots[j];
            final dx = (a.col + a.de) - (b.col + b.de);
            final dy = (a.row + a.ds) - (b.row + b.ds);
            expect(
              dx * dx + dy * dy,
              greaterThanOrEqualTo(kLampMinGap * kLampMinGap),
              reason: '$a and $b',
            );
          }
        }
      }
    });

    test('a tight town of ring roads is lit all through', () {
      // Four 1×1 buildings two tiles apart: every road tile touches a
      // junction, which the straight-tiles-only rule left dark.
      final buildings = {(1, 1), (3, 1), (1, 3), (3, 3)};
      final roads = {
        for (var c = 0; c <= 4; c++)
          for (var r = 0; r <= 4; r++)
            if (!buildings.contains((c, r))) (c, r),
      };
      final spots = lampSpots(roads);
      expect(spots.length, greaterThanOrEqualTo(8));
      // Every building has a lamp on a tile next to it.
      for (final (bc, br) in buildings) {
        expect(
          spots.any(
            (s) => (s.col - bc).abs() <= 1 && (s.row - br).abs() <= 1,
          ),
          isTrue,
        );
      }
    });
  });

  group('lampLightAt', () {
    test('off by day, on all night', () {
      for (var c = 0; c < 12; c++) {
        expect(lampLightAt(12, c, 0), 0);
        expect(lampLightAt(16.5, c, 0), 0);
        expect(lampLightAt(21, c, 0), 1);
        expect(lampLightAt(2, c, 0), 1);
        expect(lampLightAt(7, c, 0), 0);
      }
    });

    test('they come on one by one across dusk', () {
      final onTimes = <double>{};
      for (var c = 0; c < 20; c++) {
        var h = 17.0;
        while (lampLightAt(h, c, 3) < 0.5) {
          h += 0.01;
        }
        expect(h, inInclusiveRange(17.5, 18.45));
        onTimes.add((h * 100).round() / 100);
      }
      expect(onTimes.length, greaterThan(12));
    });

    test('fades up rather than snapping', () {
      var h = 17.0;
      while (lampLightAt(h, 4, 4) == 0) {
        h += 0.001;
      }
      expect(lampLightAt(h + kLampFadeHours / 2, 4, 4), closeTo(0.5, 0.06));
    });
  });
}
