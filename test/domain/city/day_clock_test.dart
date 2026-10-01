import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/day_clock.dart';

void main() {
  group('formatHour', () {
    test('reads as a 12-hour clock', () {
      expect(formatHour(9.5), '9:30 am');
      expect(formatHour(0), '12:00 am');
      expect(formatHour(12), '12:00 pm');
      expect(formatHour(18.08), '6:04 pm');
      expect(formatHour(24.25), '12:15 am');
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
