/// Cars driving the auto-road graph (city_builder.md §9, ideas A1/A2).
///
/// A [Vehicle] lives on a road tile exactly like a `Pedestrian`: it entered
/// heading [Vehicle.dirIn], will leave heading [Vehicle.dir], and is
/// `t ∈ [0, 1)` of the way along the tile's **driving path**
/// ([vehiclePath]). The differences from the sidewalk walker are what make
/// it read as a car: it keeps to the right-hand lane, follows the curve
/// tiles' quarter-circle arcs instead of cornering, holds behind a car
/// ahead in its lane, and faces one of **eight** screen headings so a 90°
/// bend is two 45° steps rather than one flick (see [vehicleHeading]).
///
/// Pure Dart — no Flutter / Flame. Positions are fractional tile
/// coordinates; the game layer maps them to the screen, depth-sorts, and
/// picks the sprite for the heading.
library;

import 'dart:math' as math;

import 'package:math_city/domain/city/pedestrian_walk.dart'
    show pedestrianDirDeltas, pickDirection, roadNeighbours;

/// Driving-lane offset from the road's centre line, in tile units along the
/// car's right-hand axis. The asphalt spans ±0.3 about the centre line; a
/// 0.26-wide car centred at 0.12 sits between the dashes and the kerb.
const double kDrivingLane = 0.12;

/// How far past the tile centre a car drives before swinging round at a
/// dead end (the road's cap ends ~0.2 past the centre).
const double _deadEndBack = 0.2;

/// Segments a quarter-circle bend is sampled into.
const int _arcSegments = 8;

/// A car ahead within this many tiles (measured along the heading) and
/// within [_laneTolerance] to the side makes the follower hold.
const double kFollowGap = 0.62;
const double _laneTolerance = 0.12;

/// A blocked car waits at most this long before driving on anyway, so a
/// packed ring can never freeze for good.
const double kMaxHold = 4;

/// Seconds a heading change cross-fades over (game layer reads
/// [Vehicle.fade] against this).
const double kHeadingFade = 0.12;

/// One car. Mutable: [stepVehicle] advances it in place.
class Vehicle {
  Vehicle({
    required this.col,
    required this.row,
    required this.dir,
    required this.speed,
    required this.kind,
    int? dirIn,
    this.t = 0,
  }) : dirIn = dirIn ?? dir {
    heading = vehiclePosition(this).heading;
  }

  int col;
  int row;

  /// Heading the car entered this tile with (index into
  /// [pedestrianDirDeltas]).
  int dirIn;

  /// Heading the car will leave this tile with.
  int dir;

  /// Progress along this tile's driving path, in `[0, 1)`.
  double t;

  /// Tiles per second (measured along the path).
  final double speed;

  /// Which sprite set the game draws it with, e.g. `hatchback`.
  final String kind;

  /// Screen heading currently shown, 0–7 (see [vehicleHeading]).
  late int heading;

  /// Heading shown before the last change, while [fade] < [kHeadingFade].
  int? prevHeading;

  /// Seconds since [heading] last changed.
  double fade = kHeadingFade;

  /// Seconds spent held behind another car (resets when moving).
  double held = 0;
}

/// Where a car is: fractional tile coordinates and its 8-way screen
/// heading.
typedef VehiclePosition = ({double col, double row, int heading});

/// Screen headings by index: 0 down-right (grid east, +col), 1 down,
/// 2 down-left (south, +row), 3 left, 4 up-left (west), 5 up, 6 up-right
/// (north), 7 right. Even indices are the four grid directions
/// (`heading = 2 * dir`); odd ones sit between them.
const int vehicleHeadings = 8;

/// Screen-space angle (radians, y down) of each heading: +col is (1, ½) on
/// screen and +row is (−1, ½).
final List<double> _headingAngles = List.generate(vehicleHeadings, (h) {
  final (dc, dr) = _headingTileVector(h);
  return math.atan2((dc + dr) / 2, (dc - dr).toDouble());
});

