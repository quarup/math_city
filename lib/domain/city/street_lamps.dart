/// Street lamps (city_builder.md §12, L3 locked 2026-10-02): lanterns on
/// the kerbs of the town's streets, on every other tile in a checkerboard,
/// each coming on at its own moment across dusk and staying on until dawn.
///
/// Pure Dart: no Flutter / Flame / Drift imports. The painter in
/// `lib/game/city/` draws the post and its pool of light.
library;

import 'package:math_city/domain/city/terrain.dart';

/// How far from the road's centre line a lamp stands, in tiles: the outer
/// edge of the pavement, clear of the walkers' lane (0.405).
const double kLampOffset = 0.46;

/// One lamp: the road tile it stands on and where on that tile, as east /
/// south offsets from the tile centre.
typedef LampSpot = ({int col, int row, double de, double ds, bool alongEast});

/// The least distance between two lamps, in tiles. Two lamps on tiles
/// that touch at a corner (either side of a bend) can face each other
/// three quarters of a tile apart and read as one doubled lamp.
const double kLampMinGap = 1;

/// Where the lamps stand on [roads]: on every other road tile, in a
/// checkerboard, at a **kerb** — a side of the tile with no road beyond
/// it. A straight tile has two kerbs and its lamps swap sides down the
/// street; a T-junction or the edge of a two-tile-wide road has one; a
/// bend has its two outer sides; a dead end takes the far end. A crossing
/// has none and stays clear. A lamp that would stand within [kLampMinGap]
/// of an earlier one takes the tile's other kerb, or is left out.
///
/// The first rule lit straight tiles only. Road rings round neighbouring
/// buildings merge into wide roads and tight grids, where every tile is a
/// junction, so the built-up middle of a town had no lamps at all.
///
/// A lamp depends only on the tiles round its own — pass **world** tiles
/// — so it stays put when the town grows elsewhere. Ordered by column,
/// then row.
List<LampSpot> lampSpots(Set<(int, int)> roads) {
  final out = <LampSpot>[];
  // Where each accepted lamp stands, in tiles, by its road tile.
  final standing = <(int, int), (double, double)>{};
  bool clear(double x, double y, int c, int r) {
    for (var dc = -2; dc <= 2; dc++) {
      for (var dr = -2; dr <= 2; dr++) {
        final other = standing[(c + dc, r + dr)];
        if (other == null) continue;
        final dx = other.$1 - x;
        final dy = other.$2 - y;
        if (dx * dx + dy * dy < kLampMinGap * kLampMinGap) return false;
      }
    }
    return true;
  }

  final ordered = roads.toList()
    ..sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
  for (final (c, r) in ordered) {
    if ((c + r).isOdd) continue;
    final kerbs = _kerbs(
      east: roads.contains((c + 1, r)),
      south: roads.contains((c, r + 1)),
      west: roads.contains((c - 1, r)),
      north: roads.contains((c, r - 1)),
      // Steps by one from each lamp to the next along a street.
      flip: ((c + r) >> 1).isOdd,
    );
    for (final (de, ds) in kerbs) {
      final x = c + de * kLampOffset;
      final y = r + ds * kLampOffset;
      if (!clear(x, y, c, r)) continue;
      standing[(c, r)] = (x, y);
      out.add((
        col: c,
        row: r,
        de: de * kLampOffset,
        ds: ds * kLampOffset,
        // The pool of light lies along the kerb.
        alongEast: ds != 0,
      ));
      break;
    }
  }
  return out;
}

/// The sides of a road tile its lamp may stand on, best first, as (east,
/// south) steps, given which neighbours are road. Empty when the tile has
/// no kerb (a crossing) or no street (a lone tile). [flip] says which of
/// two kerbs comes first.
List<(int, int)> _kerbs({
  required bool east,
  required bool south,
  required bool west,
  required bool north,
  required bool flip,
}) {
  final open = [
    if (!east) (1, 0),
    if (!south) (0, 1),
    if (!west) (-1, 0),
    if (!north) (0, -1),
  ];
  return switch (open.length) {
    1 => open,
    2 => flip ? open : open.reversed.toList(),
    // A dead end: the far end, opposite the one way in.
    3 => [
      if (east)
        (-1, 0)
      else if (south)
        (0, -1)
      else if (west)
        (1, 0)
      else
        (0, 1),
    ],
    _ => const [],
  };
}

/// How long a lamp takes to come up, in clock hours.
const double kLampFadeHours = 0.04;

/// How lit the lamp on world tile `(col, row)` is at [hour], `0..1`: each
/// comes on at its own moment between about 17:30 and 18:20, burns all
/// night, and goes out between 6:20 and 6:40.
double lampLightAt(double hour, int col, int row) {
  final h = ((hour % 24) + 24) % 24;
  final onAt = 17.55 + tileHash(col * 3 + 1, row * 5 + 2) * 0.8;
  final offAt = 6.3 + tileHash(row, col) * 0.4;
  double ramp(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
  if (h >= onAt) return ramp((h - onAt) / kLampFadeHours);
  if (h < offAt) return ramp((offAt - h) / kLampFadeHours);
  return 0;
}
