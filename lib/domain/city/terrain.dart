/// Ground and countryside (city_builder.md §11, X11 locked 2026-10-01): one
/// meadow palette inside and outside the town, hash-seeded decor that is
/// sparse on owned land and wooded beyond it, a rail fence along every
/// owned-tile edge that faces the wild, and the two roads that leave town.
///
/// Everything here is deterministic in the tile coordinates, so the same
/// world tile always grows the same tree. Pure Dart: no Flutter / Flame /
/// Drift imports. The painter in `lib/game/city/` turns these specs into
/// pixels.
library;

/// A stable pseudo-random number in `[0, 1)` for a tile — the port of the
/// mocks' `hash2`, so the Flutter ground matches the approved pages.
double tileHash(int c, int r) {
  var h = ((c * 73856093) ^ (r * 19349663)) & 0xFFFFFFFF;
  h = ((h ^ (h >> 13)) * 0x5bd1e995) & 0xFFFFFFFF;
  h ^= h >> 15;
  return h / 4294967296;
}

/// Which greens a tile is painted from: the light meadow inside the
/// town, scrub on the purchasable ring, forest floor beyond. The bands
/// follow the fence — buying a block turns it meadow and pushes the scrub
/// and the forest out with it.
enum TerrainBand { meadow, scrub, forest }

/// The band for a block [distance] blocks (Chebyshev) from the nearest
/// owned block: `0` is owned.
TerrainBand terrainBandForDistance(int distance) => switch (distance) {
  0 => TerrainBand.meadow,
  1 => TerrainBand.scrub,
  _ => TerrainBand.forest,
};

/// Chebyshev distance in blocks from `(bx, by)` to the nearest block in
/// [owned], capped at [cap] (the bands stop changing past 2 anyway).
int blockDistanceToOwned(
  int bx,
  int by,
  Set<(int, int)> owned, {
  int cap = 2,
}) {
  if (owned.contains((bx, by))) return 0;
  var best = cap;
  for (final (ox, oy) in owned) {
    final d = (bx - ox).abs() > (by - oy).abs()
        ? (bx - ox).abs()
        : (by - oy).abs();
    if (d < best) best = d;
    if (best == 1) break;
  }
  return best;
}

/// Where a tile's grass tuft goes, if it has one: offsets in tile widths
/// from the tile centre. Null for a tile without a tuft.
(double, double)? tuftAt(int col, int row) {
  final h = tileHash(col, row);
  if (h <= 0.55) return null;
  return ((h - 0.5) * 30 / 64, (tileHash(row, col) - 0.5) * 12 / 64);
}

enum DecorKind { tree, bush, flowers, rock }

/// One thing growing on a tile: its kind, where on the tile it stands
/// (offsets in tile widths from the centre), and its size / colour pick.
class DecorItem {
  const DecorItem({
    required this.kind,
    required this.col,
    required this.row,
    required this.dx,
    required this.dy,
    required this.scale,
    required this.variant,
  });

  final DecorKind kind;
  final int col;
  final int row;
  final double dx;
  final double dy;
  final double scale;

  /// `0..2`: which green / which blooms.
  final int variant;
}

/// Tree probability on a tile the town owns — the town is open ground.
const double kTownTreeDensity = 0.04;

/// Tree probability on a tile beyond the fence — the countryside is
/// wooded everywhere (X10).
const double kWildTreeDensity = 0.32;

