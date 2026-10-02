import 'dart:typed_data';
import 'dart:ui';

import 'package:math_city/domain/city/street_lamps.dart';
import 'package:math_city/domain/city/street_life.dart';
import 'package:math_city/domain/city/traffic.dart';
import 'package:math_city/game/city/iso_grid.dart';

/// Lights that are drawn rather than baked (city_builder.md §12): a car's
/// headlights and tail lamps (H3) and the street lanterns (L3). All sizes
/// are the mocks' pixels at a 64 px tile, scaled to the live tile width.
///
/// Light lies **on the ground**: a beam and a lamp's pool are shapes in
/// tile space, so they foreshorten with the projection. They go on the
/// board's light layer, where the building in front hides them.

const _beamColor = Color(0xFFFFF0C4);
const _amber = Color(0xFFFFBE6E);
const _post = Color(0xFF2D3338);

/// Headlights and tail lamps of one car at fractional tile `(col, row)`
/// facing [heading]: one soft beam on the road ahead, two points at the
/// nose when it faces the viewer, two red points when it drives away.
/// [level] is how much the lights show, `0..1`.
void paintVehicleLights(
  Canvas canvas, {
  required IsoGrid grid,
  required double col,
  required double row,
  required int heading,
  required VehicleKind kind,
  required double level,
}) {
  if (level <= 0.02) return;
  final k = grid.tileWidth / 64;
  final (fc, fr) = vehicleHeadingVector(heading);
  // Right-hand perpendicular: east (1, 0) → south (0, 1).
  final (sc, sr) = (-fr, fc);
  // A point on the car: [a] tiles forward, [b] to its right, [z] px up.
  Offset at(double a, double b, [double z = 0]) {
    final (x, y) = grid.pointAt(col + fc * a + sc * b, row + fr * a + sr * b);
    return Offset(x, y - z * k);
  }

  final half = kind.length / 2;
  final width = kind.width;

  // The beam: as wide as the bumper at the nose, fanning to about a third
  // of a tile nearly a tile ahead; brightest at the car, gone at the end.
  const reach = 0.95;
  final start = at(half, 0);
  final end = at(half + reach, 0);
  final beam = Path()
    ..addPolygon([
      at(half, -width * 0.42),
      at(half, width * 0.42),
      at(half + reach, 0.36),
      at(half + reach, -0.36),
    ], true);
  canvas.drawPath(
    beam,
    Paint()
      ..shader = Gradient.linear(
        start,
        end,
        [
          _beamColor.withValues(alpha: 0.5 * level),
          _beamColor.withValues(alpha: 0.21 * level),
          _beamColor.withValues(alpha: 0),
        ],
        const [0, 0.55, 1],
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.4 * k),
  );

  // The lamps themselves. The nose points down-screen when the heading's
  // tile vector has a positive col + row.
  final facing = fc + fr > 0.01;
  final away = fc + fr < -0.01;
  void lamp(Offset p, double r, Color core, Color halo, double haloR) {
    canvas
      ..drawCircle(
        p,
        haloR * k,
        Paint()
          ..shader = Gradient.radial(p, haloR * k, [
            halo.withValues(alpha: halo.a * level),
            halo.withValues(alpha: 0),
          ]),
      )
      ..drawCircle(p, r * k, Paint()..color = core.withValues(alpha: level));
  }

  if (facing) {
    for (final side in const [-1.0, 1.0]) {
      lamp(
        at(half - 0.02, side * width * 0.32, 3.2),
        1.25,
        const Color(0xFFFFFBE6),
        const Color(0xD9FFF4C8),
        3.6,
      );
    }
  } else if (away) {
    for (final side in const [-1.0, 1.0]) {
      lamp(
        at(-half + 0.02, side * width * 0.34, 3.4),
        1.1,
        const Color(0xFFE0241C),
        const Color(0x99FF3228),
        3,
      );
    }
  }
}

/// The ground point a lamp stands on, in board space.
Offset lampBase(IsoGrid grid, LampSpot spot) {
  final (x, y) = grid.pointAt(spot.col + spot.de, spot.row + spot.ds);
  return Offset(x, y);
}

