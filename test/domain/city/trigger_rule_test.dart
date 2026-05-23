import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/trigger_rule.dart';

TriggerContext _ctx({
  Set<String> placed = const <String>{},
  int population = 0,
  Map<String, int> ages = const <String, int>{},
  Set<String> fired = const <String>{},
  int? bricksSince,
}) => TriggerContext(
  placedBuildingTypeIds: placed,
  population: population,
  maxBuildingAgeByTypeId: ages,
  firedBeatIds: fired,
  bricksEarnedSinceBeatLastFired: bricksSince,
);

void main() {
  group('TriggerRule.open', () {
    test('always evaluates true', () {
      expect(TriggerRule.open.evaluate(_ctx()), isTrue);
    });
  });

  group('buildingsPresent / buildingsAbsent', () {
    test('present required, absent forbidden — both honored', () {
      const rule = TriggerRule(
        buildingsPresent: <String>{'mayors_office'},
        buildingsAbsent: <String>{'apartment'},
      );
      expect(
        rule.evaluate(_ctx(placed: <String>{'mayors_office'})),
        isTrue,
      );
      expect(
        rule.evaluate(
          _ctx(placed: <String>{'mayors_office', 'apartment'}),
        ),
        isFalse,
      );
      expect(rule.evaluate(_ctx(placed: <String>{})), isFalse);
    });
  });

  group('minPopulation', () {
    test('honored', () {
      const rule = TriggerRule(minPopulation: 50);
      expect(rule.evaluate(_ctx(population: 49)), isFalse);
      expect(rule.evaluate(_ctx(population: 50)), isTrue);
    });
  });

  group('minBuildingAgeForId', () {
    const rule = TriggerRule(
      minBuildingAgeForId: (buildingTypeId: 'grocery', minRounds: 5),
    );

    test('blocks when building is younger than minRounds', () {
      expect(
        rule.evaluate(_ctx(ages: <String, int>{'grocery': 3})),
        isFalse,
      );
    });

    test('blocks when building absent (treated as age 0)', () {
      expect(rule.evaluate(_ctx()), isFalse);
    });

    test('passes when building is old enough', () {
      expect(
        rule.evaluate(_ctx(ages: <String, int>{'grocery': 5})),
        isTrue,
      );
    });
  });

  group('minBricksEarnedSinceLastBeat', () {
    const rule = TriggerRule(minBricksEarnedSinceLastBeat: 50);

    test('first-fire (null) is always allowed', () {
      expect(rule.evaluate(_ctx()), isTrue);
    });

    test('blocks if not enough bricks earned since last fire', () {
      expect(rule.evaluate(_ctx(bricksSince: 40)), isFalse);
    });

    test('passes once enough bricks have been earned', () {
      expect(rule.evaluate(_ctx(bricksSince: 50)), isTrue);
    });
  });
}
