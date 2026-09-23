/// Pedestrians walking the auto-road graph (city_builder.md §9.3, idea B1).
///
/// A pedestrian lives on a road tile, heading in one of four grid directions,
/// `t ∈ [0, 1)` of the way from that tile's centre to the next. At each tile
/// centre it picks a road neighbour: straight ahead by preference, never a
/// U-turn unless the tile is a dead end. Now and then it stops for a moment.
/// Nothing here is persisted — citizens are decoration that respawn on every
/// screen.
///
/// Pure Dart — no Flutter / Flame. Screen placement (sidewalk lane offset,
/// depth sorting) is the game layer's job.
library;

import 'dart:math' as math;

/// Grid direction deltas `(dCol, dRow)`: 0 east, 1 south, 2 west, 3 north.
/// Matches `road_sprites.dart` (east exits the lower-right diamond edge).
const pedestrianDirDeltas = <(int, int)>[(1, 0), (0, 1), (-1, 0), (0, -1)];

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
    this.t = 0,
    this.phase = 0,
    this.wait = 0,
  });

  int col;
  int row;

  /// Index into [pedestrianDirDeltas].
  int dir;

  /// Progress from this tile's centre to the next, in `[0, 1)`.
  double t;

  /// Tiles per second while walking.
  final double speed;

  /// Sidewalk offset in world px at a 64 px tile, signed: `+` is the walker's
  /// right-hand side. Constant for the walker's life so it never crosses the
  /// road mid-tile.
  final double lane;

  /// Walk-cycle phase in radians; advances only while moving.
  double phase;

  /// Seconds left standing still (0 = walking).
  double wait;

  final CitizenLook look;

  bool get isWaiting => wait > 0;

  /// Painter's-order key: `col + row` interpolated along the current step.
  double get depth {
    final (dc, dr) = pedestrianDirDeltas[dir];
    return col + row + (dc + dr) * t;
  }
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
/// Walking advances [Pedestrian.t]; crossing a tile centre moves the walker
/// to the next tile and picks a new heading. A walking pedestrian starts a
/// pause with probability [pauseChancePerSecond] per second, lasting
/// [pauseMin] to [pauseMax] seconds; the walk-cycle [Pedestrian.phase] runs
/// at [phaseRate] radians per second (scaled by the walker's speed relative
/// to [referenceSpeed], so kids' legs move faster).
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
  p.t += dt * p.speed;
  while (p.t >= 1) {
    p.t -= 1;
    final (dc, dr) = pedestrianDirDeltas[p.dir];
    p
      ..col += dc
      ..row += dr
      ..dir = pickDirection(
        isRoad: isRoad,
        col: p.col,
        row: p.row,
        dir: p.dir,
        random: random,
      );
  }
  p.phase += dt * phaseRate * math.sqrt(p.speed / referenceSpeed);
}

/// A fresh walker on a random tile of [roadTiles] (must be non-empty),
/// heading along a random road neighbour (or east on an isolated tile),
/// part-way along its step so a batch doesn't spawn in lock-step.
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
