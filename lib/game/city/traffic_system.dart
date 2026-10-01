import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:math_city/domain/city/pedestrian_walk.dart'
    show pedestrianDirDeltas;
import 'package:math_city/domain/city/street_life.dart';
import 'package:math_city/domain/city/traffic.dart';
import 'package:math_city/game/city/iso_grid.dart';
import 'package:math_city/game/city/pedestrian_system.dart' show kMoverFade;

/// Owns the cars on the city's auto-roads (ideas A1/A2): keeps the fleet the
/// street-life plan asks for, steps it each frame, and hands the board what
/// to paint.
///
/// Roads live in **window-local** tile coords (see `LandWindow`); when the
/// window grows the board calls [shift] with the local-origin delta so the
/// fleet stays where it was on screen.
class TrafficSystem {
  TrafficSystem({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  /// The town's fleet (the street-life plan).
  final List<Vehicle> cars = [];

  /// Through traffic: cars that drive in from an edge of the map, through
  /// town, and out again ([kCommutersPerExit] per road out of town).
  final List<Vehicle> commuters = [];

  /// Every car on the road, for blocking and painting.
  Iterable<Vehicle> get allCars => cars.followedBy(commuters);

  /// Cars fading in after joining and fading out after leaving, so the
  /// fleet follows the time of day without popping.
  final Map<Vehicle, double> _appearing = {};
  final List<(Vehicle, double)> _leaving = [];

  /// How far down its road in a seeded commuter may start, in tiles: the
  /// run past the window plus most of the way across it.
  static const int _kSeedReach = 60;

  /// Through traffic per road out of town; follows the hour.
  int _commutersPerExit = kCommutersPerExit;

  void setCommutersPerExit(int n) {
    if (n == _commutersPerExit) return;
    _commutersPerExit = n;
    _syncCommuters();
  }

  void _syncCommuters() {
    final want = _exits.length * _commutersPerExit;
    while (commuters.length > want) {
      _leaving.add((commuters.removeLast(), kMoverFade));
    }
    // A newcomer starts somewhere along its road in, fading in, so the
    // through traffic is there from the first second rather than a minute
    // later; replacements for cars that left come in at the edge.
    while (commuters.length < want) {
      final v = _spawnCommuter(alongTheWay: true);
      _appearing[v] = 0;
      commuters.add(v);
    }
  }

  Set<(int, int)> _roads = const {};
  Set<(int, int)> _townRoads = const {};
  Set<(int, int)> _throughRoads = const {};
  List<HighwayExit> _exits = const [];
  List<(int, int)> _roadList = const [];
  List<(int, int)> _townRoadList = const [];
  List<String> _buildingIds = const [];
  int _population = 0;

  bool _isRoad(int col, int row) => _roads.contains((col, row));
  bool _isTownRoad(int col, int row) => _townRoads.contains((col, row));
  bool _isThroughRoad(int col, int row) => _throughRoads.contains((col, row));

  /// The road predicate a car drives on: town-only kinds never cross the
  /// fence, the rest use every road of the window.
  bool Function(int, int) _predicateFor(Vehicle v) =>
      vehicleKindById(v.kind).leavesTown ? _isRoad : _isTownRoad;

  /// Replaces the road sets: [roads] is every road tile of the window,
  /// [townRoads] the ones inside the fence (where town-only kinds and
  /// the walkers stay), [throughRoads] the window's roads plus the
  /// highway on past it to [exits], where the through traffic enters and
  /// leaves. Cars whose tile is no longer road for them respawn.
  void setRoads(
    Set<(int, int)> roads, {
    Set<(int, int)>? townRoads,
    Set<(int, int)>? throughRoads,
    List<HighwayExit> exits = const [],
  }) {
    _roads = roads;
    _townRoads = townRoads ?? roads;
    _throughRoads = throughRoads ?? roads;
    _exits = exits;
    _roadList = roads.toList(growable: false);
    _townRoadList = _townRoads.toList(growable: false);
    if (_roadList.isEmpty) {
      cars.clear();
      commuters.clear();
      return;
    }
    for (var i = 0; i < cars.length; i++) {
      final v = cars[i];
      if (!_predicateFor(v)(v.col, v.row)) cars[i] = _spawn(v.kind);
    }
    commuters.retainWhere((v) => _isThroughRoad(v.col, v.row));
    _syncCommuters();
  }

  /// A commuter at a random exit, driving into town, part-way along the
  /// edge tile so a batch never arrives in lock-step. [alongTheWay] starts
  /// it a random distance down that road instead of at the very edge.
  Vehicle _spawnCommuter({bool alongTheWay = false}) {
    final exit = _exits[_random.nextInt(_exits.length)];
    final kind = drawCommuterKind(_random);
    var col = exit.col;
    var row = exit.row;
    if (alongTheWay) {
      final (dc, dr) = pedestrianDirDeltas[exit.inbound];
      final steps = _random.nextInt(_kSeedReach);
      for (var i = 0; i < steps; i++) {
        if (!_isThroughRoad(col + dc, row + dr)) break;
        col += dc;
        row += dr;
      }
    }
    return Vehicle(
      col: col,
      row: row,
      dir: exit.inbound,
      speed: (0.45 + _random.nextDouble() * 0.2) * kind.speed,
      kind: kind.id,
      t: _random.nextDouble(),
    );
  }

  /// Brings the fleet to [plan]: gated kinds exactly as planned, civilian
  /// slots filled from the pool. Existing cars are kept where they still fit
  /// so a replan never makes traffic jump.
  void setFleet(
    StreetLifePlan plan, {
    required List<String> buildingIds,
    required int population,
  }) {
    _buildingIds = buildingIds;
    _population = population;
    if (_roadList.isEmpty) {
      cars.clear();
      return;
    }
    // Drop gated cars over their count, then civilians over their slots.
    final keptGated = <String, int>{};
    var keptCivilians = 0;
    cars.retainWhere((v) {
      final kind = vehicleKindById(v.kind);
      var keep = true;
      if (kind.isGated) {
        final n = keptGated[v.kind] ?? 0;
        keep = n < (plan.gated[v.kind] ?? 0);
        if (keep) keptGated[v.kind] = n + 1;
      } else {
        keep = keptCivilians < plan.civilians;
        if (keep) keptCivilians++;
      }
      if (!keep) _leaving.add((v, kMoverFade));
      return keep;
    });
    void join(String kind) {
      final v = _spawn(kind);
      _appearing[v] = 0;
      cars.add(v);
    }

    for (final entry in plan.gated.entries) {
      for (var n = keptGated[entry.key] ?? 0; n < entry.value; n++) {
        join(entry.key);
      }
    }
    for (var n = keptCivilians; n < plan.civilians; n++) {
      join(
        drawCivilianKind(
          _random,
          _buildingIds,
          population: _population,
        ).id,
      );
    }
  }

  /// Moves every car by `(dCol, dRow)` tiles — the local-origin shift when
  /// the land window grows.
  void shift(int dCol, int dRow) {
    if (dCol == 0 && dRow == 0) return;
    for (final v in allCars.followedBy(_leaving.map((l) => l.$1))) {
      v
        ..col += dCol
        ..row += dRow;
    }
  }

  /// Steps every car. [walkers] are the pedestrians' tile positions this
  /// frame: a car holds for one stepping across its path.
  void update(
    double dt, {
    Iterable<({double col, double row})> walkers = const [],
  }) {
    _appearing
      ..updateAll((_, age) => age + dt)
      ..removeWhere((_, age) => age >= kMoverFade);
    for (var i = _leaving.length - 1; i >= 0; i--) {
      final (v, left) = _leaving[i];
      if (left - dt <= 0) {
        _leaving.removeAt(i);
      } else {
        _leaving[i] = (v, left - dt);
      }
    }
    if (_roadList.isEmpty) return;
    final all = allCars.toList(growable: false);
    for (final v in cars) {
      stepVehicle(
        v,
        dt,
        isRoad: _predicateFor(v),
        random: _random,
        blocked: vehicleBlocked(v, all) || vehicleBlockedByWalker(v, walkers),
      );
    }
    for (var i = 0; i < commuters.length; i++) {
      final v = commuters[i];
      final from = (v.col, v.row);
      stepVehicle(
        v,
        dt,
        isRoad: _isThroughRoad,
        random: _random,
        blocked: vehicleBlocked(v, all) || vehicleBlockedByWalker(v, walkers),
      );
      // Reaching an exit (not the one it just spawned on) means it has
      // left town: a fresh car comes in somewhere else.
      final atExit = _exits.any((e) => e.col == v.col && e.row == v.row);
      if (atExit && from != (v.col, v.row)) commuters[i] = _spawnCommuter();
    }
  }

  Vehicle _spawn(String kind) {
    final town = !vehicleKindById(kind).leavesTown && _townRoadList.isNotEmpty;
    return spawnVehicle(
      roadTiles: town ? _townRoadList : _roadList,
      isRoad: town ? _isTownRoad : _isRoad,
      random: _random,
      kind: kind,
      speed: (0.45 + _random.nextDouble() * 0.2) * vehicleKindById(kind).speed,
    );
  }

  /// Where each car's ground centre is on the board, in [grid] local space,
  /// with its fractional tile position (the board derives the sort key from
  /// it, see `mover_depth.dart`) and its ground footprint for the shadow.
  Iterable<VehicleView> views(IsoGrid grid) sync* {
    for (final v in allCars) {
      yield _view(grid, v, (_appearing[v] ?? kMoverFade) / kMoverFade);
    }
    for (final (v, left) in _leaving) {
      yield _view(grid, v, left / kMoverFade);
    }
  }

  VehicleView _view(IsoGrid grid, Vehicle v, double opacity) {
    {
      final pos = vehiclePosition(v);
      final (x, y) = grid.pointAt(pos.col, pos.row);
      final kind = vehicleKindById(v.kind);
      final shadow = Path();
      final quad = vehicleFootprint(v.heading, kind.length, kind.width);
      for (var i = 0; i < quad.length; i++) {
        final (qx, qy) = grid.pointAt(
          pos.col + quad[i].$1,
          pos.row + quad[i].$2,
        );
        if (i == 0) {
          shadow.moveTo(qx, qy);
        } else {
          shadow.lineTo(qx, qy);
        }
      }
      shadow.close();
      return VehicleView(
        vehicle: v,
        centre: Offset(x, y),
        col: pos.col,
        row: pos.row,
        shadow: shadow,
        opacity: opacity.clamp(0.0, 1.0),
      );
    }
  }
}

/// Where a road out of town meets the edge of the map (window-local tile)
/// and the direction a car drives to come in from it.
class HighwayExit {
  const HighwayExit({
    required this.col,
    required this.row,
    required this.inbound,
  });

  final int col;
  final int row;
  final int inbound;
}

/// Sprite file for a car kind facing a heading, relative to
/// `assets/vehicles/`.
String vehicleSpriteFile(String kind, int heading) => '${kind}_h$heading.png';

/// One car resolved to board space for painting.
class VehicleView {
  const VehicleView({
    required this.vehicle,
    required this.centre,
    required this.col,
    required this.row,
    required this.shadow,
    this.opacity = 1,
  });

  /// `1` normally; below it while fading in or out.
  final double opacity;

  final Vehicle vehicle;
  final Offset centre;
  final double col;
  final double row;

  /// The car's ground footprint on the board, drawn as its contact shadow.
  final Path shadow;

  static final Paint _shadowPaint = Paint()..color = const Color(0x38000000);

  /// Draws the ground shadow and the heading sprite (cross-fading from the
  /// previous heading just after a change). [spriteFor] resolves a file
  /// under `assets/vehicles/`; a missing sprite just skips the frame.
  /// [scale] is board px per authoring px (tile width / 192).
  void paint(
    Canvas canvas,
    double scale,
    Sprite? Function(String file) spriteFor,
  ) {
    canvas.drawPath(shadow, _shadowPaint);
    final v = vehicle;
    final k = (v.fade / kHeadingFade).clamp(0.0, 1.0);
    if (k < 1 && v.prevHeading != null) {
      _drawHeading(canvas, scale, spriteFor, v.prevHeading!, 1 - k);
    }
    _drawHeading(canvas, scale, spriteFor, v.heading, k);
  }

  void _drawHeading(
    Canvas canvas,
    double scale,
    Sprite? Function(String file) spriteFor,
    int heading,
    double opacity,
  ) {
    final sprite = spriteFor(vehicleSpriteFile(vehicle.kind, heading));
    if (sprite == null) return;
    sprite.render(
      canvas,
      position: Vector2(centre.dx, centre.dy),
      size: sprite.srcSize * scale,
      anchor: Anchor.center,
      overridePaint: opacity < 1
          ? (Paint()..color = Color.fromRGBO(255, 255, 255, opacity))
          : null,
    );
  }
}
