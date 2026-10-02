import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// The pale streaks that fly outward from behind the rim while the wheel
/// spins — half of the PR #112 spin effect (the other half is the city
/// smearing sideways behind the wheel). Driven by [intensity] (0 = at rest,
/// 1 = full throw), which the game sets every frame from the wheel's speed.
/// Drawn on its own so it works whatever sits behind the wheel: the
/// home-strip backdrop, or the live city when the wheel floats over it.
class SpinStreaks extends Component {
  SpinStreaks({required this.wheelCenter, required this.wheelRadius})
    : super(priority: 0);

  /// Streaks start just outside the rim.
  final Vector2 wheelCenter;
  final double wheelRadius;

  double intensity = 0;

  static const _streakColor = Color(0xFFEAF7FF);
  static const _streakCount = 44;
  late final List<_Streak> _streaks = _seedStreaks();

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
    if (k <= 0.02) return;
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
