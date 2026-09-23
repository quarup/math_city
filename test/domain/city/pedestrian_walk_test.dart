import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/pedestrian_walk.dart';

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

  const look = CitizenLook(shirt: 1, pants: 2, skin: 3, hair: 4);

  group('pickDirection', () {
    test('never reverses when another road neighbour exists', () {
      final random = math.Random(1);
      for (var i = 0; i < 200; i++) {
        // Arriving at (2,1) heading south (from (2,0)): options are south to
        // (2,2) or east to (3,1); never north.
        final d = pickDirection(
          isRoad: isRoad,
          col: 2,
          row: 1,
          dir: 1,
          random: random,
        );
        expect(d, isNot(3));
        expect([1, 0], contains(d));
      }
    });

    test('turns around at a dead end', () {
      final d = pickDirection(
        isRoad: isRoad,
        col: 4,
        row: 1,
        dir: 0,
        random: math.Random(1),
      );
      expect(d, 2);
    });

    test('prefers straight ahead with the bias', () {
      final random = math.Random(7);
      var straight = 0;
      for (var i = 0; i < 1000; i++) {
        // At (1,0) heading east: straight (2,0) or nothing else non-reverse.
        // Use (2,1) heading south instead so there is a real choice.
        if (pickDirection(
              isRoad: isRoad,
              col: 2,
              row: 1,
              dir: 1,
              random: random,
            ) ==
            1) {
          straight++;
        }
      }
      // 0.6 straight + 0.4 × ½ from the uniform fallback ≈ 0.8.
      expect(straight, inInclusiveRange(700, 900));
    });
  });

  group('stepPedestrian', () {
    test('advances t, crosses tiles and stays on road', () {
      final p = Pedestrian(
        col: 0,
        row: 0,
        dir: 0,
        speed: 1,
        lane: 14.5,
        look: look,
      );
      final random = math.Random(3);
      for (var i = 0; i < 400; i++) {
        stepPedestrian(
          p,
          0.05,
          isRoad: isRoad,
          random: random,
          pauseChancePerSecond: 0,
        );
        expect(isRoad(p.col, p.row), isTrue, reason: 'left the road at $i');
        expect(p.t, inInclusiveRange(0, 1));
      }
      expect(p.phase, greaterThan(0));
    });

    test('a waiting pedestrian only counts down and keeps its phase', () {
      final p = Pedestrian(
        col: 0,
        row: 0,
        dir: 0,
        speed: 1,
        lane: 14.5,
        look: look,
        wait: 1,
        phase: 2,
      );
      stepPedestrian(p, 0.4, isRoad: isRoad, random: math.Random(1));
      expect(p.wait, closeTo(0.6, 1e-9));
      expect(p.t, 0);
      expect(p.phase, 2);
      stepPedestrian(p, 1, isRoad: isRoad, random: math.Random(1));
      expect(p.wait, 0);
    });

    test('pauses start at the configured rate', () {
      final p = Pedestrian(
        col: 0,
        row: 0,
        dir: 0,
        speed: 0.1,
        lane: 14.5,
        look: look,
      );
      // Certain pause per second: one 1-second step must start a pause.
      stepPedestrian(
        p,
        1,
        isRoad: isRoad,
        random: math.Random(1),
        pauseChancePerSecond: 1,
      );
      expect(p.isWaiting, isTrue);
      expect(p.wait, inInclusiveRange(1.5, 3.5));
    });

    test(
      'crossing the exit edge lands on the next tile, entering straight',
      () {
        final p = Pedestrian(
          col: 0,
          row: 0,
          dir: 0,
          speed: 1,
          lane: 0.4,
          look: look,
          t: 0.9,
        );
        stepPedestrian(
          p,
          0.2,
          isRoad: isRoad,
          random: math.Random(1),
          pauseChancePerSecond: 0,
        );
        expect((p.col, p.row), (1, 0));
        expect(p.dirIn, 0);
        expect(p.t, greaterThan(0));
        expect(p.t, lessThan(0.2));
      },
    );
  });

  group('pedestrianPath', () {
    Pedestrian at(int dirIn, int dir, {double lane = 0.4, double t = 0}) =>
        Pedestrian(
          col: 5,
          row: 5,
          dir: dir,
          dirIn: dirIn,
          speed: 1,
          lane: lane,
          look: look,
          t: t,
        );

    test('straight: one leg from entry edge to exit edge on the lane', () {
      final pts = pedestrianPath(at(0, 0));
      expect(pts, [(-0.5, 0.4), (0.5, 0.4)]);
      expect(pedestrianPathLength(at(0, 0)), closeTo(1, 1e-9));
    });

    test('turn toward the lane side hugs the inner kerb', () {
      // Enter heading east (from the west edge), leave south: the road is
      // west + south, its inner corner the tile's south-west corner
      // (-0.5, 0.5). Lane is on the walker's right (south), so the corner
      // point sits 0.1 in from that corner — inside the sidewalk triangle.
      final pts = pedestrianPath(at(0, 1));
      expect(pts.length, 3);
      final (cc, cr) = pts[1];
      expect(cc, closeTo(-0.4, 1e-9));
      expect(cr, closeTo(0.4, 1e-9));
      expect(pedestrianPathLength(at(0, 1)), closeTo(0.2, 1e-9));
    });

    test('turn away from the lane side sweeps the outer sidewalk', () {
      // Enter heading east, leave north: road west + north, inner corner
      // (-0.5, -0.5). Lane on the right (south) is the outer side.
      final pts = pedestrianPath(at(0, 3));
      final (cc, cr) = pts[1];
      expect(cc, closeTo(0.4, 1e-9));
      expect(cr, closeTo(0.4, 1e-9));
      expect(pedestrianPathLength(at(0, 3)), closeTo(1.8, 1e-9));
      // The whole path stays outside the asphalt arc (radius < 0.8 about
      // the inner corner).
      for (final (c, r) in pts) {
        final d = math.sqrt(math.pow(c + 0.5, 2) + math.pow(r + 0.5, 2));
        expect(d, greaterThan(0.8));
      }
    });

    test('dead end: goes past the centre and around the cap', () {
      // Enter heading east, leave west. Cap centre ~(-0.15, 0), radius 0.3.
      final pts = pedestrianPath(at(0, 2));
      expect(pts.length, 4);
      expect(pts[1], (-0.38, 0.4));
      expect(pts[2], (-0.38, -0.4));
      for (final (c, r) in pts.sublist(1, 3)) {
        final d = math.sqrt(math.pow(c + 0.15, 2) + r * r);
        expect(d, greaterThan(0.3));
      }
    });

    test("position walks the legs in order with each leg's heading", () {
      final p = at(0, 1);
      var pos = pedestrianPosition(p..t = 0.25);
      expect(pos.heading, 0);
      expect(pos.col, closeTo(4.55, 1e-9));
      expect(pos.row, closeTo(5.4, 1e-9));
      pos = pedestrianPosition(p..t = 0.75);
      expect(pos.heading, 1);
      expect(pos.col, closeTo(4.6, 1e-9));
      expect(pos.row, closeTo(5.45, 1e-9));
      expect(pedestrianDepth(p), closeTo(4.6 + 5.45, 1e-9));
    });
  });

  group('spawnPedestrian', () {
    test('lands on a road tile heading along a road', () {
      final tiles = ring.toList();
      final random = math.Random(11);
      for (var i = 0; i < 50; i++) {
        final p = spawnPedestrian(
          roadTiles: tiles,
          isRoad: isRoad,
          random: random,
          look: look,
          speed: 0.16,
          lane: -14.5,
        );
        expect(isRoad(p.col, p.row), isTrue);
        final (dc, dr) = pedestrianDirDeltas[p.dir];
        expect(isRoad(p.col + dc, p.row + dr), isTrue);
        expect(p.t, inInclusiveRange(0, 1));
      }
    });
  });
}
