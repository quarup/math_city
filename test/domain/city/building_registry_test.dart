import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

void main() {
  group('buildingRegistry', () {
    test('contains exactly 10 entries (Phase 7 catalog)', () {
      expect(buildingRegistry, hasLength(10));
    });

    test('all IDs are unique', () {
      final ids = buildingRegistry.map((b) => b.id).toSet();
      expect(ids.length, buildingRegistry.length);
    });

    test('covers all 4 categories', () {
      final categories = buildingRegistry.map((b) => b.category).toSet();
      expect(categories, BuildingCategory.values.toSet());
    });

    test("mayor's office is free + ungated", () {
      final mayors = findBuildingTypeById('mayors_office');
      expect(mayors, isNotNull);
      expect(mayors!.brickCost, 0);
      expect(mayors.researchCost, 0);
      expect(
        mayors.unlockRule.evaluate(
          const UnlockContext(
            lifetimeBricksEarned: 0,
            population: 0,
            placedBuildingTypeIds: <String>{},
            readBeatIds: <String>{},
          ),
        ),
        isTrue,
      );
    });

    test('single home is free to place but costs 1 research', () {
      final home = findBuildingTypeById('single_home');
      expect(home, isNotNull);
      expect(home!.brickCost, 0);
      expect(home.researchCost, 1);
    });

    test("every non-mayor building requires mayor's office placed", () {
      for (final b in buildingRegistry) {
        if (b.id == 'mayors_office') continue;
        expect(
          b.unlockRule.requiredBuildingsPlaced.contains('mayors_office'),
          isTrue,
          reason: '${b.id} should require mayors_office',
        );
      }
    });

    test("preResearchedBuildings is exactly the mayor's office", () {
      final ids = preResearchedBuildings.map((b) => b.id).toList();
      expect(ids, ['mayors_office']);
    });
  });
}
