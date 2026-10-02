import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/street_lamps.dart';

void main() {
  group('lampSpots', () {
    final street = {for (var c = -6; c <= 9; c++) (c, 0)};

    test('every other tile of a straight street, swapping sides', () {
      final spots = lampSpots(street);
      // Ends are dead ends (one neighbour): no lamp there.
      expect(spots.every((s) => s.col.isEven), isTrue);
      expect(spots.map((s) => s.col), [-4, -2, 0, 2, 4, 6, 8]);
      expect(spots.every((s) => s.alongEast && s.de == 0), isTrue);
      expect(spots.map((s) => s.ds.sign).toSet(), {-1.0, 1.0});
      for (final s in spots) {
        expect(s.ds.abs(), kLampOffset);
      }
      // Sides alternate lamp by lamp.
      for (var i = 1; i < spots.length; i++) {
        expect(spots[i].ds, -spots[i - 1].ds);
      }
    });

    test('a north-south street puts them east and west', () {
      final spots = lampSpots({for (var r = 0; r <= 8; r++) (3, r)});
      expect(spots, isNotEmpty);
      expect(spots.every((s) => !s.alongEast && s.ds == 0), isTrue);
      expect(spots.every((s) => s.de.abs() == kLampOffset), isTrue);
    });

    test('junctions and bends stay clear', () {
      final roads = {...street, for (var r = 1; r <= 6; r++) (2, r)};
      final spots = lampSpots(roads);
      expect(spots.any((s) => s.col == 2 && s.row == 0), isFalse);
      final bend = lampSpots({(0, 0), (1, 0), (1, 1), (1, 2)});
      expect(bend.any((s) => s.col == 1 && s.row == 0), isFalse);
    });

    test('a lamp keeps its place when the street grows', () {
      final longer = {...street, for (var c = 10; c <= 20; c++) (c, 0)};
      final before = lampSpots(street).where((s) => s.col < 8).toSet();
      final after = lampSpots(longer).where((s) => s.col < 8).toSet();
      expect(after, before);
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
