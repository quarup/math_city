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
    test('advances t, crosses tile centres and stays on road', () {
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

    test('depth interpolates col + row along the step', () {
      final p = Pedestrian(
        col: 2,
        row: 1,
        dir: 1,
        speed: 1,
        lane: 0,
        look: look,
        t: 0.25,
      );
      expect(p.depth, closeTo(3.25, 1e-9));
      p.dir = 3; // north: depth decreases along the step
      expect(p.depth, closeTo(2.75, 1e-9));
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
