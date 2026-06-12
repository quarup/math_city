import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/land_expansion.dart';

void main() {
  group('nextLandExpansion', () {
    test('beginner 12×12 → 16×16 at the first rung price, shift (2,2)', () {
      final offer = nextLandExpansion(
        gridWidth: 12,
        gridHeight: 12,
        baseGridWidth: 12,
        baseGridHeight: 12,
      );
      expect(offer, isNotNull);
      expect(offer!.newGridWidth, 16);
      expect(offer.newGridHeight, 16);
      expect(offer.shiftX, kExpansionTilesPerSide);
      expect(offer.shiftY, kExpansionTilesPerSide);
      expect(offer.brickCost, kExpansionBrickCosts[0]);
    });

    test('price climbs the ladder with each expansion bought', () {
      final second = nextLandExpansion(
        gridWidth: 16,
        gridHeight: 16,
        baseGridWidth: 12,
        baseGridHeight: 12,
      );
      expect(second!.newGridWidth, 20);
      expect(second.brickCost, kExpansionBrickCosts[1]);

      final third = nextLandExpansion(
        gridWidth: 20,
        gridHeight: 20,
        baseGridWidth: 12,
        baseGridHeight: 12,
      );
      expect(third!.newGridWidth, 24);
      expect(third.newGridHeight, 24);
      expect(third.brickCost, kExpansionBrickCosts[2]);
    });

    test('no offer at the 24×24 cap', () {
      expect(
        nextLandExpansion(
          gridWidth: kMaxGridSize,
          gridHeight: kMaxGridSize,
          baseGridWidth: 12,
          baseGridHeight: 12,
        ),
        isNull,
      );
    });

    test('an axis at the cap stays put while the other grows', () {
      final offer = nextLandExpansion(
        gridWidth: kMaxGridSize,
        gridHeight: 20,
        baseGridWidth: 12,
        baseGridHeight: 12,
      );
      expect(offer, isNotNull);
      expect(offer!.newGridWidth, kMaxGridSize);
      expect(offer.shiftX, 0);
      expect(offer.newGridHeight, 24);
      expect(offer.shiftY, kExpansionTilesPerSide);
    });

    test('expansions past the price list stay at the last rung', () {
      // A hypothetical bigger base map that allows a 4th expansion.
      final offer = nextLandExpansion(
        gridWidth: 20,
        gridHeight: 20,
        baseGridWidth: 4,
        baseGridHeight: 4,
      );
      expect(offer!.brickCost, kExpansionBrickCosts.last);
    });
  });
}
