import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/game/spin_wheel/spin_plan.dart';

void main() {
  const turn = 2 * math.pi;

  double turns(SpinPlan p) => spinTravel(p.velocity, p.decay) / turn;

  group('planSpin', () {
    test('a strong throw spins as thrown, on normal friction', () {
      final p = planSpin(20, extraTurns: 0.7);
      expect(p.velocity, 20);
      expect(p.decay, kSpinDecay);
    });

    test('a gentle throw goes at least 1.5 turns plus the extra', () {
      for (final extra in [0.0, 0.25, 0.5, 0.99]) {
        for (final v in [4.0, 6.0, 10.0, -5.0]) {
          final p = planSpin(v, extraTurns: extra);
          expect(turns(p), closeTo(kMinSpinTurns + extra, 1e-9));
          expect(p.velocity.sign, v.sign, reason: 'keeps its direction');
        }
      }
    });

    test('lubricates first: the speed only rises below the friction floor', () {
      // 10 rad/s needs decay ≈ 1.05 for 1.5 turns: slower spin, same speed.
      final p = planSpin(10, extraTurns: 0);
      expect(p.velocity, 10);
      expect(p.decay, lessThan(kSpinDecay));
      // 4 rad/s would need decay ≈ 0.42: floored, speed raised to match.
      final q = planSpin(4, extraTurns: 0);
      expect(q.decay, kMinSpinDecay);
      expect(q.velocity, greaterThan(4));
    });

    test('a gentle throw stops within ~7 s even with the full extra', () {
      final p = planSpin(4, extraTurns: 0.999);
      final seconds = math.log(p.velocity.abs() / kSpinStopVelocity) / p.decay;
      expect(seconds, lessThan(7));
    });

    test('the same gentle throw lands anywhere: the extra spreads it', () {
      // Landing angle mod one turn, over the extra's range, covers the
      // whole wheel — so the start position can't choose the slice.
      final landings = [
        for (var i = 0; i < 8; i++)
          (spinTravel(
                    planSpin(5, extraTurns: i / 8).velocity,
                    planSpin(5, extraTurns: i / 8).decay,
                  ) %
                  turn) /
              turn,
      ];
      for (var i = 0; i < 8; i++) {
        expect(landings[i], closeTo((0.5 + i / 8) % 1, 1e-9));
      }
    });
  });
}
