import 'package:math_city/domain/city/placement_rules.dart';

/// Computes the road tiles for the "full street grid" layout (see prd.md
/// "City Builder / Roads" and plan.md Phase 7).
///
/// Every empty tile within the *built-up area* — the bounding box of all
/// placed buildings, expanded by one tile and clamped to the grid — becomes
/// road, so buildings sit in street-framed blocks. The untouched frontier
/// beyond that box stays green and the paved area grows as the city does.
/// Returns an empty set when there are no buildings.
///
/// The road-access invariant ([checkPlacement]) guarantees every building has
/// an open orthogonal neighbor; that neighbor lies inside the expanded box, so
/// every building is always fronted by road. The expanded box's outer ring
/// holds no buildings, so the road region is connected in the normal case.
///
/// Pure — no Flutter / Flame / Drift.
Set<(int, int)> generateRoads({
  required int gridWidth,
  required int gridHeight,
  required List<GridFootprint> buildings,
}) {
  if (buildings.isEmpty) return const {};

  final buildingTiles = <(int, int)>{};
  var minCol = gridWidth;
  var minRow = gridHeight;
  var maxCol = -1;
  var maxRow = -1;
  for (final b in buildings) {
    for (final (c, r) in b.tiles()) {
      buildingTiles.add((c, r));
      if (c < minCol) minCol = c;
      if (r < minRow) minRow = r;
      if (c > maxCol) maxCol = c;
      if (r > maxRow) maxRow = r;
    }
  }

  // Expand the built-up box by one tile (the block frame), clamped to grid.
  final loCol = _clamp(minCol - 1, 0, gridWidth - 1);
  final hiCol = _clamp(maxCol + 1, 0, gridWidth - 1);
  final loRow = _clamp(minRow - 1, 0, gridHeight - 1);
  final hiRow = _clamp(maxRow + 1, 0, gridHeight - 1);

  final roads = <(int, int)>{};
  for (var c = loCol; c <= hiCol; c++) {
    for (var r = loRow; r <= hiRow; r++) {
      if (!buildingTiles.contains((c, r))) roads.add((c, r));
    }
  }
  return roads;
}

int _clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