(int, int) _headingTileVector(int h) {
  final (ac, ar) = pedestrianDirDeltas[(h ~/ 2) % 4];
  if (h.isEven) return (ac, ar);
  final (bc, br) = pedestrianDirDeltas[(h ~/ 2 + 1) % 4];
  return (ac + bc, ar + br);
}

/// The heading whose screen angle is nearest the tile-space tangent
/// `(dCol, dRow)`.
int vehicleHeading(double dCol, double dRow) {
  final angle = math.atan2((dCol + dRow) / 2, dCol - dRow);
  var best = 0;
  var bestGap = double.infinity;
  for (var h = 0; h < vehicleHeadings; h++) {
    var gap = (angle - _headingAngles[h]).abs();
    if (gap > math.pi) gap = 2 * math.pi - gap;
    if (gap < bestGap) {
      bestGap = gap;
      best = h;
    }
  }
  return best;
}

/// The polyline a car follows across its current tile, as offsets from the
/// tile centre in tile units, always in the right-hand lane.
///
/// Straight through: the lane line from entry edge to exit edge. A bend:
/// the quarter circle centred on the tile corner between the two edges,
/// matching the curve sprites' annulus — radius `½ − lane` turning right
/// (inner lane), `½ + lane` turning left (outer). A dead end: in along the
/// lane, a half circle round the road's cap, and back out on the other
/// lane.
List<(double, double)> vehiclePath(Vehicle v) => vehiclePathFor(
  dirIn: v.dirIn,
  dir: v.dir,
  lane: kDrivingLane,
);

/// [vehiclePath] for an explicit entry / exit heading pair.
List<(double, double)> vehiclePathFor({
  required int dirIn,
  required int dir,
  required double lane,
}) {
  final (ic, ir) = pedestrianDirDeltas[dirIn];
  final (oc, or) = pedestrianDirDeltas[dir];
  final (cic, cir) = pedestrianDirDeltas[(dirIn + 1) % 4];
  final (coc, cor) = pedestrianDirDeltas[(dir + 1) % 4];
  final entry = (-0.5 * ic + lane * cic, -0.5 * ir + lane * cir);
  final exit = (0.5 * oc + lane * coc, 0.5 * or + lane * cor);
  if (dir == dirIn) return [entry, exit];
  if (dir == (dirIn + 2) % 4) {
    // Half circle of radius `lane` about the turnaround point, from the
    // entry lane to the exit lane, bulging past the point.
    final mc = _deadEndBack * ic;
    final mr = _deadEndBack * ir;
    return [
      entry,
      for (var i = 0; i <= _arcSegments; i++)
        () {
          final a = math.pi * i / _arcSegments;
          return (
            mc + lane * cic * math.cos(a) + lane * ic * math.sin(a),
            mr + lane * cir * math.cos(a) + lane * ir * math.sin(a),
          );
        }(),
      exit,
    ];
  }
  // Bend: arc from entry to exit about the corner between the two edges.
  final cc = -0.5 * ic + 0.5 * oc;
  final cr = -0.5 * ir + 0.5 * or;
  final (ec, er) = (entry.$1 - cc, entry.$2 - cr);
  final (xc, xr) = (exit.$1 - cc, exit.$2 - cr);
  return [
    for (var i = 0; i <= _arcSegments; i++)
      () {
        final a = math.pi / 2 * i / _arcSegments;
        final c = math.cos(a);
        final s = math.sin(a);
        return (cc + ec * c + xc * s, cr + er * c + xr * s);
      }(),
  ];
}

double _legLength((double, double) a, (double, double) b) {
  final dc = b.$1 - a.$1;
  final dr = b.$2 - a.$2;
  return math.sqrt(dc * dc + dr * dr);
}

/// Length of [vehiclePath] in tile units.
double vehiclePathLength(Vehicle v) => _pathLength(vehiclePath(v));

double _pathLength(List<(double, double)> pts) {
  var len = 0.0;
  for (var i = 1; i < pts.length; i++) {
    len += _legLength(pts[i - 1], pts[i]);
  }
  return len;
}

