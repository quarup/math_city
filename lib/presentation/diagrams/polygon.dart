import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [PolygonSpec] as a regular n-gon with one vertex pointing
/// up (triangles look like triangles, hexagons look like hexagons, etc.).
/// Filled lightly so the outline reads at a glance.
class Polygon extends StatelessWidget {
  const Polygon({
    required this.spec,
    this.size = 160,
    super.key,
  });

  final PolygonSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PolygonPainter(
          spec: spec,
          edgeColor: theme.colorScheme.onSurface,
          fillColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          labelStyle:
              theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _PolygonPainter extends CustomPainter {
  _PolygonPainter({
    required this.spec,
    required this.edgeColor,
    required this.fillColor,
    required this.labelStyle,
  });

  final PolygonSpec spec;
  final Color edgeColor;
  final Color fillColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = edgeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final pad = size.shortestSide * 0.12;
    final reservedForLabel = spec.label == null ? 0.0 : 18.0;
    final boxHeight = size.height - 2 * pad - reservedForLabel;
    final boxWidth = size.width - 2 * pad;
    final r = math.min(boxWidth, boxHeight) / 2;
    final cx = size.width / 2;
    final cy = pad + boxHeight / 2;

    // First vertex points up. For even-N polygons (square, hexagon,
    // octagon) this gives a "top vertex" silhouette; for odd-N (triangle,
    // pentagon, heptagon) the apex sits at top, matching how kids
    // canonically draw them.
    const startAngle = -math.pi / 2;
    final path = Path();
    for (var i = 0; i < spec.sides; i++) {
      final t = startAngle + i * 2 * math.pi / spec.sides;
      final x = cx + r * math.cos(t);
      final y = cy + r * math.sin(t);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas
      ..drawPath(path, fill)
      ..drawPath(path, stroke);

    if (spec.label != null) {
      final tp = TextPainter(
        text: TextSpan(text: spec.label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, size.height - tp.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(_PolygonPainter old) =>
      old.spec.sides != spec.sides ||
      old.spec.label != spec.label ||
      old.edgeColor != edgeColor ||
      old.fillColor != fillColor;
}
