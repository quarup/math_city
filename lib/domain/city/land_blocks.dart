/// Land ownership on an effectively-infinite plane (plan.md Phase 9 revamp):
/// the city is a *set of owned 4×4 blocks*, not a fixed rectangle. Tiles you
/// don't own show pale; you tap an adjacent block to buy it with coins, and
/// the price climbs 30% per ring the further the block sits from the center.
///
/// World tile coordinates are **signed** — block `(0,0)` is the center and
/// covers tiles `[0,4)×[0,4)`, so blocks (and the tiles / placements on them)
/// can be negative. Pure Dart: no Flutter / Flame / Drift imports.
library;

import 'dart:math' as math;

/// A "block" is a [kBlockSize]×[kBlockSize] square of world tiles.
const int kBlockSize = 4;

/// Price of a block on the first purchasable ring (ring 2 — rings 0–1, the
/// starting 3×3, are seeded free). Coins are study-seconds, so 600 = ten
/// minutes of math: about what it costs to fill the block's 16 tiles with
/// starter buildings, and the price of a median building.
const int kBaseBlockCoinCost = 600;

/// Each ring further out costs this much more than the one before it:
/// ring 2 = 600, ring 3 = 780, ring 4 = 1010, ring 5 = 1320, ring 6 = 1710.
const double kBlockRingGrowth = 1.3;

/// Chebyshev ring of a block: `max(|bx|, |by|)`. Center block `(0,0)` is ring
/// 0, the 8 blocks around it ring 1, and so on outward in square rings.
int blockRing(int bx, int by) => math.max(bx.abs(), by.abs());

/// Coin cost to buy block `(bx, by)`: [kBaseBlockCoinCost] on ring 2, growing
/// by [kBlockRingGrowth] per ring beyond it, rounded to the nearest 10.
/// (Rings 0–1 are seeded free, so this is only meaningful for ring ≥ 2; a
/// ring-1 block costs the base and the center block nothing.)
int blockCost(int bx, int by) {
  final ring = blockRing(bx, by);
  if (ring == 0) return 0;
  final raw =
      kBaseBlockCoinCost * math.pow(kBlockRingGrowth, math.max(0, ring - 2));
  return (raw / 10).round() * 10;
}

/// Floored integer division — unlike Dart's `~/` (which truncates toward zero),
/// this rounds toward negative infinity, so block coordinates stay correct for
/// negative tiles (e.g. tile -1 belongs to block -1, not 0).
int _floorDiv(int a, int b) => (a - ((a % b + b) % b)) ~/ b;

/// The block containing world tile `(col, row)`.
(int, int) blockOfTile(int col, int row) =>
    (_floorDiv(col, kBlockSize), _floorDiv(row, kBlockSize));

/// Every world tile of block `(bx, by)`.
Iterable<(int, int)> tilesOfBlock(int bx, int by) sync* {
  for (var c = bx * kBlockSize; c < bx * kBlockSize + kBlockSize; c++) {
    for (var r = by * kBlockSize; r < by * kBlockSize + kBlockSize; r++) {
      yield (c, r);
    }
  }
}

/// The purchasable frontier: every block *not* in [owned] that shares an
/// **edge** (4-neighborhood) with one. Diagonal-only neighbors are excluded,
/// so land grows orthogonally.
Set<(int, int)> purchasableBlocks(Set<(int, int)> owned) {
  const ortho = [(0, -1), (0, 1), (-1, 0), (1, 0)];
  final out = <(int, int)>{};
  for (final (bx, by) in owned) {
    for (final (dx, dy) in ortho) {
      final n = (bx + dx, by + dy);
      if (!owned.contains(n)) out.add(n);
    }
  }
  return out;
}

/// The starting land every new city is seeded with: the 3×3 blocks of rings 0–1
/// (`bx, by ∈ {-1, 0, 1}`), i.e. the same 12×12 tiles the old fixed grid began
/// with, centered on block `(0,0)`.
Set<(int, int)> startingOwnedBlocks() => {
  for (var bx = -1; bx <= 1; bx++)
    for (var by = -1; by <= 1; by++) (bx, by),
};

/// Every owned world tile, expanded from [ownedBlocks]. Used as the bounds
/// predicate for placement / road generation and to paint owned terrain.
Set<(int, int)> ownedTilesOf(Set<(int, int)> ownedBlocks) => {
  for (final (bx, by) in ownedBlocks) ...tilesOfBlock(bx, by),
};
