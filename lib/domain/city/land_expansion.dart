/// Land expansion (plan.md Phase 9): spend 🧱 to grow the city grid
/// symmetrically outward by [kExpansionTilesPerSide] tiles on every side,
/// capped at [kMaxGridSize] per dimension. Growing outward means existing
/// placements shift by the per-side amount on each axis that grew, so the
/// city stays centered on the bigger map.
library;

/// Tiles added to *each* side per expansion (so a dimension grows by twice
/// this much).
const kExpansionTilesPerSide = 2;

/// v1 grid-size cap per dimension.
const kMaxGridSize = 24;

/// 🧱 cost of the n-th expansion (0-based). The beginner 12×12 map has
/// exactly three rungs: 12→16→20→24. Expansions past the end of the list
/// (a future bigger base map) stay at the last price.
const kExpansionBrickCosts = [60, 150, 300];

/// One purchasable expansion step: the grid size after it, what existing
/// placements shift by, and the 🧱 price.
class LandExpansionOffer {
  const LandExpansionOffer({
    required this.newGridWidth,
    required this.newGridHeight,
    required this.shiftX,
    required this.shiftY,
    required this.brickCost,
  });

  final int newGridWidth;
  final int newGridHeight;

  /// How far existing placements move (per axis) so the old land sits in the
  /// middle of the grown grid. Zero on an axis already at [kMaxGridSize].
  final int shiftX;
  final int shiftY;

  final int brickCost;
}

/// The next expansion available from `gridWidth × gridHeight`, or null when
/// both dimensions are at [kMaxGridSize]. The base size anchors the price
/// ladder ([kExpansionBrickCosts] is indexed by expansions already bought).
LandExpansionOffer? nextLandExpansion({
  required int gridWidth,
  required int gridHeight,
  required int baseGridWidth,
  required int baseGridHeight,
}) {
  const growth = 2 * kExpansionTilesPerSide;
  final canGrowW = gridWidth + growth <= kMaxGridSize;
  final canGrowH = gridHeight + growth <= kMaxGridSize;
  if (!canGrowW && !canGrowH) return null;

  final bought =
      ((gridWidth - baseGridWidth) + (gridHeight - baseGridHeight)) ~/
      (2 * growth);
  final cost =
      kExpansionBrickCosts[bought >= kExpansionBrickCosts.length
          ? kExpansionBrickCosts.length - 1
          : bought];

  return LandExpansionOffer(
    newGridWidth: canGrowW ? gridWidth + growth : gridWidth,
    newGridHeight: canGrowH ? gridHeight + growth : gridHeight,
    shiftX: canGrowW ? kExpansionTilesPerSide : 0,
    shiftY: canGrowH ? kExpansionTilesPerSide : 0,
    brickCost: cost,
  );
}