/// The car's position along its tile path at [Vehicle.t], with the heading
/// of the path segment it is on.
VehiclePosition vehiclePosition(Vehicle v) {
  final pts = vehiclePath(v);
  final total = _pathLength(pts);
  var remaining = v.t.clamp(0.0, 1.0) * total;
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1];
    final b = pts[i];
    final len = _legLength(a, b);
    if (remaining <= len || i == pts.length - 1) {
      final k = len == 0 ? 0.0 : (remaining / len).clamp(0.0, 1.0);
      return (
        col: v.col + a.$1 + (b.$1 - a.$1) * k,
        row: v.row + a.$2 + (b.$2 - a.$2) * k,
        heading: vehicleHeading(b.$1 - a.$1, b.$2 - a.$2),
      );
    }
    remaining -= len;
  }
  throw StateError('unreachable');
}

/// Painter's-order key for the board's depth sort: `col + row` of the car's
/// actual position.
double vehicleDepth(Vehicle v) {
  final pos = vehiclePosition(v);
  return pos.col + pos.row;
}

/// Whether [v] should hold because another car is just ahead in its lane:
/// within [kFollowGap] tiles along [v]'s heading and [_laneTolerance] to
/// the side. Cars on the opposite lane are two lane offsets away and never
/// count.
bool vehicleBlocked(Vehicle v, Iterable<Vehicle> others) {
  final pos = vehiclePosition(v);
  final (uc, ur) = _headingTileVector(pos.heading);
  final ul = math.sqrt((uc * uc + ur * ur).toDouble());
  final fc = uc / ul;
  final fr = ur / ul;
  for (final o in others) {
    if (identical(o, v)) continue;
    final op = vehiclePosition(o);
    final dc = op.col - pos.col;
    final dr = op.row - pos.row;
    final ahead = dc * fc + dr * fr;
    final side = (dc * fr - dr * fc).abs();
    if (ahead > 0.05 && ahead < kFollowGap && side < _laneTolerance) {
      return true;
    }
  }
  return false;
}

/// Advances [v] by [dt] seconds. A car held behind another ([blocked])
/// stays put, for at most [kMaxHold] seconds. Reaching the exit edge moves
/// the car to the next tile and picks a new direction: straight ahead by
/// preference, never a U-turn unless the tile is a dead end. The shown
/// [Vehicle.heading] follows the path tangent; a change starts a
/// cross-fade ([Vehicle.fade]).
void stepVehicle(
  Vehicle v,
  double dt, {
  required bool Function(int col, int row) isRoad,
  required math.Random random,
  bool blocked = false,
}) {
  v.fade += dt;
  if (blocked && v.held < kMaxHold) {
    v.held += dt;
    return;
  }
  v.held = 0;
  var distance = dt * v.speed;
  while (distance > 0) {
    final total = vehiclePathLength(v);
    final left = (1 - v.t) * total;
    if (distance < left) {
      v.t += distance / total;
      break;
    }
    distance -= left;
    final (dc, dr) = pedestrianDirDeltas[v.dir];
    final next = pickDirection(
      isRoad: isRoad,
      col: v.col + dc,
      row: v.row + dr,
      dir: v.dir,
      random: random,
      straightBias: 0.7,
    );
    v
      ..col += dc
      ..row += dr
      ..t = 0
      ..dirIn = v.dir
      ..dir = next;
  }
  final heading = vehiclePosition(v).heading;
  if (heading != v.heading) {
    v
      ..prevHeading = v.heading
      ..heading = heading
      ..fade = 0;
  }
}

/// A fresh car on a random tile of [roadTiles] (must be non-empty), driving
/// straight along a random road neighbour (or east on an isolated tile),
/// part-way along its path so a batch doesn't spawn in lock-step.
Vehicle spawnVehicle({
  required List<(int, int)> roadTiles,
  required bool Function(int col, int row) isRoad,
  required math.Random random,
  required String kind,
  required double speed,
}) {
  final (col, row) = roadTiles[random.nextInt(roadTiles.length)];
  final dirs = roadNeighbours(isRoad, col, row);
  return Vehicle(
    col: col,
    row: row,
    dir: dirs.isEmpty ? 0 : dirs[random.nextInt(dirs.length)],
    speed: speed,
    kind: kind,
    t: random.nextDouble(),
  );
}
