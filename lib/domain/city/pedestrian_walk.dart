/// Pedestrians walking the auto-road graph (city_builder.md §9.3, idea B1).
///
/// A pedestrian lives on a road tile, having entered it heading [Pedestrian
/// .dirIn] and about to leave it heading [Pedestrian.dir], `t ∈ [0, 1)` of
/// the way along the tile's **sidewalk path** (see [pedestrianPath]). At the
/// exit edge it steps onto the next tile and picks a new heading: straight
/// ahead by preference, never a U-turn unless the tile is a dead end. Now
/// and then it stops for a moment. Nothing here is persisted — citizens are
/// decoration that respawn on every screen.
///
/// Pure Dart — no Flutter / Flame. Positions are fractional tile
/// coordinates; the game layer maps them to the screen and depth-sorts.
library;

import 'dart:math' as math;

/// Grid direction deltas `(dCol, dRow)`: 0 east, 1 south, 2 west, 3 north.
/// Matches `road_sprites.dart` (east exits the lower-right diamond edge).
const pedestrianDirDeltas = <(int, int)>[(1, 0), (0, 1), (-1, 0), (0, -1)];

/// Sidewalk offset from the road's centre line, in tile units along the
/// walker's right-hand axis. The road sprites' asphalt spans ±0.3 of the
/// tile about the centre line and the beige band the remaining 0.3–0.5, so
/// 0.4 is the band's centre (see city_builder.md §9.3).
const double kSidewalkLane = 0.405;

/// How far past the tile centre a walker goes to round the cap of a
/// dead-end road (the cap's asphalt ends ~0.2 past the centre, radius 0.3).
const double _deadEndBack = 0.38;

/// What a citizen looks like: ARGB colours (kept as ints so the domain layer
/// stays free of `dart:ui`) plus an overall scale (kids are smaller) and a
/// head boost (kids' heads are bigger).
class CitizenLook {
  const CitizenLook({
    required this.shirt,
    required this.pants,
    required this.skin,
    required this.hair,
    this.scale = 1,
    this.headScale = 1,
  });

  final int shirt;
  final int pants;
  final int skin;
  final int hair;
  final double scale;
  final double headScale;
}

/// One walker. Mutable: [stepPedestrian] advances it in place.
class Pedestrian {
  Pedestrian({
    required this.col,
    required this.row,
    required this.dir,
    required this.speed,
    required this.lane,
    required this.look,
    int? dirIn,
    this.t = 0,
    this.phase = 0,
    this.wait = 0,
  }) : dirIn = dirIn ?? dir;

  int col;
  int row;

  /// Heading the walker entered this tile with (index into
  /// [pedestrianDirDeltas]); the first leg of the tile path runs this way.
  int dirIn;

  /// Heading the walker will leave this tile with.
  int dir;

  /// Progress along this tile's sidewalk path, in `[0, 1)`.
  double t;

  /// Tiles per second while walking (measured along the path).
  final double speed;

  /// Sidewalk offset in tile units, signed: `+` is the walker's right-hand
  /// side. Constant for the walker's life so it never crosses the road.
  final double lane;

  /// Walk-cycle phase in radians; advances only while moving.
  double phase;

  /// Seconds left standing still (0 = walking).
  double wait;

  final CitizenLook look;

  bool get isWaiting => wait > 0;
}

/// Where a walker is: fractional tile coordinates and the heading of the
/// path leg it is on (what the painter faces it toward).
typedef PedestrianPosition = ({double col, double row, int heading});

/// The polyline a walker follows across its current tile, as offsets from
/// the tile centre in tile units.
///
/// Every leg is axis-aligned. Entry and exit points sit on the edge
/// midpoints shifted by the lane; going straight they join directly. On a
/// bend the two offset lines meet at a single corner point: for a turn
/// toward the lane side that point hugs the inner kerb (well inside the
/// small sidewalk triangle the curve sprite leaves there), for a turn away
/// it sweeps the outer sidewalk. At a dead end (exit is the reverse of
/// entry) the walker goes past the centre, crosses behind the road's cap,
/// and comes back along the other sidewalk.
List<(double, double)> pedestrianPath(Pedestrian p) {
  final (ic, ir) = pedestrianDirDeltas[p.dirIn];
  final (oc, or) = pedestrianDirDeltas[p.dir];
  final (cic, cir) = pedestrianDirDeltas[(p.dirIn + 1) % 4];
  final (coc, cor) = pedestrianDirDeltas[(p.dir + 1) % 4];
  final l = p.lane;
  final entry = (-0.5 * ic + l * cic, -0.5 * ir + l * cir);
  final exit = (0.5 * oc + l * coc, 0.5 * or + l * cor);
  if (p.dir == p.dirIn) return [entry, exit];
  if (p.dir == (p.dirIn + 2) % 4) {
    return [
      entry,
      (-_deadEndBack * ic + l * cic, -_deadEndBack * ir + l * cir),
      (-_deadEndBack * ic + l * coc, -_deadEndBack * ir + l * cor),
      exit,
    ];
  }
  return [entry, (l * cic + l * coc, l * cir + l * cor), exit];
}

/// Length of [pedestrianPath] in tile units.
double pedestrianPathLength(Pedestrian p) {
  final pts = pedestrianPath(p);
  var len = 0.0;
  for (var i = 1; i < pts.length; i++) {
    len += _legLength(pts[i - 1], pts[i]);
  }
  return len;
}

