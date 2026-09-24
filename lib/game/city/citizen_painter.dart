import 'dart:math' as math;
import 'dart:ui';

import 'package:math_city/domain/city/pedestrian_walk.dart';

/// Paints one code-drawn citizen — the "P02 toy chibi" settled in
/// city_builder.md §9.3: 15 px tall at the 64 px tile, head a fifth of the
/// height, jointed legs with a knee that bends on the swinging leg and a heel
/// lift, two-segment arms with round hands, ink outline on torso and head,
/// dot eyes facing the camera and a hair dome from behind.
///
/// A straight port of `drawPed` in `tools/city_mocks/ped.js` with the chosen
/// style baked in. Draw order is the part that took two review rounds: the
/// limbs on the side of the body facing *away* from the camera go down
/// first, behind both the legs and the torso; the near limbs come after.
///
/// [feet] is the point on the ground between the shoes, in the same
/// coordinate space the canvas is in; [scale] multiplies every size (1 =
/// the 64 px tile), [dir] is the grid heading (0 east … 3 north, see
/// [pedestrianDirDeltas]), [phase] the walk cycle in radians.
void paintCitizen(
  Canvas canvas, {
  required Offset feet,
  required int dir,
  required double phase,
  required CitizenLook look,
  bool idle = false,
  double scale = 1,
}) {
  final u = _unit[dir];
  final fx = u.dx >= 0 ? 1.0 : -1.0; // screen-x facing
  final front = u.dy > 0; // walking toward the viewer: face visible
  // The figure's right-hand side in screen space; it sits at screen-x
  // sign(sv.x) and is nearer the camera when sv.y > 0.
  final sv = _unit[(dir + 1) % 4];
  final nearSide = sv.dx * sv.dy > 0 ? 1.0 : -1.0;
  final farSide = -nearSide;

  final k = scale * look.scale * kCitizenSize;
  final h = _height * k;
  final headR = h * _headRatio * look.headScale;
  final legL = h * _legRatio;
  final bodyW = h * _bodyWidthRatio;
  final bodyH = math.max(2 * k, h - legL - 2 * h * _headRatio);
  final moving = !idle;
  final sw = moving ? math.sin(phase) : 0.0;
  final bob = moving ? math.cos(phase).abs() * _bobRatio * h : 0.0;
  final stride = h * _strideRatio;
  final x = feet.dx;
  final y = feet.dy;
  final hipY = y - legL - bob;
  final shY = hipY - bodyH;
  final headCY = shY - headR;

  final ink = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = _inkWidth * k;
  final fill = Paint()..style = PaintingStyle.fill;

  // Shadow.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(x, y + 0.5 * k),
      width: bodyW * 1.5,
      height: bodyW * 0.64,
    ),
    fill..color = const Color(0x40000000),
  );

  // ---- limbs -----------------------------------------------------------
  final legW = _legWidth * k;
  final armW = bodyW * 0.24;
  final armL = bodyH * 0.9;
  final pants = Paint()
    ..color = Color(look.pants)
    ..style = PaintingStyle.stroke
    ..strokeWidth = legW
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final sleeve = Paint()
    ..color = Color(look.shirt)
    ..style = PaintingStyle.stroke
    ..strokeWidth = armW
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final skin = Paint()..color = Color(look.skin);

  void leg(double i) {
    final hipX = x + i * bodyW * 0.22;
    final s = sw * i;
    final footX = hipX + s * stride * fx;
    final lift = moving ? math.max(0, math.cos(phase) * i) * h * 0.1 : 0.0;
    final footY = y - lift;
    final kneeX = (hipX + footX) / 2 + fx * (lift * 0.9 + 0.6 * k);
    final kneeY = (hipY + footY) / 2;
    canvas
      ..drawPath(
        Path()
          ..moveTo(hipX, hipY)
          ..lineTo(kneeX, kneeY)
          ..lineTo(footX, footY),
        pants,
      )
      ..drawOval(
        Rect.fromCenter(
          center: Offset(footX + fx * 1.2 * k, footY),
          width: 4.8 * k,
          height: 2.4 * k,
        ),
        fill..color = _ink,
      );
  }

  void arm(double i) {
    final s = moving ? -sw * i : 0.0;
    final ax0 = x + i * bodyW * 0.5;
    final ay0 = shY + bodyW * 0.2;
    final ax1 = ax0 + s * stride * 0.7 * fx + i * 0.6 * k;
    final ay1 = ay0 + armL;
    final ex = (ax0 + ax1) / 2 - fx * 0.8 * k * (s > 0 ? 1 : 0.3);
    final ey = (ay0 + ay1) / 2;
    canvas
      ..drawPath(
        Path()
          ..moveTo(ax0, ay0)
          ..lineTo(ex, ey)
          ..lineTo(ax1, ay1),
        sleeve,
      )
      ..drawCircle(Offset(ax1, ay1), armW * 0.55, skin);
  }

  arm(farSide);
  leg(farSide);
  leg(nearSide);

  // ---- torso -----------------------------------------------------------
  final torso = RRect.fromRectAndRadius(
    Rect.fromLTWH(x - bodyW / 2, shY, bodyW, bodyH + bodyW * 0.15),
    Radius.circular(bodyW * 0.45),
  );
  canvas
    ..drawRRect(torso, fill..color = Color(look.shirt))
    ..drawRRect(torso, ink);

  arm(nearSide);

  // ---- head ------------------------------------------------------------
  final head = Offset(x, headCY);
  canvas
    ..drawCircle(head, headR, skin)
    ..drawCircle(head, headR, ink);
  final hair = Path();
  final headRect = Rect.fromCircle(center: head, radius: headR);
  if (front) {
    // A cap over the top of the head.
    hair
      ..addArc(headRect, math.pi * 1.05, math.pi * 0.9)
      ..close();
  } else {
    // The whole back of the head, down past the ears.
    hair
      ..addArc(headRect, math.pi * 0.95, math.pi * 1.1)
      ..lineTo(x + headR, headCY + headR * 0.35)
      ..lineTo(x - headR, headCY + headR * 0.35)
      ..close();
  }
  canvas.drawPath(hair, fill..color = Color(look.hair));
  if (front) {
    final eyeY = headCY + headR * 0.1;
    final eyeR = headR * 0.12;
    final shift = fx * headR * 0.15;
    canvas
      ..drawCircle(
        Offset(x - headR * 0.35 + shift, eyeY),
        eyeR,
        fill..color = _ink,
      )
      ..drawCircle(Offset(x + headR * 0.35 + shift, eyeY), eyeR, fill);
  }
}

