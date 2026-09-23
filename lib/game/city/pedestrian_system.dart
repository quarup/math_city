import 'dart:math' as math;
import 'dart:ui';

import 'package:math_city/domain/city/pedestrian_walk.dart';
import 'package:math_city/game/city/citizen_painter.dart';
import 'package:math_city/game/city/iso_grid.dart';

/// Sidewalk offset from the road centre line, in world px at the 64 px tile,
/// measured along the cross iso axis (city_builder.md §9.3): the straight
/// road sprite's beige band spans 8.9–14.3 px perpendicular to the road, and
/// the cross axis is not perpendicular (|cross| = 0.8), so 14.5 along it puts
/// the feet on the band's centre. 12 put them on the kerb.
const double kSidewalkLane = 14.5;

/// Owns the walkers on the city's auto-roads (idea B1): spawns a crowd sized
/// to the road network, steps them each frame, and hands the board what to
/// paint, depth-keyed so a walker slots into the building sort.
///
/// Roads live in **window-local** tile coords (see `LandWindow`); when the
/// window grows the board calls [shift] with the local-origin delta so the
/// crowd stays where it was on screen.
class PedestrianSystem {
  PedestrianSystem({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;
  final List<Pedestrian> people = [];
  Set<(int, int)> _roads = const {};
  List<(int, int)> _roadList = const [];

  /// Walkers per road tile; a fresh 8-tile ring gets two, a 60-tile city
  /// fifteen, capped so a sprawling town never becomes a parade.
  static const double perRoadTile = 0.25;
  static const int maxPeople = 24;

  bool _isRoad(int col, int row) => _roads.contains((col, row));

  /// Replaces the road set: walkers whose tile is no longer road respawn,
  /// and the crowd grows or shrinks to the new target size.
  void setRoads(Set<(int, int)> roads) {
    _roads = roads;
    _roadList = roads.toList(growable: false);
    if (_roadList.isEmpty) {
      people.clear();
      return;
    }
    for (var i = 0; i < people.length; i++) {
      final p = people[i];
      if (!_isRoad(p.col, p.row)) people[i] = _spawn();
    }
    final target = math.min(
      maxPeople,
      (_roadList.length * perRoadTile).round(),
    );
    while (people.length > target) {
      people.removeLast();
    }
    while (people.length < target) {
      people.add(_spawn());
    }
  }

  /// Moves every walker by `(dCol, dRow)` tiles — the local-origin shift when
  /// the land window grows. Runs before or after the matching [setRoads]
  /// depending on the caller; either order ends with every walker on a road.
  void shift(int dCol, int dRow) {
    if (dCol == 0 && dRow == 0) return;
    for (final p in people) {
      p
        ..col += dCol
        ..row += dRow;
    }
  }

  void update(double dt) {
    if (_roadList.isEmpty) return;
    for (final p in people) {
      stepPedestrian(p, dt, isRoad: _isRoad, random: _random);
    }
  }

  Pedestrian _spawn() {
    // Three ages: kids small with big heads and quick steps, elders a little
    // shorter, grey and slow, adults in between (city_builder.md §9.3).
    final roll = _random.nextDouble();
    final CitizenLook look;
    final double speed;
    if (roll < 0.25) {
      look = _look(scale: 0.62, headScale: 1.35);
      speed = 0.16 * 1.4;
    } else if (roll < 0.4) {
      look = _look(scale: 0.9, hair: 0xFFD0D0D0);
      speed = 0.16 * 0.6;
    } else {
      look = _look();
      speed = 0.16 * (0.9 + _random.nextDouble() * 0.2);
    }
    return spawnPedestrian(
      roadTiles: _roadList,
      isRoad: _isRoad,
      random: _random,
      look: look,
      speed: speed,
      lane: _random.nextBool() ? kSidewalkLane : -kSidewalkLane,
    );
  }

  CitizenLook _look({double scale = 1, double headScale = 1, int? hair}) =>
      CitizenLook(
        shirt: _pick(citizenShirts),
        pants: _pick(citizenPants),
        skin: _pick(citizenSkins),
        hair: hair ?? _pick(citizenHairs),
        scale: scale,
        headScale: headScale,
      );

  int _pick(List<int> from) => from[_random.nextInt(from.length)];

  /// Where each walker's feet are on the board, in [grid] local space, with
  /// the painter's-order key the board sorts on.
  Iterable<PedestrianView> views(IsoGrid grid) sync* {
    final hw = grid.tileWidth / 2;
    final hh = grid.tileWidth / 4;
    final laneScale = grid.tileWidth / 64;
    for (final p in people) {
      final (cx, cy) = grid.centerOf(p.col, p.row);
      final (dc, dr) = pedestrianDirDeltas[p.dir];
      final (sc, sr) = pedestrianDirDeltas[(p.dir + 1) % 4];
      // Cross iso axis (the walker's right-hand side), unit length.
      final sx = (sc - sr) * hw;
      final sy = (sc + sr) * hh;
      final sl = math.sqrt(sx * sx + sy * sy);
      final lane = p.lane * laneScale;
      yield PedestrianView(
        pedestrian: p,
        feet: Offset(
          cx + (dc - dr) * hw * p.t + sx / sl * lane,
          cy + (dc + dr) * hh * p.t + sy / sl * lane,
        ),
        depth: p.depth,
      );
    }
  }
}

/// One walker resolved to board space for painting.
class PedestrianView {
  const PedestrianView({
    required this.pedestrian,
    required this.feet,
    required this.depth,
  });

  final Pedestrian pedestrian;
  final Offset feet;
  final double depth;

  void paint(Canvas canvas, double scale) => paintCitizen(
    canvas,
    feet: feet,
    dir: pedestrian.dir,
    phase: pedestrian.phase,
    look: pedestrian.look,
    idle: pedestrian.isWaiting,
    scale: scale,
  );
}
