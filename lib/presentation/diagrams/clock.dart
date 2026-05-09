import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_dash/domain/questions/diagram_spec.dart';

/// Renders a [ClockSpec] as an analog clock face.
class Clock extends StatelessWidget {
  const Clock({
    required this.spec,
    this.size = 180,
    super.key,
  });

  final ClockSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ClockPainter(
          spec: spec,
          faceColor: theme.colorScheme.surface,
          rimColor: theme.colorScheme.outline,
          tickColor: theme.colorScheme.onSurface,
          hourHandColor: theme.colorScheme.primary,
          minuteHandColor: theme.colorScheme.tertiary,
          textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ) ??
              const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.spec,
    required this.faceColor,
    required this.rimColor,
    required this.tickColor,
    required this.hourHandColor,
    required this.minuteHandColor,
    required this.textStyle,
  });

  final ClockSpec spec;
  final Color faceColor;
  final Color rimColor;
  final Color tickColor;
  final Color hourHandColor;
  final Color minuteHandColor;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    // Face
    canvas
      ..drawCircle(center, radius, Paint()..color = faceColor)
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = rimColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

    // Hour numerals 1–12
    for (var h = 1; h <= 12; h++) {
      final theta = -math.pi / 2 + h * math.pi / 6;
      final r = radius * 0.78;
      final pos = Offset(
        center.dx + r * math.cos(theta),
        center.dy + r * math.sin(theta),
      );
      final tp = TextPainter(
        text: TextSpan(text: '$h', style: textStyle.copyWith(color: tickColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    // Minute ticks
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.4;
    for (var m = 0; m < 60; m++) {
      final theta = -math.pi / 2 + m * math.pi / 30;
      final outer = Offset(
        center.dx + radius * math.cos(theta),
        center.dy + radius * math.sin(theta),
      );
      final innerR = m % 5 == 0 ? radius - 8 : radius - 4;
      final inner = Offset(
        center.dx + innerR * math.cos(theta),
        center.dy + innerR * math.sin(theta),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Hour hand: angle accounts for minute progress.
    final hour12 = spec.hour % 12;
    final hourAngle = -math.pi / 2 +
        (hour12 + spec.minute / 60) * math.pi / 6;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.5 * math.cos(hourAngle),
        center.dy + radius * 0.5 * math.sin(hourAngle),
      ),
      Paint()
        ..color = hourHandColor
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Minute hand
    final minAngle = -math.pi / 2 + spec.minute * math.pi / 30;
    canvas
      ..drawLine(
        center,
        Offset(
          center.dx + radius * 0.78 * math.cos(minAngle),
          center.dy + radius * 0.78 * math.sin(minAngle),
        ),
        Paint()
          ..color = minuteHandColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      )
      // Center pin
      ..drawCircle(center, 4, Paint()..color = tickColor);
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.spec != spec ||
      old.faceColor != faceColor ||
      old.rimColor != rimColor ||
      old.tickColor != tickColor ||
      old.hourHandColor != hourHandColor ||
      old.minuteHandColor != minuteHandColor;
}
