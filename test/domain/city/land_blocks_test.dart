import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/land_blocks.dart';

void main() {
  group('blockRing', () {
    test('center is ring 0, the ring-1 square is ring 1', () {
      expect(blockRing(0, 0), 0);
      for (final (bx, by) in const [
        (1, 0),
        (0, 1),
        (-1, 0),
        (1, 1),
        (-1, -1),
      ]) {
        expect(blockRing(bx, by), 1, reason: '($bx,$by)');
      }
    });

    test('ring is Chebyshev: a corner counts the same as an edge', () {
      expect(blockRing(2, 0), 2);
      expect(blockRing(2, 2), 2); // corner, not Euclidean √8
      expect(blockRing(-3, 1), 3);
    });
  });

  group('blockCost', () {
    test('linear base × ring', () {
      expect(blockCost(2, 0), 80);
      expect(blockCost(3, 0), 120);
      expect(blockCost(2, 2), 80); // keys off ring, not distance
      expect(blockCost(0, 0), 0);
    });
  });

  group('blockOfTile / tilesOfBlock', () {
    test('round-trips across the origin including negative tiles', () {
      expect(blockOfTile(0, 0), (0, 0));
      expect(blockOfTile(3, 3), (0, 0));
      expect(blockOfTile(4, 0), (1, 0));
      expect(blockOfTile(-1, -1), (-1, -1)); // floored, not truncated
      expect(blockOfTile(-4, -4), (-1, -1));
      expect(blockOfTile(-5, 0), (-2, 0));
    });

    test('tilesOfBlock yields the 4×4 tiles, and every tile maps back', () {
      for (final (bx, by) in const [(0, 0), (-1, 2), (3, -1)]) {
        final tiles = tilesOfBlock(bx, by).toList();
        expect(tiles.length, 16);
        for (final (c, r) in tiles) {
          expect(blockOfTile(c, r), (bx, by));
        }
      }
    });
  });

  group('startingOwnedBlocks / ownedTilesOf', () {
    test('the start is the 3×3 rings-0-1 blocks = 144 tiles', () {
      final blocks = startingOwnedBlocks();
      expect(blocks.length, 9);
      expect(blocks.every((b) => blockRing(b.$1, b.$2) <= 1), isTrue);

      final tiles = ownedTilesOf(blocks);
      expect(tiles.length, 144); // 12×12
      // Spans world tiles [-4, 8) on each axis.
      expect(tiles.contains((-4, -4)), isTrue);
      expect(tiles.contains((7, 7)), isTrue);
      expect(tiles.contains((8, 0)), isFalse);
    });
  });

  group('purchasableBlocks', () {
    test(
      'the start frontier is exactly the 12 edge-adjacent ring-2 blocks',
      () {
        final buyable = purchasableBlocks(startingOwnedBlocks());
        expect(buyable.length, 12);
        // Three blocks on each of the four orthogonal sides.
        for (final b in const [
          (2, -1),
          (2, 0),
          (2, 1),
          (-2, 0),
          (0, 2),
          (0, -2),
        ]) {
          expect(buyable.contains(b), isTrue, reason: '$b should be buyable');
        }
      },
    );

    test('diagonal-only neighbors are NOT purchasable (edge adjacency)', () {
      final buyable = purchasableBlocks(startingOwnedBlocks());
      // (2,2) touches the owned 3×3 only at a corner.
      expect(buyable.contains((2, 2)), isFalse);
      expect(buyable.contains((-2, -2)), isFalse);
    });

    test('a freshly bought block opens its own new edge frontier', () {
      final owned = {...startingOwnedBlocks(), (2, 0)};
      final buyable = purchasableBlocks(owned);
      expect(buyable.contains((3, 0)), isTrue); // newly reachable
      expect(buyable.contains((2, 0)), isFalse); // now owned
      // The corner is reachable now that (2,1) is on the orthogonal frontier
      // of (2,0)... but (2,2) still only touches owned land at a corner.
      expect(buyable.contains((2, 2)), isFalse);
    });
  });
}
