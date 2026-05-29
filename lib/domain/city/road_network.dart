import 'dart:collection';

import 'package:math_city/domain/city/placement_rules.dart';

/// Computes the road tiles for the city (see prd.md "City Builder / Roads" and
/// plan.md Phase 7). Two steps:
///
/// 1. **Hug each island.** Every empty tile in the Moore neighborhood (all 8
///    directions) of a building becomes road. This wraps each cluster of
///    buildings in a connected road ring and fills the small gaps between
///    neighbours, without paving open dead space.
/// 2. **Connect the islands.** The hug rings of separate clusters are linked
///    into one network by the shortest road path through empty tiles.
///
/// Returns an empty set when there are no buildings. The road-access invariant
/// ([checkPlacement]) guarantees every building has an open orthogonal
/// neighbour, so every building is always fronted by road.
///
/// Pure — no Flutter / Flame / Drift.
Set<(int, int)> generateRoads({
  required int gridWidth,
  required int gridHeight,
  required List<GridFootprint> buildings,
}) {
  if (buildings.isEmpty) return const {};

  final buildingTiles = <(int, int)>{};
  for (final b in buildings) {
    buildingTiles.addAll(b.tiles());
  }

  bool inBounds(int c, int r) =>
      c >= 0 && r >= 0 && c < gridWidth && r < gridHeight;

  // Step 1: hug rings.
  final roads = <(int, int)>{};
  for (final (bc, br) in buildingTiles) {
    for (final (dc, dr) in _moore) {
      final c = bc + dc;
      final r = br + dr;
      if (inBounds(c, r) && !buildingTiles.contains((c, r))) {
        roads.add((c, r));
      }
    }
  }

  // Step 2: connect islands. Each pass links the lowest-ordered component to
  // its nearest neighbour, paving the grass tiles in between, until one
  // network remains (or no path exists).
  while (true) {
    final components = _components(roads);
    if (components.length <= 1) break;
    final connector = _shortestConnector(
      components.first,
      roads,
      buildingTiles,
      inBounds,
    );
    if (connector == null || connector.isEmpty) break;
    roads.addAll(connector);
  }

  return roads;
}

const _ortho = [(0, -1), (0, 1), (-1, 0), (1, 0)];
const _moore = [
  (-1, -1),
  (0, -1),
  (1, -1),
  (-1, 0),
  (1, 0),
  (-1, 1),
  (0, 1),
  (1, 1),
];

int _cmp((int, int) a, (int, int) b) {
  final c = a.$1.compareTo(b.$1);
  return c != 0 ? c : a.$2.compareTo(b.$2);
}

/// Orthogonally-connected components of [roads], ordered so the component
/// holding the lowest-ordered tile comes first (deterministic).
List<Set<(int, int)>> _components(Set<(int, int)> roads) {
  final seen = <(int, int)>{};
  final components = <Set<(int, int)>>[];
  final ordered = roads.toList()..sort(_cmp);
  for (final start in ordered) {
    if (seen.contains(start)) continue;
    final component = <(int, int)>{};
    final stack = <(int, int)>[start];
    seen.add(start);
    while (stack.isNotEmpty) {
      final (c, r) = stack.removeLast();
      component.add((c, r));
      for (final (dc, dr) in _ortho) {
        final n = (c + dc, r + dr);
        if (roads.contains(n) && !seen.contains(n)) {
          seen.add(n);
          stack.add(n);
        }
      }
    }
    components.add(component);
  }
  return components;
}

/// Shortest grass path linking [sources] (one road component) to any other
/// road tile, as the set of empty tiles to pave. Null if no path exists.
Set<(int, int)>? _shortestConnector(
  Set<(int, int)> sources,
  Set<(int, int)> roads,
  Set<(int, int)> buildingTiles,
  bool Function(int, int) inBounds,
) {
  final parent = <(int, int), (int, int)>{};
  final visited = <(int, int)>{...sources};
  final queue = ListQueue<(int, int)>()..addAll(sources.toList()..sort(_cmp));

  while (queue.isNotEmpty) {
    final (c, r) = queue.removeFirst();
    for (final (dc, dr) in _ortho) {
      final n = (c + dc, r + dr);
      if (!inBounds(n.$1, n.$2)) continue;
      if (buildingTiles.contains(n) || visited.contains(n)) continue;

      // Reached a road tile in another component — backtrack the grass we
      // crossed and return it to be paved.
      if (roads.contains(n)) {
        final path = <(int, int)>{};
        (int, int)? cur = (c, r);
        while (cur != null && !sources.contains(cur)) {
          path.add(cur);
          cur = parent[cur];
        }
        return path;
      }

      parent[n] = (c, r);
      visited.add(n);
      queue.add(n);
    }
  }
  return null;
}
