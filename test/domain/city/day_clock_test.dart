import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/day_clock.dart';

(int, int, int) _rgb(int c) => ((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF);

void main() {
  group('hazeColorAt', () {
    test('is white by day and near black at midnight', () {
      final (r, g, b) = _rgb(hazeColorAt(12));
      expect(r, greaterThan(225));
      expect(g, greaterThan(225));
      expect(b, greaterThan(225));
      final (nr, ng, nb) = _rgb(hazeColorAt(0));
      expect(nr, lessThan(30));
      expect(ng, lessThan(30));
      expect(nb, lessThan(40));
    });

    test('is never purple before dawn', () {
      for (var h = 0.0; h < 6.5; h += 0.25) {
        final (r, g, b) = _rgb(hazeColorAt(h));
        // Grey or peach: blue never dominates red by much.
        expect(b - r, lessThan(16), reason: 'hour $h');
        // And no magenta: green is never far below both red and blue.
        expect(g, greaterThanOrEqualTo((r < b ? r : b) - 24), reason: '$h');
      }
    });

    test('hits the keys exactly and wraps at 24', () {
      expect(hazeColorAt(13), 0xE8F0F6);
      expect(hazeColorAt(18.5), 0xF3C58F);
      expect(hazeColorAt(24), hazeColorAt(0));
      expect(hazeColorAt(25), hazeColorAt(1));
    });
  });

  group('night and dusk', () {
    test('night strength is 0 by day, 1 at night', () {
      expect(nightStrengthAt(12), 0);
      expect(nightStrengthAt(9.5), 0);
      expect(nightStrengthAt(0), 1);
      expect(nightStrengthAt(22), 1);
      expect(nightStrengthAt(19.25), closeTo(0.525, 1e-9));
    });

    test('dusk warmth peaks at sunset', () {
      expect(duskWarmthAt(18.5), 0.9);
      expect(duskWarmthAt(12), lessThanOrEqualTo(0.12));
    });
  });

  group('advanceHour', () {
    test('five minutes of day run 6:30 to 18:30', () {
      expect(advanceHour(kDayStartHour, kDaySeconds), kNightStartHour);
    });

    test('three minutes of night run 18:30 round to 6:30', () {
      expect(
        advanceHour(kNightStartHour, kNightSeconds),
        closeTo(kDayStartHour, 1e-9),
      );
    });

    test('the whole loop is eight minutes', () {
      expect(
        advanceHour(9.5, kDaySeconds + kNightSeconds),
        closeTo(9.5, 1e-9),
      );
    });

    test('a step across the boundary changes rate mid-step', () {
      // 25 s of day before 18:30 (1 h), then 30 s of night (2 h).
      final h = advanceHour(17.5, 55);
      expect(h, closeTo(20.5, 1e-9));
    });
  });

  group('AmbientClock', () {
    test("starts at chapter one's 9:30 and ticks when running", () {
      final clock = AmbientClock();
      expect(clock.hour, kChapterOneHour);
      clock.tick(25);
      expect(clock.hour, closeTo(10.5, 1e-9));
      clock.tick(25);
      expect(clock.hour, closeTo(11.5, 1e-9));
    });

    test('frozen or paused, it does not move', () {
      final clock = AmbientClock()
        ..frozen = true
        ..tick(100);
      expect(clock.hour, kChapterOneHour);
      clock
        ..frozen = false
        ..paused = true
        ..tick(100);
      expect(clock.hour, kChapterOneHour);
      clock
        ..paused = false
        ..tick(25);
      expect(clock.hour, closeTo(10.5, 1e-9));
    });
  });
}
