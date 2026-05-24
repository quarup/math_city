/// Pure-Dart placement validation for the city grid. No Flutter / Flame /
/// Drift imports — this is the testable core of the "road-access invariant".
///
/// The rule (see prd.md "City Builder / Placement" and plan.md Phase 7):
/// players place buildings on any vacant tiles and buildings may touch, but
/// **no building may be boxed in.** Every building must keep at least one free
/// orthogonal tile somewhere on its footprint perimeter so the auto-road
/// network can always reach it. The grid edge does *not* count as open — a
/// road has to run along an in-bounds vacant tile to reach a building.
library;

/// An axis-aligned building footprint on the grid: top-left anchor `(col, row)`
/// plus its tile size. All Phase 7 buildings are 1×1, but the validator walks
/// the real footprint perimeter so a future multi-tile building is handled.
class GridFootprint {
  const GridFootprint({
    required this.col,
    required this.row,
    required this.width,
    required this.height,
  });

  final int col;
  final int row;
  final int width;
  final int height;

  /// Every tile this footprint occupies.
  Iterable<(int, int)> tiles() sync* {
    for (var c = col; c < col + width; c++) {
      for (var r = row; r < row + height; r++) {
        yield (c, r);
      }
    }
  }

  /// The tiles orthogonally adjacent to (but outside) this footprint — its
  /// edge ring, excluding diagonals. These are the candidate road tiles.
  Iterable<(int, int)> perimeter() sync* {
    for (var c = col; c < col + width; c++) {
      yield (c, row - 1); // above the top edge
      yield (c, row + height); // below the bottom edge
    }
    for (var r = row; r < row + height; r++) {
      yield (col - 1, r); // left of the left edge
      yield (col + width, r); // right of the right edge
    }
  }
}

/// Why a placement is illegal.
enum PlacementRejection {
  /// The footprint extends past a grid edge.
  outOfBounds,

  /// The footprint overlaps a building already on the grid.
  overlap,

  /// The building being placed/moved would have no open side for a road.
  wouldBoxInSelf,

  /// The placement would seal off a neighbor's last open side.
  wouldBoxInNeighbor,
}

/// Result of [checkPlacement]. Legal when [rejection] is null.
class PlacementCheck {
  const PlacementCheck.ok() : rejection = null;
  const PlacementCheck.rejected(this.rejection);

  final PlacementRejection? rejection;

  bool get isLegal => rejection == null;
}

/// Validates placing (or moving) [candidate] onto a `gridWidth × gridHeight`
/// grid that already holds [existing] footprints.
///
/// Enforces the road-access invariant two-way: it rejects both a [candidate]
/// that would have no open perimeter side, and a [candidate] that would take
/// the last open side of an existing neighbor it now abuts. For a **move**,
/// exclude the moved building from [existing] (its old tiles are vacated).
PlacementCheck checkPlacement({
  required int gridWidth,
  required int gridHeight,
  required List<GridFootprint> existing,
  required GridFootprint candidate,
}) {
  // 1. Bounds.
  if (candidate.col < 0 ||
      candidate.row < 0 ||
      candidate.col + candidate.width > gridWidth ||
      candidate.row + candidate.height > gridHeight) {
    return const PlacementCheck.rejected(PlacementRejection.outOfBounds);
  }

  final occupied = <(int, int)>{};
  for (final f in existing) {
    occupied.addAll(f.tiles());
  }

  // 2. Overlap.
  for (final t in candidate.tiles()) {
    if (occupied.contains(t)) {
      return const PlacementCheck.rejected(PlacementRejection.overlap);
    }
  }

  // 3. Road-access invariant, evaluated against the post-placement grid.
  final after = {...occupied, ...candidate.tiles()};

  bool hasRoadAccess(GridFootprint f) {
    for (final (c, r) in f.perimeter()) {
      final inBounds = c >= 0 && r >= 0 && c < gridWidth && r < gridHeight;
      if (inBounds && !after.contains((c, r))) return true;
    }
    return false;
  }

  // (a) The candidate itself must keep an open side.
  if (!hasRoadAccess(candidate)) {
    return const PlacementCheck.rejected(PlacementRejection.wouldBoxInSelf);
  }

  // (b) Only neighbors the candidate now abuts can lose their last open side.
  final candidatePerimeter = candidate.perimeter().toSet();
  for (final f in existing) {
    final abuts = f.tiles().any(candidatePerimeter.contains);
    if (abuts && !hasRoadAccess(f)) {
      return const PlacementCheck.rejected(
        PlacementRejection.wouldBoxInNeighbor,
      );
    }
  }

  return const PlacementCheck.ok();
}
