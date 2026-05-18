import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders an [AngleSpec] as rays from a single vertex, with optional
/// labels inside the wedges between consecutive rays. Handles single-
/// angle, two-adjacent-angle, and intersecting-line cases.
class Angle extends StatelessWidget {
  const Angle({
    required this.spec,
    this.size = 200,
    super.key,
  });

  final AngleSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AnglePainter(
          spec: spec,
          rayColor: theme.colorScheme.onSurface,
          arcColor: theme.colorScheme.primary,
          textStyle:
              theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _AnglePainter extends CustomPainter {
  _AnglePainter({
    required this.spec,
    required this.rayColor,
    required this.arcColor,
    required this.textStyle,
  });

  final AngleSpec spec;
  final Color rayColor;
  final Color arcColor;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;

    final rayPaint = Paint()
      ..color = rayColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final arcPaint = Paint()
      ..color = arcColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Convert degrees (0 = east, CCW positive) to canvas radians
    // (0 = east, CW positive — flip the sign).
    double canvasRad(int deg) => -deg * math.pi / 180;

    // Draw rays.
    for (final deg in spec.rayAnglesDeg) {
      final theta = canvasRad(deg);
      final end = Offset(
        center.dx + radius * math.cos(theta),
        center.dy + radius * math.sin(theta),
      );
      canvas.drawLine(center, end, rayPaint);
    }
    // Vertex dot.
    canvas.drawCircle(center, 3, Paint()..color = rayColor);

    // Draw wedge labels.
    for (final wedge in spec.wedgeLabels) {
      final i = wedge.rayIndex;
      if (i >= spec.rayAnglesDeg.length) continue;
      final aDeg = spec.rayAnglesDeg[i];
      final bDeg = spec.rayAnglesDeg[(i + 1) % spec.rayAnglesDeg.length];
      // Sweep CCW from aDeg to bDeg; if bDeg < aDeg add 360.
      var span = bDeg - aDeg;
      if (span <= 0) span += 360;
      final midDeg = aDeg + span / 2;
      final arcRadius = radius * 0.32;
      final theta = canvasRad(aDeg);
      final canvasSweep = -span * math.pi / 180; // CCW in math = CW in canvas
      final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
      canvas.drawArc(arcRect, theta, canvasSweep, false, arcPaint);
      // Label position outside the arc.
      final labelR = arcRadius + 18;
      final labelTheta = canvasRad(midDeg.round());
      _drawLabel(
        canvas,
        wedge.label,
        Offset(
          center.dx + labelR * math.cos(labelTheta),
          center.dy + labelR * math.sin(labelTheta),
        ),
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_AnglePainter old) =>
      old.spec != spec ||
      old.rayColor != rayColor ||
      old.arcColor != arcColor;
}