double _legLength((double, double) a, (double, double) b) =>
    (b.$1 - a.$1).abs() + (b.$2 - a.$2).abs(); // legs are axis-aligned

int _legHeading((double, double) a, (double, double) b) {
  final dc = b.$1 - a.$1;
  final dr = b.$2 - a.$2;
  if (dc.abs() >= dr.abs()) return dc >= 0 ? 0 : 2;
  return dr >= 0 ? 1 : 3;
}

/// The walker's position along its tile path at [Pedestrian.t].
PedestrianPosition pedestrianPosition(Pedestrian p) {
  final pts = pedestrianPath(p);
  final total = pedestrianPathLength(p);
  var remaining = p.t.clamp(0.0, 1.0) * total;
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1];
    final b = pts[i];
    final len = _legLength(a, b);
    if (remaining <= len || i == pts.length - 1) {
      final k = len == 0 ? 0.0 : (remaining / len).clamp(0.0, 1.0);
      return (
        col: p.col + a.$1 + (b.$1 - a.$1) * k,
        row: p.row + a.$2 + (b.$2 - a.$2) * k,
        heading: _legHeading(a, b),
      );
    }
    remaining -= len;
  }
  throw StateError('unreachable');
}

/// Painter's-order key for the board's depth sort: `col + row` of the
/// walker's actual position.
double pedestrianDepth(Pedestrian p) {
  final pos = pedestrianPosition(p);
  return pos.col + pos.row;
}

/// Road neighbours of `(col, row)` as direction indices.
List<int> roadNeighbours(
  bool Function(int col, int row) isRoad,
  int col,
  int row,
) {
  final out = <int>[];
  for (var d = 0; d < 4; d++) {
    final (dc, dr) = pedestrianDirDeltas[d];
    if (isRoad(col + dc, row + dr)) out.add(d);
  }
  return out;
}

/// The direction to leave `(col, row)` in, arriving with heading [dir].
/// Straight ahead wins with probability [straightBias] when it is a road;
/// otherwise a uniform pick among the non-reverse road neighbours; the
/// reverse only at a dead end (or an isolated tile, where it just turns).
int pickDirection({
  required bool Function(int col, int row) isRoad,
  required int col,
  required int row,
  required int dir,
  required math.Random random,
  double straightBias = 0.6,
}) {
  final reverse = (dir + 2) % 4;
  final options = roadNeighbours(
    isRoad,
    col,
    row,
  ).where((d) => d != reverse).toList();
  if (options.isEmpty) return reverse;
  if (options.contains(dir) && random.nextDouble() < straightBias) return dir;
  return options[random.nextInt(options.length)];
}

/// Advances [p] by [dt] seconds. While waiting, only the wait timer runs.
/// Walking advances [Pedestrian.t] at the walker's speed over the path's
/// length; reaching the exit edge moves the walker to the next tile and
/// picks a new heading. A walking pedestrian starts a pause with
/// probability [pauseChancePerSecond] per second, lasting [pauseMin] to
/// [pauseMax] seconds; the walk-cycle [Pedestrian.phase] runs at
/// [phaseRate] radians per second (scaled by the walker's speed relative to
/// [referenceSpeed], so kids' legs move faster).
void stepPedestrian(
  Pedestrian p,
  double dt, {
  required bool Function(int col, int row) isRoad,
  required math.Random random,
  double pauseChancePerSecond = 0.05,
  double pauseMin = 1.5,
  double pauseMax = 3.5,
  double phaseRate = 9,
  double referenceSpeed = 0.16,
}) {
  if (p.wait > 0) {
    p.wait = math.max(0, p.wait - dt);
    return;
  }
  if (random.nextDouble() < pauseChancePerSecond * dt) {
    p.wait = pauseMin + random.nextDouble() * (pauseMax - pauseMin);
    return;
  }
  var distance = dt * p.speed;
  while (distance > 0) {
    final total = pedestrianPathLength(p);
    final left = (1 - p.t) * total;
    if (distance < left) {
      p.t += distance / total;
      break;
    }
    distance -= left;
    final (dc, dr) = pedestrianDirDeltas[p.dir];
    final next = pickDirection(
      isRoad: isRoad,
      col: p.col + dc,
      row: p.row + dr,
      dir: p.dir,
      random: random,
    );
    p
      ..col += dc
      ..row += dr
      ..t = 0
      ..dirIn = p.dir
      ..dir = next;
  }
  p.phase += dt * phaseRate * math.sqrt(p.speed / referenceSpeed);
}

/// A fresh walker on a random tile of [roadTiles] (must be non-empty),
/// heading straight along a random road neighbour (or east on an isolated
/// tile), part-way along its path so a batch doesn't spawn in lock-step.
Pedestrian spawnPedestrian({
  required List<(int, int)> roadTiles,
  required bool Function(int col, int row) isRoad,
  required math.Random random,
  required CitizenLook look,
  required double speed,
  required double lane,
}) {
  final (col, row) = roadTiles[random.nextInt(roadTiles.length)];
  final dirs = roadNeighbours(isRoad, col, row);
  return Pedestrian(
    col: col,
    row: row,
    dir: dirs.isEmpty ? 0 : dirs[random.nextInt(dirs.length)],
    speed: speed,
    lane: lane,
    look: look,
    t: random.nextDouble(),
    phase: random.nextDouble() * 2 * math.pi,
  );
}
