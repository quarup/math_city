import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Short-lived particle burst shown at the selected segment on landing.
///
/// Removes itself from the component tree after [_duration] seconds.
class BurstComponent extends PositionComponent {
  BurstComponent({required Vector2 burstPosition})
      : super(position: burstPosition, priority: 3);

  double _elapsed = 0;
  static const double _duration = 1.2;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed = (_elapsed + dt).clamp(0.0, _duration);
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _elapsed / _duration;
    final ease = 1.0 - math.pow(1.0 - t, 3).toDouble();

    final ringOpacity = (1.0 - t).clamp(0.0, 1.0);

    // Expanding golden ring.
    canvas.drawCircle(
      Offset.zero,
      ease * 60.0,
      Paint()
        ..color = Colors.amber.withValues(alpha: ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * (1.0 - t) + 1.0,
    );

    // White inner flash that fades quickly in the first ~0.3 s.
    final flashT = (1.0 - t * 3.3).clamp(0.0, 1.0);
    if (flashT > 0) {
      canvas.drawCircle(
        Offset.zero,
        20.0 * (1.0 - flashT) + 4.0,
        Paint()..color = Colors.white.withValues(alpha: flashT * 0.9),
      );
    }

    // 8 sparkle lines radiating outward.
    final sparkPaint = Paint()
      ..color = Colors.amber.withValues(alpha: ringOpacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final startR = 10.0 + ease * 20.0;
      final endR = startR + ease * 30.0;
      canvas.drawLine(
        Offset(math.cos(angle) * startR, math.sin(angle) * startR),
        Offset(math.cos(angle) * endR, math.sin(angle) * endR),
        sparkPaint,
      );
    }
  }
}
