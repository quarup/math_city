import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/window_lights.dart';

/// How many of [count] windows of building [seed] are lit at [hour].
int _lit(int seed, LightProfile profile, double hour, {int count = 40}) {
  var n = 0;
  for (var i = 0; i < count; i++) {
    final hours = windowHoursFor(seed: seed, index: i, profile: profile);
    if (windowLightAt(hour, hours) > 0.5) n++;
  }
  return n;
}

void main() {
  group('lightProfileFor', () {
    test('homes, shops, offices, staffed services and venues', () {
      LightProfile of(String id, BuildingCategory c) =>
          lightProfileFor(typeId: id, category: c);
      expect(
        of('single_home', BuildingCategory.housing),
        LightProfile.home,
      );
      expect(of('high_rise', BuildingCategory.housing), LightProfile.home);
      expect(
        of('mayors_office', BuildingCategory.housing),
        LightProfile.office,
      );
      expect(of('school', BuildingCategory.services), LightProfile.office);
      expect(of('hospital', BuildingCategory.services), LightProfile.civic);
      expect(of('bakery', BuildingCategory.commercial), LightProfile.shop);
      expect(
        of('business_tower', BuildingCategory.commercial),
        LightProfile.office,
      );
      expect(
        of('movie_theater', BuildingCategory.entertainment),
        LightProfile.venue,
      );
    });
  });

  group('no window is lit in the middle of the night', () {
    test('every profile, many buildings, midnight to 5:30', () {
      for (final profile in LightProfile.values) {
        for (var seed = 1; seed <= 60; seed++) {
          for (var i = 0; i < 30; i++) {
            final hours = windowHoursFor(
              seed: seed,
              index: i,
              profile: profile,
            );
            for (final h in [0.0, 0.5, 2.0, 3.75, 5.0, 5.49]) {
              expect(
                windowLightAt(h, hours),
                0,
                reason: '$profile seed $seed window $i at $h',
              );
            }
            expect(hours.eveningOff, lessThan(24));
          }
        }
      }
    });
  });

  group('signs and lamps burn from dusk until dawn', () {
    WindowHours glow(int seed, int i, LightProfile profile) =>
        windowHoursFor(seed: seed, index: i, profile: profile, glow: true);

    test('lit all through the night, whatever the building', () {
      for (final profile in LightProfile.values) {
        for (var seed = 1; seed <= 20; seed++) {
          for (var i = 0; i < 8; i++) {
            final hours = glow(seed, i, profile);
            expect(hours.allNight, isTrue);
            for (final h in [18.0, 21.0, 23.9, 0.0, 2.0, 5.0, 6.0]) {
              expect(
                windowLightAt(h, hours),
                1,
                reason: '$profile seed $seed glow $i at $h',
              );
            }
          }
        }
      }
    });

    test('dark by day', () {
      final hours = glow(3, 0, LightProfile.shop);
      for (final h in [7.0, 9.5, 12.0, 16.0]) {
        expect(windowLightAt(h, hours), 0, reason: 'at $h');
      }
    });

    test("a building's signs come on within minutes of each other", () {
      final ons = [
        for (var i = 0; i < 10; i++) glow(4, i, LightProfile.shop).eveningOn,
      ];
      final spread =
          ons.reduce((a, b) => a > b ? a : b) -
          ons.reduce((a, b) => a < b ? a : b);
      expect(spread, lessThan(0.11));
      expect(ons.every((on) => on >= 16.9 && on <= 17.4), isTrue);
    });

    test('they fade in at dusk and out at dawn', () {
      final hours = glow(5, 2, LightProfile.home);
      expect(
        windowLightAt(hours.eveningOn + kWindowFadeHours / 2, hours),
        closeTo(0.5, 1e-9),
      );
      expect(
        windowLightAt(hours.morningOff! - kWindowFadeHours / 2, hours),
        closeTo(0.5, 1e-9),
      );
      expect(windowLightAt(hours.morningOff! + 0.01, hours), 0);
      expect(hours.morningOff, inInclusiveRange(6.3, 6.7));
    });
  });

  group('evenings', () {
    test('lights are on in the evening for every profile', () {
      for (final profile in LightProfile.values) {
        expect(_lit(7, profile, 19.5), greaterThan(15), reason: '$profile');
      }
    });

    test('daytime is dark', () {
      for (final profile in LightProfile.values) {
        expect(_lit(7, profile, 12), 0, reason: '$profile');
        expect(_lit(7, profile, 9.5), 0, reason: '$profile');
      }
    });

    test('a home fills in one window at a time, not all at once', () {
      final counts = [
        for (var h = 17.0; h <= 20.5; h += 0.25) _lit(11, LightProfile.home, h),
      ];
      // Monotone rise over the evening, with many distinct steps.
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThanOrEqualTo(counts[i - 1]));
      }
      expect(counts.toSet().length, greaterThan(6));
      expect(counts.first, lessThan(4));
      // Some flats stay dark all evening.
      expect(counts.last, lessThan(40));
      expect(counts.last, greaterThan(25));
    });

    test('homes go to bed over the night, staggered', () {
      final counts = [
        for (var h = 20.75; h <= 23.75; h += 0.25)
          _lit(11, LightProfile.home, h),
      ];
      expect(counts.first, greaterThan(counts.last));
      expect(counts.last, 0);
      expect(counts.toSet().length, greaterThan(5));
    });

    test('two houses of the same kind do not switch together', () {
      final a = windowHoursFor(seed: 1, index: 0, profile: LightProfile.home);
      final b = windowHoursFor(seed: 2, index: 0, profile: LightProfile.home);
      expect(
        a.eveningOn == b.eveningOn && a.eveningOff == b.eveningOff,
        isFalse,
      );
    });

    test("a shop's windows switch within minutes of each other", () {
      final ons = [
        for (var i = 0; i < 12; i++)
          windowHoursFor(
            seed: 5,
            index: i,
            profile: LightProfile.shop,
          ).eveningOn,
      ];
      final offs = [
        for (var i = 0; i < 12; i++)
          windowHoursFor(
            seed: 5,
            index: i,
            profile: LightProfile.shop,
          ).eveningOff,
      ];
      double spread(List<double> v) =>
          v.reduce((a, b) => a > b ? a : b) - v.reduce((a, b) => a < b ? a : b);
      expect(spread(ons), lessThan(0.2));
      expect(spread(offs), lessThan(0.25));
      // And they are not all identical either.
      expect(ons.toSet().length, greaterThan(6));
    });

    test('offices empty out earlier than homes', () {
      expect(
        _lit(3, LightProfile.office, 22.25),
        0,
      );
      expect(_lit(3, LightProfile.home, 22.25), greaterThan(5));
    });
  });

  group('mornings', () {
    test('a few home windows are lit before dawn, and off again by 8', () {
      final early = _lit(11, LightProfile.home, 6.6);
      expect(early, greaterThan(3));
      expect(early, lessThan(25));
      expect(_lit(11, LightProfile.home, 8), 0);
    });

    test('shops and venues have no morning lights', () {
      expect(_lit(11, LightProfile.shop, 6.6), 0);
      expect(_lit(11, LightProfile.venue, 6.6), 0);
    });
  });

  group('windowLightAt', () {
    const hours = WindowHours(eveningOn: 18, eveningOff: 22);

    test('fades in and out', () {
      expect(windowLightAt(18, hours), 0);
      expect(
        windowLightAt(18 + kWindowFadeHours / 2, hours),
        closeTo(0.5, 1e-9),
      );
      expect(windowLightAt(19, hours), 1);
      expect(
        windowLightAt(22 - kWindowFadeHours / 2, hours),
        closeTo(0.5, 1e-9),
      );
      expect(windowLightAt(22, hours), 0);
    });

    test('a window that never lights stays dark', () {
      expect(WindowHours.never.isNever, isTrue);
      for (var h = 0.0; h < 24; h += 0.5) {
        expect(windowLightAt(h, WindowHours.never), 0);
      }
    });

    test('is deterministic', () {
      final a = windowHoursFor(seed: 9, index: 4, profile: LightProfile.home);
      final b = windowHoursFor(seed: 9, index: 4, profile: LightProfile.home);
      expect(a.eveningOn, b.eveningOn);
      expect(a.eveningOff, b.eveningOff);
      expect(a.morningOn, b.morningOn);
    });
  });
}
