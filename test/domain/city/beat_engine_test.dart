import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/beat_engine.dart';
import 'package:math_city/domain/city/trigger_rule.dart';

void main() {
  const engine = BeatEngine();

  TriggerContext ctx({
    Set<String> placed = const <String>{},
  }) => TriggerContext(
    placedBuildingTypeIds: placed,
    population: 0,
    maxBuildingAgeByTypeId: const <String, int>{},
    firedBeatIds: const <String>{},
    bricksEarnedSinceBeatLastFired: null,
  );

  test("with only mayor's office, demand_first_home is eligible", () {
    final eligible = engine.eligibleBeats(
      contextFor: (_) => ctx(placed: <String>{'mayors_office'}),
    );
    final ids = eligible.map((b) => b.id).toSet();
    expect(ids, contains('demand_first_home'));
    expect(ids, isNot(contains('praise_first_home')));
  });

  test('after placing a home, demand fades and praise fires', () {
    final eligible = engine.eligibleBeats(
      contextFor: (_) => ctx(placed: <String>{'mayors_office', 'single_home'}),
    );
    final ids = eligible.map((b) => b.id).toSet();
    expect(ids, isNot(contains('demand_first_home')));
    expect(ids, contains('praise_first_home'));
  });

  test("empty city yields no beats (mayor's office not yet placed)", () {
    final eligible = engine.eligibleBeats(
      contextFor: (_) => ctx(),
    );
    expect(eligible, isEmpty);
  });
}
