import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

/// Sky gradient and the home-screen city strip behind the wheel, plus the
/// spin effect: while the wheel turns, the whole city smears sideways in
/// proportion to wheel speed and pale streaks fly outward from behind the
/// rim. The effect is driven by [intensity] (0 = at rest, 1 = full throw),
/// which the game sets every frame from the wheel's angular velocity.
class CityBackdrop extends PositionComponent {
  CityBackdrop({required this.skyTop, required this.skyBottom})
    : super(priority: 0);

  final Color skyTop;
  final Color skyBottom;

  /// `assets/images/math_city_bottom.png` is 2170×420.
  static const double stripAspect = 2170 / 420;

  /// The strip is drawn wider than the screen so it can crop at the sides
  /// without ever cropping at the bottom (and so the blur has real city to
  /// sample beyond the edge).
  static const double stripOverhang = 0.19;

  ui.Image? _strip;
  double intensity = 0;

  /// Wheel geometry, set by the game once laid out; streaks start just
  /// outside the rim.
  Vector2 wheelCenter = Vector2.zero();
  double wheelRadius = 100;

  static const _streakColor = Color(0xFFEAF7FF);
  static const _streakCount = 44;
  late final List<_Streak> _streaks = _seedStreaks();

  /// Top edge of the strip in game coordinates, for laying out the wheel.
  double get stripTop => size.y - stripHeight;
  double get stripWidth => size.x * (1 + 2 * stripOverhang);
  double get stripHeight => stripWidth / stripAspect;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _strip = await Flame.images.load('math_city_bottom.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (intensity <= 0) return;
    // Streaks stream outward at a speed tied to the wheel's.
    final speed = intensity * 18 * 28 * (wheelRadius / 148);
    final reset = wheelRadius + 20;
    final far = wheelRadius * 2.9;
    for (final s in _streaks) {
      s.r += speed * dt;
      if (s.r > far) s.r = reset;
    }
  }

  @override
  void render(Canvas canvas) {
    final k = intensity.clamp(0.0, 1.0);
    final full = Rect.fromLTWH(0, 0, size.x, size.y);
    final blur = k * 10 * (wheelRadius / 148);
    final blurred = blur > 0.3;

    if (blurred) {
      canvas.saveLayer(
        full,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: blur,
            tileMode: TileMode.clamp,
          ),
      );
    }

    // Sky, painted past both edges so a horizontal blur never pulls in
    // transparent pixels (the bezel showed through in the first mock).
    final sky = Rect.fromLTWH(-80, -20, size.x + 160, size.y + 40);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.y),
          [skyTop, skyBottom],
        ),
    );

    final strip = _strip;
    if (strip != null) {
      final w = stripWidth;
      final h = stripHeight;
      canvas.drawImageRect(
        strip,
        Rect.fromLTWH(0, 0, strip.width.toDouble(), strip.height.toDouble()),
        Rect.fromLTWH((size.x - w) / 2, size.y - h, w, h),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }

    if (blurred) canvas.restore();

    if (k > 0.02) _renderStreaks(canvas, k);
  }

  void _renderStreaks(Canvas canvas, double k) {
    final cx = wheelCenter.x;
    final cy = wheelCenter.y;
    final s = wheelRadius / 148;
    final paint = Paint()
      ..color = _streakColor.withValues(alpha: k * 0.75)
      ..strokeCap = StrokeCap.round;
    for (final st in _streaks) {
      final len = st.length * k * s;
      if (len < 1) continue;
      paint.strokeWidth = st.width * s;
      canvas.drawLine(
        Offset(cx + st.r * math.cos(st.angle), cy + st.r * math.sin(st.angle)),
        Offset(
          cx + (st.r + len) * math.cos(st.angle),
          cy + (st.r + len) * math.sin(st.angle),
        ),
        paint,
      );
    }
  }

  List<_Streak> _seedStreaks() {
    final rng = math.Random(17);
    return List.generate(_streakCount, (_) {
      return _Streak(
        angle: rng.nextDouble() * 2 * math.pi,
        r: wheelRadius + 24 + rng.nextDouble() * wheelRadius * 1.35,
        length: 40 + rng.nextDouble() * 90,
        width: 1.5 + rng.nextDouble() * 2,
      );
    });
  }
}

class _Streak {
  _Streak({
    required this.angle,
    required this.r,
    required this.length,
    required this.width,
  });

  final double angle;
  double r;
  final double length;
  final double width;
}
