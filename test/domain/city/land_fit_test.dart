import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/land_blocks.dart';
import 'package:math_city/domain/city/land_fit.dart';
import 'package:math_city/domain/city/placement_rules.dart';

/// Every tile of [blocks] covered by 1×1 footprints: no room anywhere.
List<GridFootprint> _packed(Set<(int, int)> blocks) => [
  for (final (c, r) in ownedTilesOf(blocks))
    GridFootprint(col: c, row: r, width: 1, height: 1),
];

void main() {
  final start = startingOwnedBlocks();

  group('blockSetPurchasable', () {
    test('a frontier block alone is purchasable', () {
      expect(blockSetPurchasable(start, {(2, 0)}), isTrue);
    });

    test('a ring-3 block hangs off the group, not the town', () {
      expect(blockSetPurchasable(start, {(3, 0)}), isFalse);
      expect(blockSetPurchasable(start, {(2, 0), (3, 0)}), isTrue);
      expect(blockSetPurchasable(start, {(2, 0), (3, 1)}), isFalse);
    });

    test('owned or empty sets are not', () {
      expect(blockSetPurchasable(start, {(0, 0)}), isFalse);
      expect(blockSetPurchasable(start, const {}), isFalse);
    });
  });

  group('findBlockSetForFootprint', () {
    test('a small footprint in a full town takes one block', () {
      final fit = findBlockSetForFootprint(
        ownedBlocks: start,
        existing: _packed(start),
        width: 2,
        height: 2,
      );
      expect(fit, isNotNull);
      expect(fit!.blocks.length, 1);
      expect(fit.price, 600);
      final block = fit.blocks.single;
      expect(blockRing(block.$1, block.$2), 2);
      // The building stands on the new block.
      expect(
        fit.footprint.tiles().every(ownedTilesOf(fit.blocks).contains),
        isTrue,
      );
    });

    test('a 6×6 needs a group, and the group may reach ring 3', () {
      // One owned block, nothing built: a 6×6 needs an 8×8 of blocks, so
      // three more around the corner of the owned one.
      final fit = findBlockSetForFootprint(
        ownedBlocks: {(0, 0)},
        existing: const [],
        width: 6,
        height: 6,
      );
      expect(fit, isNotNull);
      expect(fit!.blocks.length, 3);
      expect(fit.price, 1800);
      expect(blockSetPurchasable({(0, 0)}, fit.blocks), isTrue);
      final land = ownedTilesOf({(0, 0), ...fit.blocks});
      expect(fit.footprint.tiles().every(land.contains), isTrue);
    });

    test('cheapest total first', () {
      // Owned land stretched east so that a ring-3 block is the only
      // single block with room beside it: the search still prefers the
      // cheaper ring-2 single block when one works.
      final owned = {...start, (2, 0)};
      final fit = findBlockSetForFootprint(
        ownedBlocks: owned,
        existing: _packed(owned),
        width: 1,
        height: 1,
      );
      expect(fit, isNotNull);
      expect(fit!.price, 600);
    });

    test('nearest to town on ties', () {
      final fit = findBlockSetForFootprint(
        ownedBlocks: {(0, 0)},
        existing: _packed({(0, 0)}),
        width: 1,
        height: 1,
      );
      // All four ring-1 neighbours tie on price and distance; the
      // lowest-ordered wins, deterministically.
      expect(fit!.blocks.single, (-1, 0));
      expect(
        findBlockSetForFootprint(
          ownedBlocks: {(0, 0)},
          existing: _packed({(0, 0)}),
          width: 1,
          height: 1,
        )!.blocks.single,
        (-1, 0),
      );
    });

    test('reserved tiles are kept clear', () {
      final street = {for (var c = -20; c < 20; c++) (c, 0)};
      final fit = findBlockSetForFootprint(
        ownedBlocks: start,
        existing: _packed(start),
        width: 4,
        height: 4,
        reserved: street,
      );
      expect(fit, isNotNull);
      expect(fit!.footprint.tiles().any(street.contains), isFalse);
    });

    test('gives up past maxBlocks', () {
      expect(
        findBlockSetForFootprint(
          ownedBlocks: {(0, 0)},
          existing: const [],
          width: 12,
          height: 12,
        ),
        isNull,
      );
    });
  });
}
