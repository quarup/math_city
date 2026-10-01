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

/// Validates placing (or moving) [candidate] onto the city's owned land
/// ([ownedTiles], the set of purchased world tiles) which already holds
/// [existing] footprints.
///
/// Enforces the road-access invariant two-way: it rejects both a [candidate]
/// that would have no open perimeter side, and a [candidate] that would take
/// the last open side of an existing neighbor it now abuts. For a **move**,
/// exclude the moved building from [existing] (its old tiles are vacated).
///
/// [reserved] tiles (the main street and the high street, `terrain.dart`)
/// can never be built on, but they are road, so they count as an open side.
PlacementCheck checkPlacement({
  required Set<(int, int)> ownedTiles,
  required List<GridFootprint> existing,
  required GridFootprint candidate,
  Set<(int, int)> reserved = const {},
}) {
  // 1. Bounds: every tile of the footprint must sit on owned land, off the
  // fixed roads.
  if (!candidate.tiles().every(
    (t) => ownedTiles.contains(t) && !reserved.contains(t),
  )) {
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
      // A road can only run on owned land, so the edge of owned land does not
      // count as an open side.
      if (ownedTiles.contains((c, r)) && !after.contains((c, r))) return true;
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

/// Auto-fit a `[width]×[height]` footprint so it *covers* the tapped tile
/// `(tapCol, tapRow)`, sliding the anchor as needed (see prd.md "Placement" /
/// plan.md Phase 9 — "place the building on the area containing the tile under
/// the click, even if the anchor needs to move").
///
/// The footprint's anchor is its north (min col+row) corner, so on its own a
/// tap that wants a multi-tile building *centered* on a tile would push the
/// building south-east off a usable spot. This walks every anchor offset that
/// keeps the tapped tile inside the footprint and returns the first fully-legal
/// one (bounds + overlap + the two-way road-access invariant via
/// [checkPlacement]), **preferring the smallest slide** from "anchor at the
/// tapped tile" — so the building lands as close to where the player tapped as
/// its footprint allows.
///
/// Returns null when the tapped tile is itself off owned land or occupied, or
/// no covering footprint is legal. For a **move**, exclude the moved building
/// from [existing] (its old tiles are vacated).
GridFootprint? resolvePlacement({
  required Set<(int, int)> ownedTiles,
  required List<GridFootprint> existing,
  required int width,
  required int height,
  required int tapCol,
  required int tapRow,
  Set<(int, int)> reserved = const {},
}) {
  // The tapped tile itself must be on owned land and free — the player is
  // pointing at where the building should go.
  if (!ownedTiles.contains((tapCol, tapRow)) ||
      reserved.contains((tapCol, tapRow))) {
    return null;
  }
  for (final f in existing) {
    for (final t in f.tiles()) {
      if (t == (tapCol, tapRow)) return null;
    }
  }

  GridFootprint? best;
  int? bestCost;
  // (dCol, dRow) is the tapped tile's position *within* the footprint, so the
  // anchor is (tapCol - dCol, tapRow - dRow). Cost is the slide distance from
  // anchoring at the tap; the smaller, the nearer the building lands to the
  // tap (cost 0 == the legacy "anchor at the tapped tile" behaviour).
  for (var dCol = 0; dCol < width; dCol++) {
    for (var dRow = 0; dRow < height; dRow++) {
      final cost = dCol + dRow;
      if (bestCost != null && cost >= bestCost) continue;
      final candidate = GridFootprint(
        col: tapCol - dCol,
        row: tapRow - dRow,
        width: width,
        height: height,
      );
      final check = checkPlacement(
        ownedTiles: ownedTiles,
        existing: existing,
        candidate: candidate,
        reserved: reserved,
      );
      if (!check.isLegal) continue;
      best = candidate;
      bestCost = cost;
    }
  }
  return best;
}

/// Where a letter's *Build it!* proposes a [width]×[height] building
/// (city_builder.md §10.4): the legal footprint nearest [anchor] (the
/// mayor's office) that leaves at least one free tile between itself and
/// every existing footprint, so the auto-road can run between them. Falls
/// back to the nearest legal footprint of any kind, or null when nothing
/// fits on owned land. Deterministic: ties break on the smaller column,
/// then row.
GridFootprint? proposePlacement({
  required Set<(int, int)> ownedTiles,
  required List<GridFootprint> existing,
  required int width,
  required int height,
  required (int, int) anchor,
  Set<(int, int)> reserved = const {},
}) {
  final occupied = <(int, int)>{};
  for (final f in existing) {
    occupied.addAll(f.tiles());
  }
  // Tiles touching an existing footprint (8-neighbourhood): a candidate
  // that avoids these keeps a road-wide gap.
  final fringe = <(int, int)>{};
  for (final (c, r) in occupied) {
    for (var dc = -1; dc <= 1; dc++) {
      for (var dr = -1; dr <= 1; dr++) {
        fringe.add((c + dc, r + dr));
      }
    }
  }

  GridFootprint? best;
  GridFootprint? fallback;
  var bestCost = double.infinity;
  var fallbackCost = double.infinity;
  final cols = ownedTiles.map((t) => t.$1).toList()..sort();
  final rows = ownedTiles.map((t) => t.$2).toList()..sort();
  if (cols.isEmpty) return null;
  for (var col = cols.first; col <= cols.last; col++) {
    for (var row = rows.first; row <= rows.last; row++) {
      final candidate = GridFootprint(
        col: col,
        row: row,
        width: width,
        height: height,
      );
      final check = checkPlacement(
        ownedTiles: ownedTiles,
        existing: existing,
        candidate: candidate,
        reserved: reserved,
      );
      if (!check.isLegal) continue;
      final cx = col + (width - 1) / 2;
      final cy = row + (height - 1) / 2;
      final dx = cx - anchor.$1;
      final dy = cy - anchor.$2;
      final cost = dx * dx + dy * dy;
      final spaced = candidate.tiles().every((t) => !fringe.contains(t));
      if (spaced) {
        if (cost < bestCost) {
          best = candidate;
          bestCost = cost;
        }
      } else if (cost < fallbackCost) {
        fallback = candidate;
        fallbackCost = cost;
      }
    }
  }
  return best ?? fallback;
}
