import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/unlock_rule.dart';
import 'package:math_city/domain/city/warning_fix.dart';

BuildingType _b({
  required String id,
  BuildingCategory category = BuildingCategory.housing,
  int pop = 0,
  int cost = 100,
  Map<String, int> service = const {},
}) => BuildingType(
  id: id,
  name: id.replaceAll('_', ' '),
  emoji: '?',
  category: category,
  coinCost: cost,
  unlockRule: UnlockRule.open,
  populationContribution: pop,
  serviceProvision: service,
);

void main() {
  final lopsided = findBeatById('warn_lopsided')!;
  final stalled = findBeatById('warn_growth_stalled')!;
  final home = _b(id: 'single_home', pop: 10, cost: 60);
  final apartment = _b(id: 'apartment', pop: 30, cost: 120);
  final shop = _b(id: 'shop', category: BuildingCategory.commercial);
  final clinic = _b(id: 'clinic', service: const {'clinic': 50}, cost: 120);
  final hospital = _b(
    id: 'hospital',
    service: const {'clinic': 200},
    cost: 1500,
  );
  final plant = _b(id: 'power_plant', service: const {'power': 200});
  final tower = _b(id: 'water_tower', service: const {'water': 150});
  final waste = _b(id: 'waste', service: const {'waste': 150});

  group('no homes!', () {
    test('names the cheapest home and how many close the gap', () {
      final fix = warningFixFor(
        lopsided,
        placed: [home, shop, shop, shop, shop, shop],
        population: 10,
        catalog: [apartment, home, shop],
      );
      expect(fix, isNotNull);
      expect(fix!.building.id, 'single_home');
      // 5 amenities need 3 homes; there is 1.
      expect(fix.story, contains('5 shops and attractions and only 1 home'));
      expect(fix.story, contains('2 more homes'));
    });

    test('is null when the city is not lopsided', () {
      expect(
        warningFixFor(
          lopsided,
          placed: [home, home, shop],
          population: 10,
          catalog: [home],
        ),
        isNull,
      );
    });

    test('is null when no home is in the catalog yet', () {
      expect(
        warningFixFor(
          lopsided,
          placed: [home, shop, shop, shop],
          population: 10,
          catalog: [shop, clinic],
        ),
        isNull,
      );
    });
  });

  group('stuck', () {
    // Homes for 100; power, water and waste each fine; the clinic
    // allowance of 20 pins capacity at 20.
    final placed = [
      apartment,
      apartment,
      apartment,
      apartment,
      plant,
      tower,
      waste,
    ];

    test('names the thinnest service and its cheapest provider', () {
      final fix = warningFixFor(
        stalled,
        placed: placed,
        population: 20,
        catalog: [hospital, clinic, home],
      );
      expect(fix, isNotNull);
      expect(fix!.building.id, 'clinic');
      expect(
        fix.story,
        'Clinic is maxed out: 20 people and room for 20. '
        'A clinic would make room for more.',
      );
    });

    test('falls through to the next provider when the first is gone', () {
      final fix = warningFixFor(
        stalled,
        placed: placed,
        population: 20,
        catalog: [hospital, home],
      );
      expect(fix!.building.id, 'hospital');
    });

    test('is null when nothing provides the thin service yet', () {
      expect(
        warningFixFor(
          stalled,
          placed: placed,
          population: 20,
          catalog: [home, plant],
        ),
        isNull,
      );
    });

    test('is null while the city still has room to grow', () {
      expect(
        warningFixFor(
          stalled,
          placed: placed,
          population: 5,
          catalog: [clinic],
        ),
        isNull,
      );
    });
  });

  test('a demand is never a warning fix', () {
    expect(
      warningFixFor(
        findBeatById('demand_water')!,
        placed: [home, shop, shop, shop],
        population: 10,
        catalog: buildingRegistry,
      ),
      isNull,
    );
  });
}
