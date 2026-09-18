import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:math_city/game/spin_wheel/spin_wheel_component.dart';

/// The friendly concept name, popping in below the wheel once it lands.
class RevealPill extends PositionComponent {
  RevealPill({
    required this.text,
    required this.dotColor,
    required Vector2 at,
    required this.scaleFactor,
  }) : super(position: at, priority: 4);

  final String text;
  final Color dotColor;

  /// Wheel scale (radius / 148), so the pill matches the wheel's weight.
  final double scaleFactor;

  double _t = 0;
  static const _popDuration = 0.35;

  @override
  void update(double dt) {
    super.update(dt);
    _t = (_t + dt / _popDuration).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    final s = scaleFactor;
    // Ease-out-back pop.
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final u = _t - 1;
    final pop = 1 + c3 * u * u * u + c1 * u * u;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 19 * s,
          fontWeight: FontWeight.w900,
          color: SpinWheelComponent.ink,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final h = 44 * s;
    final w = math.max(tp.width + 62 * s, 160 * s);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Radius.circular(h / 2),
    );

    canvas
      ..save()
      ..scale(pop, pop)
      ..drawRRect(
        rect.shift(Offset(0, 3 * s)),
        Paint()
          ..color = const Color(0xFF0B2A30).withValues(alpha: 0.28)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * s),
      )
      ..drawRRect(rect, Paint()..color = Colors.white)
      ..drawRRect(
        rect,
        Paint()
          ..color = SpinWheelComponent.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * s,
      );
    final dot = Offset(-w / 2 + 24 * s, 0);
    canvas
      ..drawCircle(dot, 9 * s, Paint()..color = dotColor)
      ..drawCircle(
        dot,
        9 * s,
        Paint()
          ..color = SpinWheelComponent.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * s,
      );
    tp.paint(canvas, Offset(-tp.width / 2 + 14 * s, -tp.height / 2));
    canvas.restore();
  }
}
