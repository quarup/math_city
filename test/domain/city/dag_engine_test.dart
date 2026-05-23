import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/dag_engine.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

void main() {
  const engine = BuildingDagEngine();

  group('availableToResearch', () {
    test("a fresh player can only research mayor's office", () {
      final available = engine.availableToResearch(
        const UnlockContext(
          lifetimeBricksEarned: 0,
          population: 0,
          placedBuildingTypeIds: <String>{},
          firedBeatIds: <String>{},
        ),
      );
      expect(available.map((b) => b.id), ['mayors_office']);
    });

    test(
      "after placing the mayor's office, every other building is available",
      () {
        final available = engine.availableToResearch(
          const UnlockContext(
            lifetimeBricksEarned: 0,
            population: 0,
            placedBuildingTypeIds: <String>{'mayors_office'},
            firedBeatIds: <String>{},
          ),
        );
        // All 10 buildings should now be available.
        expect(available, hasLength(10));
      },
    );
  });

  group('notYetResearched', () {
    test('hides buildings already present in alreadyResearched', () {
      final result = engine.notYetResearched(
        const UnlockContext(
          lifetimeBricksEarned: 0,
          population: 0,
          placedBuildingTypeIds: <String>{'mayors_office'},
          firedBeatIds: <String>{},
        ),
        alreadyResearched: <String>{
          'mayors_office',
          'single_home',
          'apartment',
        },
      );
      // 10 available − 3 already researched = 7
      expect(result.length, 7);
      expect(result, isNot(contains('mayors_office')));
      expect(result, isNot(contains('single_home')));
      expect(result, contains('school'));
      expect(result, contains('park'));
    });

    test('returns empty when every available building is researched', () {
      final result = engine.notYetResearched(
        const UnlockContext(
          lifetimeBricksEarned: 0,
          population: 0,
          placedBuildingTypeIds: <String>{},
          firedBeatIds: <String>{},
        ),
        alreadyResearched: <String>{'mayors_office'},
      );
      expect(result, isEmpty);
    });
  });
}