/// Overall citizen size against the mock's 15 px figure. Trimmed to 0.55
/// (≈8 px at zoom 1, cabin height of a car) once cars were on the
/// roads and the full-size chibi read as taller than a car.
const double kCitizenSize = 0.55;

// P02 proportions (city_builder.md §9.3), as fractions of the height.
const double _height = 15;
const double _headRatio = 0.2;
const double _legRatio = 0.3;
const double _bodyWidthRatio = 0.42;
const double _strideRatio = 0.2;
const double _bobRatio = 0.08;
const double _legWidth = 3.1;
const double _inkWidth = 0.9;
const Color _ink = Color(0xFF2B2B3A);

/// Screen-space unit vectors of the four grid headings on the 2:1 diamond:
/// east is `(halfW, halfH)` normalised, i.e. down-right.
final List<Offset> _unit = [
  for (final (dc, dr) in pedestrianDirDeltas)
    () {
      final dx = (dc - dr) * 2.0; // halfW : halfH = 2 : 1
      final dy = (dc + dr) * 1.0;
      final len = math.sqrt(dx * dx + dy * dy);
      return Offset(dx / len, dy / len);
    }(),
];

/// The saturated shirt palette chosen in §9.3, plus pants, skins and hairs.
const citizenShirts = <int>[
  0xFFE0523F,
  0xFF3A7BD5,
  0xFFF2B134,
  0xFF3DA85F,
  0xFF8E5BD1,
  0xFFFF8C42,
  0xFFF06292,
  0xFF26C6DA,
];
const citizenPants = <int>[0xFF3A3F5C, 0xFF4A4A4A, 0xFF6B4B3A, 0xFF2F5D8A];
const citizenSkins = <int>[
  0xFFF1C9A5,
  0xFFD9A276,
  0xFFB07A4F,
  0xFF8D5A3A,
  0xFFF7DCC2,
];
const citizenHairs = <int>[
  0xFF2B1D12,
  0xFF6B3E1E,
  0xFFD8B26A,
  0xFF1A1A1A,
  0xFF9C3D1F,
  0xFFC8C8C8,
];
