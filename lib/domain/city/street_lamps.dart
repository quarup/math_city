/// Street lamps (city_builder.md §12, L3 locked 2026-10-02): a lantern on
/// alternating sides of the town's streets, every other tile, each coming
/// on at its own moment across dusk and staying on until dawn.
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

const _ortho = [(1, 0), (0, 1), (-1, 0), (0, -1)];

/// Where the lamps stand on [roads]: on straight tiles only (junctions,
/// bends and dead ends stay clear), every other tile, swapping sides
/// every second lamp. Positions depend only on the tile's coordinates —
/// pass **world** tiles — so a lamp never moves when the town grows.
/// Ordered by column, then row.
List<LampSpot> lampSpots(Set<(int, int)> roads) {
  final out = <LampSpot>[];
  final ordered = roads.toList()
    ..sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
  for (final (c, r) in ordered) {
    final n = [
      for (final (dc, dr) in _ortho) roads.contains((c + dc, r + dr)),
    ];
    final count = n.where((v) => v).length;
    if (count != 2) continue;
    final eastWest = n[0] && n[2];
    final northSouth = n[1] && n[3];
    if (!eastWest && !northSouth) continue;
    final along = eastWest ? c : r;
    if (along.isOdd) continue;
    final side = (along >> 1).isOdd ? 1.0 : -1.0;
    out.add((
      col: c,
      row: r,
      de: eastWest ? 0.0 : side * kLampOffset,
      ds: eastWest ? side * kLampOffset : 0.0,
      alongEast: eastWest,
    ));
  }
  return out;
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
