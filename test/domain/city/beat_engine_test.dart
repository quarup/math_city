import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/beat_engine.dart';
import 'package:math_city/domain/city/trigger_rule.dart';

void main() {
  const engine = BeatEngine();

  TriggerContext ctx({
    Set<String> placed = const <String>{},
    int population = 0,
    Map<String, int> ages = const <String, int>{},
    Set<String> fired = const <String>{},
    int? coinsSince,
  }) => TriggerContext(
    placedBuildingTypeIds: placed,
    population: population,
    maxBuildingAgeByTypeId: ages,
    firedBeatIds: fired,
    coinsEarnedSinceBeatLastFired: coinsSince,
  );

  Set<String> eligibleIds(TriggerContext context) =>
      engine.eligibleBeats(contextFor: (_) => context).map((b) => b.id).toSet();

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

  test('a service demand fires with residents and clears once built', () {
    final withResidents = ctx(placed: {'mayors_office', 'single_home'});
    expect(eligibleIds(withResidents), contains('demand_clinic'));

    final withClinic = ctx(placed: {'mayors_office', 'single_home', 'clinic'});
    expect(eligibleIds(withClinic), isNot(contains('demand_clinic')));
  });

  test(
    'the trash warning waits for the city to grow, then clears on build',
    () {
      // Residents but small — not yet bad enough.
      expect(
        eligibleIds(ctx(placed: {'single_home'}, population: 5)),
        isNot(contains('demand_waste')),
      );
      // Grown past the minPopulation threshold.
      expect(
        eligibleIds(ctx(placed: {'single_home'}, population: 12)),
        contains('demand_waste'),
      );
      // Cleared once waste management exists, even at higher population.
      expect(
        eligibleIds(
          ctx(placed: {'single_home', 'waste_management'}, population: 30),
        ),
        isNot(contains('demand_waste')),
      );
    },
  );

  test('a recurring demand first-fires, waits for spacing, then re-fires', () {
    // Never fired (null) -> first fire always allowed.
    expect(
      eligibleIds(ctx(placed: {'single_home'})),
      contains('demand_more_parks'),
    );
    // Within the coin-spacing window (600 ≈ 10 min of study) -> suppressed.
    expect(
      eligibleIds(ctx(placed: {'single_home'}, coinsSince: 400)),
      isNot(contains('demand_more_parks')),
    );
    // Past the spacing window -> re-fires.
    expect(
      eligibleIds(ctx(placed: {'single_home'}, coinsSince: 600)),
      contains('demand_more_parks'),
    );
  });

  test('commercial praise fires once the shop is placed', () {
    expect(
      eligibleIds(ctx(placed: {'single_home', 'grocery'})),
      contains('praise_grocery'),
    );
  });

  test(
    'the milestone beat needs both an aged mayors office and prior praise',
    () {
      // Too young, no prior praise.
      expect(
        eligibleIds(
          ctx(
            placed: {'mayors_office', 'single_home'},
            ages: {'mayors_office': 3},
          ),
        ),
        isNot(contains('praise_established_town')),
      );
      // Old enough, but the home-praise beat hasn't fired yet.
      expect(
        eligibleIds(
          ctx(
            placed: {'mayors_office', 'single_home'},
            ages: {'mayors_office': 12},
          ),
        ),
        isNot(contains('praise_established_town')),
      );
      // Old enough AND the prerequisite beat has fired.
      expect(
        eligibleIds(
          ctx(
            placed: {'mayors_office', 'single_home'},
            ages: {'mayors_office': 12},
            fired: {'praise_first_home'},
          ),
        ),
        contains('praise_established_town'),
      );
    },
  );

  test('a fired beat waits out its cooldown before re-firing', () {
    const engine = BeatEngine();
    TriggerContext ctx(int? since) => TriggerContext(
      placedBuildingTypeIds: const {'mayors_office', 'single_home'},
      population: 0,
      maxBuildingAgeByTypeId: const {},
      firedBeatIds: const {'praise_first_home'},
      coinsEarnedSinceBeatLastFired: since,
    );
    bool eligible(int? since) => engine
        .eligibleBeats(contextFor: (_) => ctx(since))
        .any((b) => b.id == 'praise_first_home');
    expect(eligible(null), isTrue);
    expect(eligible(100), isFalse);
    expect(eligible(600), isTrue);
  });
}
