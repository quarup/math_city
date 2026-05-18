import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [ProtractorSpec] as a semicircular protractor (0° to 180°)
/// with tick labels at every 10°, the fixed base ray on the right, the
/// second ray drawn at [ProtractorSpec.angleDeg] (CCW from the 0° mark),
/// and an arc inside the angle they form.
///
/// The 0° mark is on the right side of the base (east of the vertex);
/// the 180° mark is on the left (west). Mirrors how a paper protractor
/// is laid down with the straight edge horizontal.
class Protractor extends StatelessWidget {
  const Protractor({
    required this.spec,
    this.size = 240,
    super.key,
  });

  final ProtractorSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size / 2 + 24,
      child: CustomPaint(
        painter: _ProtractorPainter(
          spec: spec,
          edgeColor: theme.colorScheme.outline,
          rayColor: theme.colorScheme.primary,
          arcColor: theme.colorScheme.secondary,
          labelStyle:
              theme.textTheme.labelSmall ?? const TextStyle(fontSize: 10),
          bigLabelStyle:
              (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
                  .copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ProtractorPainter extends CustomPainter {
  _ProtractorPainter({
    required this.spec,
    required this.edgeColor,
    required this.rayColor,
    required this.arcColor,
    required this.labelStyle,
    required this.bigLabelStyle,
  });

  final ProtractorSpec spec;
  final Color edgeColor;
  final Color rayColor;
  final Color arcColor;
  final TextStyle labelStyle;
  final TextStyle bigLabelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2, size.height) - 24;
    final vertex = Offset(size.width / 2, size.height - 16);

    // Protractor edge: half-circle on top, straight line at the bottom.
    final edge = Paint()
      ..color = edgeColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromCircle(center: vertex, radius: radius);
    canvas
      ..drawArc(rect, math.pi, math.pi, false, edge)
      ..drawLine(
        Offset(vertex.dx - radius, vertex.dy),
        Offset(vertex.dx + radius, vertex.dy),
        edge,
      );

    // Convert protractor degrees (0° on the right, increasing CCW) into
    // canvas angles. In canvas, y grows downward, so "up" is negative y;
    // an angle of θ° in our convention sits at canvas (cos(-θ), sin(-θ))
    // from the vertex.
    Offset pointAt(int deg, double r) {
      final th = -deg * math.pi / 180;
      return Offset(
        vertex.dx + r * math.cos(th),
        vertex.dy + r * math.sin(th),
      );
    }

    // Tick marks + labels every 10°. Label only the 10°-multiples so the
    // diagram stays readable.
    final tickPaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 1;
    for (var d = 0; d <= 180; d += 10) {
      final outer = pointAt(d, radius);
      final inner = pointAt(d, radius - 10);
      canvas.drawLine(outer, inner, tickPaint);
      _drawLabel(
        canvas,
        '$d',
        pointAt(d, radius - 22),
        labelStyle,
      );
    }

    // Base ray: a thick segment along 0° from the vertex.
    final rayPaint = Paint()
      ..color = rayColor
      ..strokeWidth = 2.4;
    canvas
      ..drawLine(vertex, pointAt(0, radius + 4), rayPaint)
      ..drawLine(vertex, pointAt(spec.angleDeg, radius + 4), rayPaint)
      // Vertex dot.
      ..drawCircle(vertex, 3, Paint()..color = rayColor);

    // Arc inside the angle.
    final arcPaint = Paint()
      ..color = arcColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final arcRect = Rect.fromCircle(center: vertex, radius: radius * 0.28);
    canvas.drawArc(
      arcRect,
      0, // canvas 0 = east
      -spec.angleDeg * math.pi / 180, // CCW = negative canvas angle
      false,
      arcPaint,
    );

    if (spec.showAngleLabel) {
      _drawLabel(
        canvas,
        '${spec.angleDeg}°',
        pointAt(spec.angleDeg ~/ 2, radius * 0.55),
        bigLabelStyle,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ProtractorPainter old) =>
      old.spec != spec ||
      old.edgeColor != edgeColor ||
      old.rayColor != rayColor ||
      old.arcColor != arcColor;
}
