import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

void main() {
  const emptyCtx = UnlockContext(
    lifetimeBricksEarned: 0,
    population: 0,
    placedBuildingTypeIds: <String>{},
    readBeatIds: <String>{},
  );

  group('UnlockRule.open', () {
    test('is always satisfied', () {
      expect(UnlockRule.open.evaluate(emptyCtx), isTrue);
    });
  });

  group('minLifetimeBricks', () {
    const rule = UnlockRule(minLifetimeBricks: 100);

    test('blocks when balance below threshold', () {
      expect(rule.evaluate(emptyCtx), isFalse);
    });

    test('passes at exactly the threshold', () {
      expect(
        rule.evaluate(
          const UnlockContext(
            lifetimeBricksEarned: 100,
            population: 0,
            placedBuildingTypeIds: <String>{},
            readBeatIds: <String>{},
          ),
        ),
        isTrue,
      );
    });
  });

  group('requiredBuildingsPlaced', () {
    const rule = UnlockRule(
      requiredBuildingsPlaced: <String>{'mayors_office', 'single_home'},
    );

    test('blocks when neither building placed', () {
      expect(rule.evaluate(emptyCtx), isFalse);
    });

    test('blocks when only one building placed', () {
      expect(
        rule.evaluate(
          const UnlockContext(
            lifetimeBricksEarned: 0,
            population: 0,
            placedBuildingTypeIds: <String>{'mayors_office'},
            readBeatIds: <String>{},
          ),
        ),
        isFalse,
      );
    });

    test('passes when both placed', () {
      expect(
        rule.evaluate(
          const UnlockContext(
            lifetimeBricksEarned: 0,
            population: 0,
            placedBuildingTypeIds: <String>{
              'mayors_office',
              'single_home',
              'park',
            },
            readBeatIds: <String>{},
          ),
        ),
        isTrue,
      );
    });
  });

  group('minPopulation', () {
    const rule = UnlockRule(minPopulation: 50);

    test('blocks below threshold', () {
      expect(
        rule.evaluate(
          const UnlockContext(
            lifetimeBricksEarned: 0,
            population: 49,
            placedBuildingTypeIds: <String>{},
            readBeatIds: <String>{},
          ),
        ),
        isFalse,
      );
    });

    test('passes at threshold', () {
      expect(
        rule.evaluate(
          const UnlockContext(
            lifetimeBricksEarned: 0,
            population: 50,
            placedBuildingTypeIds: <String>{},
            readBeatIds: <String>{},
          ),
        ),
        isTrue,
      );
    });
  });

  group('requiredBeatsRead', () {
    const rule = UnlockRule(
      requiredBeatsRead: <String>{'demand_first_home'},
    );

    test('blocks when beat has not been read', () {
      expect(rule.evaluate(emptyCtx), isFalse);
    });

    test('passes when beat has been read', () {
      expect(
        rule.evaluate(
          const UnlockContext(
            lifetimeBricksEarned: 0,
            population: 0,
            placedBuildingTypeIds: <String>{},
            readBeatIds: <String>{'demand_first_home'},
          ),
        ),
        isTrue,
      );
    });
  });

  group('AND combination', () {
    const rule = UnlockRule(
      minLifetimeBricks: 100,
      minPopulation: 20,
      requiredBuildingsPlaced: <String>{'mayors_office'},
    );

    test('blocks if any gate fails', () {
      // bricks ok, pop fails
      expect(
        rule.evaluate(
          const UnlockContext(
            lifetimeBricksEarned: 200,
            population: 10,
            placedBuildingTypeIds: <String>{'mayors_office'},
            readBeatIds: <String>{},
          ),
        ),
        isFalse,
      );
      // pop ok, building fails
      expect(
        rule.evaluate(
          const UnlockContext(
            lifetimeBricksEarned: 200,
            population: 100,
            placedBuildingTypeIds: <String>{},
            readBeatIds: <String>{},
          ),
        ),
        isFalse,
      );
    });

    test('passes when all gates pass', () {
      expect(
        rule.evaluate(
          const UnlockContext(
            lifetimeBricksEarned: 200,
            population: 100,
            placedBuildingTypeIds: <String>{'mayors_office'},
            readBeatIds: <String>{},
          ),
        ),
        isTrue,
      );
    });
  });
}