/// What grows on tile `(col, row)`, or null for bare grass. [owned] picks
/// the density; [ring] is the tile's block ring (flowers stay near town).
DecorItem? decorAt(int col, int row, {required bool owned, required int ring}) {
  final h = tileHash(col * 3 + 1, row * 7 + 2);
  final h2 = tileHash(row * 5 + 3, col * 11 + 4);
  final dx = (h2 - 0.5) * 22 / 64;
  final dy = (tileHash(col + 9, row + 9) - 0.5) * 10 / 64;
  final pTree = owned ? kTownTreeDensity : kWildTreeDensity;
  final variant = (h2 * 3).floor();
  if (h < pTree) {
    return DecorItem(
      kind: DecorKind.tree,
      col: col,
      row: row,
      dx: dx,
      dy: dy,
      scale: 0.8 + h2 * 0.6,
      variant: variant,
    );
  }
  if (h < pTree + 0.06) {
    return DecorItem(
      kind: DecorKind.bush,
      col: col,
      row: row,
      dx: dx,
      dy: dy,
      scale: 0.7 + h2 * 0.5,
      variant: variant,
    );
  }
  // Flowers keep to the meadow and the scrub; the forest floor has none.
  if (h < pTree + 0.16 && (owned || ring <= 3)) {
    return DecorItem(
      kind: DecorKind.flowers,
      col: col,
      row: row,
      dx: dx,
      dy: dy,
      scale: 1,
      variant: variant,
    );
  }
  if (h < pTree + 0.19) {
    return DecorItem(
      kind: DecorKind.rock,
      col: col,
      row: row,
      dx: dx,
      dy: dy,
      scale: 0.6 + h2 * 0.6,
      variant: variant,
    );
  }
  return null;
}

/// The four sides of a tile diamond, named by compass direction on screen
/// (east is the `col + 1` neighbour, south the `row + 1` neighbour).
enum TileSide { east, south, west, north }

/// Step to the neighbour across [side].
(int, int) neighbourAcross(TileSide side) => switch (side) {
  TileSide.east => (1, 0),
  TileSide.south => (0, 1),
  TileSide.west => (-1, 0),
  TileSide.north => (0, -1),
};

/// One owned-tile edge that faces unowned land: where the fence runs.
typedef EdgeSegment = ({int col, int row, TileSide side});

/// Every edge of an [owned] tile whose neighbour across it is not owned,
/// except where a road crosses the line (both tiles road): the fence opens
/// there, so a road never dead-ends against it. Ordered by column, row,
/// then side, so the result is stable.
List<EdgeSegment> edgeSegments({
  required Set<(int, int)> owned,
  Set<(int, int)> roads = const {},
}) {
  final out = <EdgeSegment>[];
  final ordered = owned.toList()
    ..sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
  for (final (c, r) in ordered) {
    final onRoad = roads.contains((c, r));
    for (final side in TileSide.values) {
      final (dc, dr) = neighbourAcross(side);
      final n = (c + dc, r + dr);
      if (owned.contains(n)) continue;
      if (onRoad && roads.contains(n)) continue;
      out.add((col: c, row: r, side: side));
    }
  }
  return out;
}

/// The main street: a fixed world row that runs off the map east and west.
/// It is the row just north of the mayor's office (`kMayorsOfficeTile`
/// is `(1, 1)`, a 2×2), so the office fronts it from the first second.
const int kMainStreetRow = 0;

/// The high street: a fixed world column that leaves the main street and
/// runs off the map south — the column just east of the mayor's office.
const int kHighStreetCol = 3;

/// Whether world tile `(col, row)` lies on the main street or the high
/// street — the roads that run on past the fence and off the map.
bool isHighwayTile(int col, int row) =>
    row == kMainStreetRow || (col == kHighStreetCol && row >= kMainStreetRow);

/// The tiles of the two roads that leave town, clipped to the world-tile
/// box `[minCol, maxCol] × [minRow, maxRow]` (the rendered window). They
/// are road inside and outside the fence alike, and the auto-roads join
/// them. Beyond the fence they never move. Inside it the player may set a
/// building down on one — the auto-roads go round it — provided the
/// stretches outside can still reach each other through the town
/// (`checkPlacement`'s `through`); the automatic proposals keep off them
/// (`reserved`).
Set<(int, int)> highwayTiles({
  required int minCol,
  required int maxCol,
  required int minRow,
  required int maxRow,
}) => {
  if (kMainStreetRow >= minRow && kMainStreetRow <= maxRow)
    for (var c = minCol; c <= maxCol; c++) (c, kMainStreetRow),
  if (kHighStreetCol >= minCol && kHighStreetCol <= maxCol)
    for (var r = kMainStreetRow; r <= maxRow; r++)
      if (r >= minRow) (kHighStreetCol, r),
};
