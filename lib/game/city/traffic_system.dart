import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:math_city/domain/city/street_life.dart';
import 'package:math_city/domain/city/traffic.dart';
import 'package:math_city/game/city/iso_grid.dart';

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
  final List<Vehicle> cars = [];
  Set<(int, int)> _roads = const {};
  List<(int, int)> _roadList = const [];
  List<String> _buildingIds = const [];

  bool _isRoad(int col, int row) => _roads.contains((col, row));

  /// Replaces the road set: cars whose tile is no longer road respawn.
  void setRoads(Set<(int, int)> roads) {
    _roads = roads;
    _roadList = roads.toList(growable: false);
    if (_roadList.isEmpty) {
      cars.clear();
      return;
    }
    for (var i = 0; i < cars.length; i++) {
      final v = cars[i];
      if (!_isRoad(v.col, v.row)) cars[i] = _spawn(v.kind);
    }
  }

  /// Brings the fleet to [plan]: gated kinds exactly as planned, civilian
  /// slots filled from the pool. Existing cars are kept where they still fit
  /// so a replan never makes traffic jump.
  void setFleet(StreetLifePlan plan, List<String> buildingIds) {
    _buildingIds = buildingIds;
    if (_roadList.isEmpty) {
      cars.clear();
      return;
    }
    // Drop gated cars over their count, then civilians over their slots.
    final keptGated = <String, int>{};
    var keptCivilians = 0;
    cars.retainWhere((v) {
      final kind = vehicleKindById(v.kind);
      if (kind.isGated) {
        final n = keptGated[v.kind] ?? 0;
        if (n >= (plan.gated[v.kind] ?? 0)) return false;
        keptGated[v.kind] = n + 1;
        return true;
      }
      if (keptCivilians >= plan.civilians) return false;
      keptCivilians++;
      return true;
    });
    for (final entry in plan.gated.entries) {
      for (var n = keptGated[entry.key] ?? 0; n < entry.value; n++) {
        cars.add(_spawn(entry.key));
      }
    }
    for (var n = keptCivilians; n < plan.civilians; n++) {
      cars.add(_spawn(drawCivilianKind(_random, _buildingIds).id));
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

  Vehicle _spawn(String kind) => spawnVehicle(
    roadTiles: _roadList,
    isRoad: _isRoad,
    random: _random,
    kind: kind,
    speed: (0.45 + _random.nextDouble() * 0.2) * vehicleKindById(kind).speed,
  );

  /// Where each car's ground centre is on the board, in [grid] local space,
  /// with its fractional tile position (the board derives the sort key from
  /// it, see `mover_depth.dart`) and its ground footprint for the shadow.
  Iterable<VehicleView> views(IsoGrid grid) sync* {
    for (final v in cars) {
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
      yield VehicleView(
        vehicle: v,
        centre: Offset(x, y),
        col: pos.col,
        row: pos.row,
        shadow: shadow,
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
    required this.col,
    required this.row,
    required this.shadow,
  });

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
