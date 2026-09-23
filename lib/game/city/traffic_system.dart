import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:math_city/domain/city/traffic.dart';
import 'package:math_city/game/city/iso_grid.dart';

/// Owns the cars on the city's auto-roads (ideas A1/A2): spawns a fleet
/// sized to the road network, steps them each frame, and hands the board
/// what to paint, depth-keyed so a car slots into the building sort.
///
/// Roads live in **window-local** tile coords (see `LandWindow`); when the
/// window grows the board calls [shift] with the local-origin delta so the
/// fleet stays where it was on screen.
class TrafficSystem {
  TrafficSystem({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;
  final List<Vehicle> cars = [];
  Set<(int, int)> _roads = const {};
  List<(int, int)> _roadList = const [];

  /// Cars per road tile: the 8-tile starter ring gets one, a 60-tile city
  /// seven, capped so traffic never becomes a jam.
  static const double perRoadTile = 0.12;
  static const int maxCars = 12;

  /// Sprite sets available; each is eight `<kind>_h<0..7>.png` files under
  /// `assets/vehicles/`.
  static const List<String> kinds = ['hatchback'];

  bool _isRoad(int col, int row) => _roads.contains((col, row));

  /// Replaces the road set: cars whose tile is no longer road respawn, and
  /// the fleet grows or shrinks to the new target size.
  void setRoads(Set<(int, int)> roads) {
    _roads = roads;
    _roadList = roads.toList(growable: false);
    if (_roadList.isEmpty) {
      cars.clear();
      return;
    }
    for (var i = 0; i < cars.length; i++) {
      final v = cars[i];
      if (!_isRoad(v.col, v.row)) cars[i] = _spawn();
    }
    final target = math.min(
      maxCars,
      math.max(1, (_roadList.length * perRoadTile).round()),
    );
    while (cars.length > target) {
      cars.removeLast();
    }
    while (cars.length < target) {
      cars.add(_spawn());
    }
  }

  /// Moves every car by `(dCol, dRow)` tiles — the local-origin shift when
  /// the land window grows.
  void shift(int dCol, int dRow) {
    if (dCol == 0 && dRow == 0) return;
    for (final v in cars) {
      v
        ..col += dCol
        ..row += dRow;
    }
  }

  void update(double dt) {
    if (_roadList.isEmpty) return;
    for (final v in cars) {
      stepVehicle(
        v,
        dt,
        isRoad: _isRoad,
        random: _random,
        blocked: vehicleBlocked(v, cars),
      );
    }
  }

  Vehicle _spawn() => spawnVehicle(
    roadTiles: _roadList,
    isRoad: _isRoad,
    random: _random,
    kind: kinds[_random.nextInt(kinds.length)],
    speed: 0.45 + _random.nextDouble() * 0.2,
  );

  /// Where each car's ground centre is on the board, in [grid] local space,
  /// with the painter's-order key the board sorts on.
  Iterable<VehicleView> views(IsoGrid grid) sync* {
    for (final v in cars) {
      final pos = vehiclePosition(v);
      final (x, y) = grid.pointAt(pos.col, pos.row);
      yield VehicleView(
        vehicle: v,
        centre: Offset(x, y),
        depth: pos.col + pos.row,
      );
    }
  }
}

/// Sprite file for a car kind facing a heading, relative to
/// `assets/vehicles/`.
String vehicleSpriteFile(String kind, int heading) => '${kind}_h$heading.png';

/// One car resolved to board space for painting.
class VehicleView {
  const VehicleView({
    required this.vehicle,
    required this.centre,
    required this.depth,
  });

  final Vehicle vehicle;
  final Offset centre;
  final double depth;

  static final Paint _shadow = Paint()..color = const Color(0x40000000);

  /// Draws the ground shadow and the heading sprite (cross-fading from the
  /// previous heading just after a change). [spriteFor] resolves a file
  /// under `assets/vehicles/`; a missing sprite just skips the frame.
  /// [scale] is board px per authoring px (tile width / 192).
  void paint(
    Canvas canvas,
    double scale,
    Sprite? Function(String file) spriteFor,
  ) {
    final tile = scale * 192;
    canvas.drawOval(
      Rect.fromCenter(
        center: centre.translate(tile * 0.015, tile * 0.03),
        width: tile * 0.42,
        height: tile * 0.21,
      ),
      _shadow,
    );
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
