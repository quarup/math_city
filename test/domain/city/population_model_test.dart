import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/population_model.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

/// Minimal synthetic building so each test controls exactly the fields the
/// model reads, independent of the real registry's tuning.
BuildingType _b({
  String id = 'x',
  BuildingCategory category = BuildingCategory.civicHousing,
  int pop = 0,
  Map<String, int> service = const {},
  bool variety = false,
}) => BuildingType(
  id: id,
  name: id,
  emoji: '?',
  category: category,
  brickCost: 0,
  researchCost: 0,
  unlockRule: UnlockRule.open,
  populationContribution: pop,
  serviceProvision: service,
  varietyContribution: variety,
);

void main() {
  group('populationCapacity', () {
    test('empty city supports nobody', () {
      expect(populationCapacity(const []), 0);
    });

    test('a city with amenities but no housing still supports nobody', () {
      final placed = [
        _b(id: 'grocery', category: BuildingCategory.commercial, variety: true),
        _b(id: 'park', category: BuildingCategory.entertainment, variety: true),
      ];
      expect(populationCapacity(placed), 0);
    });

    test('housing below the free allowance is fully supported', () {
      // 4 residents, well under serviceFreeAllowance, no services, no variety.
      expect(populationCapacity([_b(id: 'home', pop: 4)]), 4);
    });

    test('housing above the free allowance stalls at it without services', () {
      // 100 housing but no gating services -> capped at serviceFreeAllowance.
      expect(
        populationCapacity([_b(id: 'tower', pop: 100)]),
        serviceFreeAllowance,
      );
    });

    test('a single gating service is not enough — the others still cap', () {
      // Power alone lifts power's ceiling, but clinic & waste stay at the
      // free allowance, so the min still binds at serviceFreeAllowance.
      final placed = [
        _b(id: 'tower', pop: 100),
        _b(
          id: 'power_plant',
          category: BuildingCategory.services,
          service: {'power': 200},
        ),
      ];
      expect(populationCapacity(placed), serviceFreeAllowance);
    });

    test('all gating services present lift the cap to the thinnest one', () {
      // power: 20+200=220, clinic: 20+50=70, waste: 20+150=170 -> min 70.
      final placed = [
        _b(id: 'tower', pop: 100),
        _b(
          id: 'power_plant',
          category: BuildingCategory.services,
          service: {'power': 200},
        ),
        _b(
          id: 'clinic',
          category: BuildingCategory.services,
          service: {'clinic': 50},
        ),
        _b(
          id: 'waste',
          category: BuildingCategory.services,
          service: {'waste': 150},
        ),
      ];
      expect(populationCapacity(placed), 70);
    });

    test('doubling the thinnest service raises the ceiling', () {
      // Two clinics: clinic ceiling 20+100=120; housing 100 now binds.
      final placed = [
        _b(id: 'tower', pop: 100),
        _b(
          id: 'power_plant',
          category: BuildingCategory.services,
          service: {'power': 200},
        ),
        _b(
          id: 'clinic',
          category: BuildingCategory.services,
          service: {'clinic': 50},
        ),
        _b(
          id: 'clinic',
          category: BuildingCategory.services,
          service: {'clinic': 50},
        ),
        _b(
          id: 'waste',
          category: BuildingCategory.services,
          service: {'waste': 150},
        ),
      ];
      expect(populationCapacity(placed), 100);
    });

    test('school is not a gating service, so it does not cap growth', () {
      // Homes (16) under the allowance; a school provides only the soft
      // `school` service, which is outside gatingServiceIds.
      final placed = [
        _b(id: 'apt', pop: 16),
        _b(id: 'school', service: {'school': 60}),
      ];
      expect(populationCapacity(placed), 16);
    });

    test('variety types apply a desirability bonus', () {
      // 3 distinct variety services, housing 100 fully serviced -> base 100,
      // multiplier 1 + 0.05*3 = 1.15 -> round(115) = 115.
      final placed = [
        _b(id: 'tower', pop: 100),
        _b(
          id: 'power_plant',
          category: BuildingCategory.services,
          service: {'power': 1000},
          variety: true,
        ),
        _b(
          id: 'clinic',
          category: BuildingCategory.services,
          service: {'clinic': 1000},
          variety: true,
        ),
        _b(
          id: 'waste',
          category: BuildingCategory.services,
          service: {'waste': 1000},
          variety: true,
        ),
      ];
      expect(populationCapacity(placed), 115);
    });

    test('repeated variety types only count once toward the bonus', () {
      final twoGroceries = [
        _b(id: 'home', pop: 10),
        _b(id: 'grocery', category: BuildingCategory.commercial, variety: true),
        _b(id: 'grocery', category: BuildingCategory.commercial, variety: true),
      ];
      // base 10, 1 distinct variety type -> *1.05 -> round(10.5) = 11.
      // (amenityCount 2 == 2*housingCount 1, not strictly greater, so no
      // lopsidedness penalty.)
      expect(populationCapacity(twoGroceries), 11);
    });

    test('the variety multiplier is capped', () {
      // 20 distinct variety service types would be 1 + 0.05*20 = 2.0 uncapped;
      // expect it pinned to maxVarietyMultiplier (1.5).
      final placed = <BuildingType>[
        _b(id: 'tower', pop: 100),
        // saturate the gating services so base stays 100
        _b(
          id: 'power_plant',
          category: BuildingCategory.services,
          service: {'power': 1000},
        ),
        _b(
          id: 'clinic',
          category: BuildingCategory.services,
          service: {'clinic': 1000},
        ),
        _b(
          id: 'waste',
          category: BuildingCategory.services,
          service: {'waste': 1000},
        ),
        for (var i = 0; i < 20; i++)
          _b(
            id: 'shop$i',
            category: BuildingCategory.commercial,
            variety: true,
          ),
      ];
      // base 100; but 20 amenities vs 1 housing -> lopsided -> *0.8.
      // multiplier capped 1.5 * 0.8 = 1.2 -> round(120) = 120.
      expect(populationCapacity(placed), 120);
    });

    test('a lopsided city (amenities >> housing) is penalised', () {
      // 1 home + 3 amenities: amenityCount 3 > 2*1 -> lopsided.
      // base = min(housing 100? no, home pop 100) ... keep services saturated.
      final lopsided = [
        _b(id: 'tower', pop: 100),
        _b(
          id: 'power_plant',
          category: BuildingCategory.services,
          service: {'power': 1000},
        ),
        _b(
          id: 'clinic',
          category: BuildingCategory.services,
          service: {'clinic': 1000},
        ),
        _b(
          id: 'waste',
          category: BuildingCategory.services,
          service: {'waste': 1000},
        ),
        _b(id: 'grocery', category: BuildingCategory.commercial, variety: true),
        _b(id: 'cafe', category: BuildingCategory.commercial, variety: true),
        _b(id: 'park', category: BuildingCategory.entertainment, variety: true),
      ];
      // base 100, variety 3 -> 1.15, lopsided *0.8 = 0.92 -> round(92) = 92.
      expect(populationCapacity(lopsided), 92);
    });
  });

  group('stepPopulation', () {
    test('holds at capacity', () {
      expect(stepPopulation(50, 50), 50);
    });

    test('grows toward capacity by the rounded-up gap fraction', () {
      // gap 100, rate 0.25 -> +25.
      expect(stepPopulation(0, 100), 25);
    });

    test('reaches capacity exactly without overshooting', () {
      // gap 1 -> ceil(0.25) = 1 -> lands on 100.
      expect(stepPopulation(99, 100), 100);
    });

    test('shrinks toward capacity when over', () {
      // over by 100, rate 0.25 -> -25.
      expect(stepPopulation(100, 0), 75);
    });

    test('shrink lands on capacity exactly', () {
      expect(stepPopulation(1, 0), 0);
    });

    test('converges to capacity in a finite number of ticks (growth)', () {
      var pop = 0;
      for (var i = 0; i < 100 && pop != 137; i++) {
        pop = stepPopulation(pop, 137);
      }
      expect(pop, 137);
    });

    test('converges to capacity in a finite number of ticks (decline)', () {
      var pop = 500;
      for (var i = 0; i < 100 && pop != 12; i++) {
        pop = stepPopulation(pop, 12);
      }
      expect(pop, 12);
    });

    test('a custom rate closes more of the gap', () {
      // gap 100, rate 0.5 -> +50.
      expect(stepPopulation(0, 100, rate: 0.5), 50);
    });
  });
}
