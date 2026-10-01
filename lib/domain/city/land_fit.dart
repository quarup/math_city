/// Finding land for a building that does not fit (city_builder.md §11,
/// E5 + E9): the smallest connected set of purchasable blocks that,
/// together with the land the town owns, has room for the footprint —
/// cheapest total first, nearest to town on ties. A single block is the
/// common answer; the big capstones (up to 6×6 on 4×4 blocks) need a
/// group, and a group may reach into ring 3 because it is bought as one.
///
/// Pure Dart: no Flutter / Flame / Drift imports.
library;

import 'package:math_city/domain/city/land_blocks.dart';
import 'package:math_city/domain/city/placement_rules.dart';

/// The outcome of [findBlockSetForFootprint]: the blocks to stake and
/// where the building goes once they are owned.
class BlockSetFit {
  const BlockSetFit({required this.blocks, required this.footprint});

  final Set<(int, int)> blocks;
  final GridFootprint footprint;

  /// The group's price: the sum of its blocks' ring prices.
  int get price => blockSetPrice(blocks);
}

int blockSetPrice(Iterable<(int, int)> blocks) {
  var total = 0;
  for (final (bx, by) in blocks) {
    total += blockCost(bx, by);
  }
  return total;
}

const _ortho = [(0, -1), (0, 1), (-1, 0), (1, 0)];

/// Whether [blocks] can be bought as one site: none is owned, and every one
/// of them is reachable from the owned land by orthogonal steps through the
/// set itself — so the group hangs off the town, even where a block of it
/// sits on ring 3 with no owned neighbour of its own.
bool blockSetPurchasable(Set<(int, int)> owned, Set<(int, int)> blocks) {
  if (blocks.isEmpty || blocks.any(owned.contains)) return false;
  final frontier = purchasableBlocks(owned);
  final seen = <(int, int)>{};
  final stack = <(int, int)>[
    for (final b in blocks)
      if (frontier.contains(b)) b,
  ];
  seen.addAll(stack);
  while (stack.isNotEmpty) {
    final (bx, by) = stack.removeLast();
    for (final (dx, dy) in _ortho) {
      final n = (bx + dx, by + dy);
      if (blocks.contains(n) && seen.add(n)) stack.add(n);
    }
  }
  return seen.length == blocks.length;
}

/// Finds the block set for a `[width]×[height]` footprint: the smallest
/// connected set of unowned blocks (at most [maxBlocks]) such that the
/// footprint fits legally on `owned ∪ set`, using at least one new tile.
/// Among sets of that size the cheapest wins, then the one whose centre is
/// nearest [town] (a block), then the lowest-ordered. The footprint lands
/// as near the town as the set allows. Null if no set of up to
/// [maxBlocks] blocks works.
BlockSetFit? findBlockSetForFootprint({
  required Set<(int, int)> ownedBlocks,
  required List<GridFootprint> existing,
  required int width,
  required int height,
  Set<(int, int)> reserved = const {},
  int maxBlocks = 4,
  (int, int) town = (0, 0),
}) {
  final ownedTiles = ownedTilesOf(ownedBlocks);
  final townTile = (
    town.$1 * kBlockSize + (kBlockSize - 1) / 2,
    town.$2 * kBlockSize + (kBlockSize - 1) / 2,
  );

  // Sets of size k, grown from the frontier; each keyed by its sorted
  // blocks so a set reached two ways is tried once.
  var layer = <String, Set<(int, int)>>{
    for (final b in purchasableBlocks(ownedBlocks)) _key({b}): {b},
  };
  for (var k = 1; k <= maxBlocks && layer.isNotEmpty; k++) {
    BlockSetFit? best;
    var bestPrice = 0;
    var bestDist = double.infinity;
    var bestKey = '';
    for (final entry in layer.entries) {
      final blocks = entry.value;
      final spot = _fitOn(
        ownedTiles: ownedTiles,
        blocks: blocks,
        existing: existing,
        width: width,
        height: height,
        reserved: reserved,
        townTile: townTile,
      );
      if (spot == null) continue;
      final price = blockSetPrice(blocks);
      final dist = _centreDistance(blocks, townTile);
      final better =
          best == null ||
          price < bestPrice ||
          (price == bestPrice &&
              (dist < bestDist ||
                  (dist == bestDist && entry.key.compareTo(bestKey) < 0)));
      if (better) {
        best = BlockSetFit(blocks: blocks, footprint: spot);
        bestPrice = price;
        bestDist = dist;
        bestKey = entry.key;
      }
    }
    if (best != null) return best;
    // Grow every set by one adjacent unowned block.
    final next = <String, Set<(int, int)>>{};
    for (final blocks in layer.values) {
      for (final (bx, by) in blocks) {
        for (final (dx, dy) in _ortho) {
          final n = (bx + dx, by + dy);
          if (blocks.contains(n) || ownedBlocks.contains(n)) continue;
          final grown = {...blocks, n};
          next.putIfAbsent(_key(grown), () => grown);
        }
      }
    }
    layer = next;
  }
  return null;
}

String _key(Set<(int, int)> blocks) {
  final list = blocks.toList()
    ..sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
  return list.map((b) => '${b.$1},${b.$2}').join(';');
}

double _centreDistance(Set<(int, int)> blocks, (double, double) townTile) {
  var cx = 0.0;
  var cy = 0.0;
  for (final (bx, by) in blocks) {
    cx += bx * kBlockSize + (kBlockSize - 1) / 2;
    cy += by * kBlockSize + (kBlockSize - 1) / 2;
  }
  cx /= blocks.length;
  cy /= blocks.length;
  final dx = cx - townTile.$1;
  final dy = cy - townTile.$2;
  return dx * dx + dy * dy;
}

/// The legal footprint on `ownedTiles ∪ blocks` that uses at least one
/// tile of [blocks], nearest [townTile]; null if none.
GridFootprint? _fitOn({
  required Set<(int, int)> ownedTiles,
  required Set<(int, int)> blocks,
  required List<GridFootprint> existing,
  required int width,
  required int height,
  required Set<(int, int)> reserved,
  required (double, double) townTile,
}) {
  final newTiles = ownedTilesOf(blocks);
  final land = {...ownedTiles, ...newTiles};
  var minC = 1 << 30;
  var minR = 1 << 30;
  var maxC = -(1 << 30);
  var maxR = -(1 << 30);
  for (final (c, r) in newTiles) {
    if (c < minC) minC = c;
    if (r < minR) minR = r;
    if (c > maxC) maxC = c;
    if (r > maxR) maxR = r;
  }
  GridFootprint? best;
  var bestCost = double.infinity;
  for (var col = minC - width + 1; col <= maxC; col++) {
    for (var row = minR - height + 1; row <= maxR; row++) {
      final candidate = GridFootprint(
        col: col,
        row: row,
        width: width,
        height: height,
      );
      if (!candidate.tiles().any(newTiles.contains)) continue;
      final check = checkPlacement(
        ownedTiles: land,
        existing: existing,
        candidate: candidate,
        reserved: reserved,
      );
      if (!check.isLegal) continue;
      final dx = col + (width - 1) / 2 - townTile.$1;
      final dy = row + (height - 1) / 2 - townTile.$2;
      final cost = dx * dx + dy * dy;
      if (cost < bestCost) {
        best = candidate;
        bestCost = cost;
      }
    }
  }
  return best;
}
