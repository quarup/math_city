/// Land ownership on an effectively-infinite plane (plan.md Phase 9 revamp):
/// the city is a *set of owned 4×4 blocks*, not a fixed rectangle. Tiles you
/// don't own show pale; you tap an adjacent block to buy it with 🧱, and the
/// price climbs the further the block sits from the center.
///
/// World tile coordinates are **signed** — block `(0,0)` is the center and
/// covers tiles `[0,4)×[0,4)`, so blocks (and the tiles / placements on them)
/// can be negative. Pure Dart: no Flutter / Flame / Drift imports.
library;

import 'dart:math' as math;

/// A "block" is a [kBlockSize]×[kBlockSize] square of world tiles.
const int kBlockSize = 4;

/// Linear price base: a ring-`r` block costs [kBaseBlockBrickCost] × `r` 🧱.
/// Rings 0–1 (the starting 3×3) are seeded free, so the first purchasable block
/// is ring 2 = 80 🧱.
const int kBaseBlockBrickCost = 40;

/// Chebyshev ring of a block: `max(|bx|, |by|)`. Center block `(0,0)` is ring
/// 0, the 8 blocks around it ring 1, and so on outward in square rings.
int blockRing(int bx, int by) => math.max(bx.abs(), by.abs());

/// 🧱 cost to buy block `(bx, by)`: [kBaseBlockBrickCost] × ring, linear.
/// (Rings 0–1 are seeded free, so this is only meaningful for ring ≥ 2.)
int blockCost(int bx, int by) => kBaseBlockBrickCost * blockRing(bx, by);

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
