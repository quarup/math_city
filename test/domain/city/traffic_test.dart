import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/traffic.dart';

void main() {
  // A 3-wide ring road around a 1×1 block, plus a dead-end spur east.
  //   (0,0) (1,0) (2,0)
  //   (0,1)       (2,1) (3,1) (4,1)
  //   (0,2) (1,2) (2,2)
  final ring = <(int, int)>{
    (0, 0), (1, 0), (2, 0), //
    (0, 1), (2, 1), (3, 1), (4, 1), //
    (0, 2), (1, 2), (2, 2),
  };
  bool isRoad(int c, int r) => ring.contains((c, r));

  double dist((double, double) a, (double, double) b) =>
      math.sqrt(math.pow(a.$1 - b.$1, 2) + math.pow(a.$2 - b.$2, 2));

  group('vehicleHeading', () {
    test('grid directions map to the even headings', () {
      expect(vehicleHeading(1, 0), 0); // east: down-right
      expect(vehicleHeading(0, 1), 2); // south: down-left
      expect(vehicleHeading(-1, 0), 4); // west: up-left
      expect(vehicleHeading(0, -1), 6); // north: up-right
    });

    test('diagonals in tile space are the odd, screen-axis headings', () {
      expect(vehicleHeading(1, 1), 1); // straight down the screen
      expect(vehicleHeading(-1, 1), 3); // left
      expect(vehicleHeading(-1, -1), 5); // up
      expect(vehicleHeading(1, -1), 7); // right
    });

    test('snaps to the nearest heading part-way round a bend', () {
      // Tile-space angles from east toward south; on screen these land at
      // 47°, 90° and 133° (the 2:1 projection is not linear in angle), so
      // the first snaps to down-right, the middle to down, the last to
      // down-left.
      const a = math.pi / 9;
      expect(vehicleHeading(math.cos(a), math.sin(a)), 0);
      expect(vehicleHeading(math.cos(2.25 * a), math.sin(2.25 * a)), 1);
      expect(vehicleHeading(math.cos(3.5 * a), math.sin(3.5 * a)), 2);
    });
  });

  group('vehiclePathFor', () {
    test('straight through stays in the right-hand lane edge to edge', () {
      final pts = vehiclePathFor(dirIn: 0, dir: 0, lane: 0.14);
      expect(pts.first, (-0.5, 0.14));
      expect(pts.last, (0.5, 0.14));
    });

    test('a right turn is a quarter circle on the inner lane', () {
      // East in, south out: the corner between those edges is (-0.5, 0.5).
      final pts = vehiclePathFor(dirIn: 0, dir: 1, lane: 0.14);
      expect(pts.first.$1, closeTo(-0.5, 1e-9));
      expect(pts.first.$2, closeTo(0.14, 1e-9));
      expect(pts.last.$1, closeTo(-0.14, 1e-9));
      expect(pts.last.$2, closeTo(0.5, 1e-9));
      for (final p in pts) {
        expect(dist(p, (-0.5, 0.5)), closeTo(0.5 - 0.14, 1e-9));
      }
    });

    test('a left turn is a quarter circle on the outer lane', () {
      // East in, north out: corner (-0.5, -0.5).
      final pts = vehiclePathFor(dirIn: 0, dir: 3, lane: 0.14);
      expect(pts.first.$1, closeTo(-0.5, 1e-9));
      expect(pts.last.$2, closeTo(-0.5, 1e-9));
      for (final p in pts) {
        expect(dist(p, (-0.5, -0.5)), closeTo(0.5 + 0.14, 1e-9));
      }
    });

    test('a dead end swings round the cap onto the other lane', () {
      final pts = vehiclePathFor(dirIn: 0, dir: 2, lane: 0.14);
      expect(pts.first, (-0.5, 0.14));
      expect(pts.last.$1, closeTo(-0.5, 1e-9));
      expect(pts.last.$2, closeTo(-0.14, 1e-9));
      // The swing bulges past the turnaround point but stays on the tile.
      final maxCol = pts.map((p) => p.$1).reduce(math.max);
      expect(maxCol, greaterThan(0.2));
      expect(maxCol, lessThan(0.5));
    });

    test('consecutive legs are short, so headings change gradually', () {
      final pts = vehiclePathFor(dirIn: 1, dir: 2, lane: 0.14);
      for (var i = 1; i < pts.length; i++) {
        expect(dist(pts[i - 1], pts[i]), lessThan(0.15));
      }
    });
  });

  group('stepVehicle', () {
    test('crosses onto the next tile and keeps its entry heading', () {
      final v = Vehicle(col: 0, row: 0, dir: 0, speed: 1, kind: 'hatchback');
      stepVehicle(v, 1.2, isRoad: isRoad, random: math.Random(3));
      expect((v.col, v.row), (1, 0));
      expect(v.dirIn, 0);
      expect(v.t, closeTo(0.2, 1e-9));
    });

    test('a bend shows all three headings in order', () {
      // Arrive at (2,0) heading east and turn south: headings 0 → 1 → 2.
      final v = Vehicle(
        col: 2,
        row: 0,
        dir: 1,
        dirIn: 0,
        speed: 0.05,
        kind: 'hatchback',
      );
      final seen = <int>[v.heading];
      for (var i = 0; i < 300 && (v.col, v.row) == (2, 0); i++) {
        stepVehicle(v, 0.1, isRoad: isRoad, random: math.Random(1));
        if (v.heading != seen.last) seen.add(v.heading);
      }
      expect(seen.take(3), [0, 1, 2]);
    });

    test('a heading change starts a cross-fade from the old heading', () {
      final v = Vehicle(
        col: 2,
        row: 0,
        dir: 1,
        dirIn: 0,
        speed: 0.05,
        kind: 'hatchback',
      );
      while (v.heading == 0) {
        stepVehicle(v, 0.05, isRoad: isRoad, random: math.Random(1));
      }
      expect(v.prevHeading, 0);
      expect(v.fade, 0);
      stepVehicle(v, 0.05, isRoad: isRoad, random: math.Random(1));
      expect(v.fade, closeTo(0.05, 1e-9));
    });

    test('never leaves the road', () {
      final random = math.Random(11);
      final v = spawnVehicle(
        roadTiles: ring.toList(),
        isRoad: isRoad,
        random: random,
        kind: 'hatchback',
        speed: 0.7,
      );
      for (var i = 0; i < 2000; i++) {
        stepVehicle(v, 0.05, isRoad: isRoad, random: random);
        expect(isRoad(v.col, v.row), isTrue, reason: 'step $i');
        final pos = vehiclePosition(v);
        expect((pos.col - v.col).abs(), lessThanOrEqualTo(0.5 + 1e-9));
        expect((pos.row - v.row).abs(), lessThanOrEqualTo(0.5 + 1e-9));
      }
    });

    test('holds while blocked, then drives on after the max hold', () {
      final v = Vehicle(col: 0, row: 0, dir: 0, speed: 1, kind: 'hatchback');
      stepVehicle(
        v,
        0.5,
        isRoad: isRoad,
        random: math.Random(1),
        blocked: true,
      );
      expect(v.t, 0);
      for (var i = 0; i < 10; i++) {
        stepVehicle(
          v,
          0.5,
          isRoad: isRoad,
          random: math.Random(1),
          blocked: true,
        );
      }
      expect(v.t, greaterThan(0));
    });
  });

  group('vehicleBlocked', () {
    Vehicle at(double t, {int dir = 0, int col = 0}) => Vehicle(
      col: col,
      row: 0,
      dir: dir,
      speed: 1,
      kind: 'hatchback',
      t: t,
    );

    test('a car just ahead in the same lane blocks', () {
      final me = at(0.2);
      final ahead = at(0.6);
      expect(vehicleBlocked(me, [me, ahead]), isTrue);
      expect(vehicleBlocked(ahead, [me, ahead]), isFalse);
    });

    test('a car far ahead does not block', () {
      final me = at(0.1);
      final ahead = at(0.1, col: 1);
      expect(vehicleBlocked(me, [me, ahead]), isFalse);
    });

    test('oncoming traffic on the other lane never blocks', () {
      final me = at(0.2);
      final oncoming = Vehicle(
        col: 0,
        row: 0,
        dir: 2,
        speed: 1,
        kind: 'hatchback',
        t: 0.4,
      );
      expect(vehicleBlocked(me, [me, oncoming]), isFalse);
    });
  });
}