/// The lantern post (L3): a slim dark post with a crossbar, a caged lamp
/// and a pointed cap. Drawn with the town, by day and by night; [on]
/// decides only the colour of its glass.
void paintLampPost(Canvas canvas, Offset base, double tileWidth, double on) {
  final k = tileWidth / 64;
  final x = base.dx;
  final y = base.dy;
  final dark = Paint()..color = _post;
  final line = Paint()
    ..color = _post
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final cage = Path()
    ..moveTo(x - 1.6 * k, y - 16.5 * k)
    ..lineTo(x + 1.6 * k, y - 16.5 * k)
    ..lineTo(x + 2.5 * k, y - 21.4 * k)
    ..lineTo(x - 2.5 * k, y - 21.4 * k)
    ..close();
  final cap = Path()
    ..moveTo(x - 3.1 * k, y - 21.4 * k)
    ..lineTo(x + 3.1 * k, y - 21.4 * k)
    ..lineTo(x, y - 24.4 * k)
    ..close();
  canvas
    ..drawRect(Rect.fromLTWH(x - 1.7 * k, y - 3 * k, 3.4 * k, 3 * k), dark)
    ..drawLine(
      Offset(x, y),
      Offset(x, y - 16.5 * k),
      line..strokeWidth = 1.4 * k,
    )
    ..drawLine(
      Offset(x - 2.6 * k, y - 14.6 * k),
      Offset(x + 2.6 * k, y - 14.6 * k),
      line..strokeWidth = k,
    )
    ..drawPath(
      cage,
      Paint()
        ..color = on > 0.5 ? const Color(0xFFFFF3C4) : const Color(0xFFAAB2B9),
    )
    ..drawPath(cage, line..strokeWidth = 0.7 * k)
    ..drawPath(cap, dark)
    ..drawRect(
      Rect.fromLTWH(x - 0.5 * k, y - 25.6 * k, k, 1.4 * k),
      dark,
    );
}

/// The lantern's light: an amber pool lying on the pavement, and a tight
/// halo round the lamp. [on] is the lamp's own level (with its flicker as
/// it comes up), already scaled by how dark the scene is.
void paintLampLight(
  Canvas canvas, {
  required IsoGrid grid,
  required LampSpot spot,
  required double on,
}) {
  if (on <= 0.01) return;
  final k = grid.tileWidth / 64;
  final halfW = grid.tileWidth / 2;
  final halfH = grid.tileWidth / 4;
  // The pool sits a little towards the road from the post, four tenths of
  // a tile along the street and a third across it.
  final (px, py) = grid.pointAt(
    spot.col + spot.de * 0.8,
    spot.row + spot.ds * 0.8,
  );
  const along = 0.4;
  const across = 0.32;
  final rE = spot.alongEast ? along : across;
  final rS = spot.alongEast ? across : along;
  final alpha = 0.55 * on;
  // Tile space → board: east is (halfW, halfH), south is (−halfW, halfH).
  final toBoard = Float64List(16)
    ..[0] = halfW
    ..[1] = halfH
    ..[4] = -halfW
    ..[5] = halfH
    ..[10] = 1
    ..[12] = px
    ..[13] = py
    ..[15] = 1;
  canvas
    ..save()
    ..transform(toBoard)
    ..scale(rE, rS)
    ..drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = Gradient.radial(
          Offset.zero,
          1,
          [
            _amber.withValues(alpha: alpha),
            _amber.withValues(alpha: alpha * 0.5),
            _amber.withValues(alpha: 0),
          ],
          const [0, 0.45, 1],
        ),
    )
    ..restore();
  final base = lampBase(grid, spot);
  final head = Offset(base.dx, base.dy - 19 * k);
  canvas
    ..drawCircle(
      head,
      7 * k,
      Paint()
        ..shader = Gradient.radial(
          head,
          7 * k,
          [
            _amber.withValues(alpha: 0.95 * on),
            _amber.withValues(alpha: 0.33 * on),
            _amber.withValues(alpha: 0),
          ],
          const [0, 0.35, 1],
        ),
    )
    ..drawCircle(
      head,
      1.5 * k,
      Paint()..color = const Color(0xFFFFFCEC).withValues(alpha: on),
    );
}
