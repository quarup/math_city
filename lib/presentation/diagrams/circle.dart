import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [CircleSpec] as a circle at a fixed visual size with
/// optional radius / diameter line and numeric labels. Used by
/// `circle_circumference` and `area_circle`.
class Circle extends StatelessWidget {
  const Circle({
    required this.spec,
    this.size = 180,
    super.key,
  });

  final CircleSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CirclePainter(
          spec: spec,
          edge: theme.colorScheme.onSurface,
          fill: theme.colorScheme.primary.withValues(alpha: 0.12),
          radiusColor: theme.colorScheme.primary,
          labelStyle:
              theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.spec,
    required this.edge,
    required this.fill,
    required this.radiusColor,
    required this.labelStyle,
  });

  final CircleSpec spec;
  final Color edge;
  final Color fill;
  final Color radiusColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 18;
    final fillPaint = Paint()..color = fill;
    final stroke = Paint()
      ..color = edge
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas
      ..drawCircle(centre, r, fillPaint)
      ..drawCircle(centre, r, stroke)
      // Centre dot.
      ..drawCircle(centre, 2.4, Paint()..color = edge);

    if (spec.showDiameter) {
      final diaStroke = Paint()
        ..color = radiusColor
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(centre.dx - r, centre.dy),
        Offset(centre.dx + r, centre.dy),
        diaStroke,
      );
      _drawText(
        canvas,
        'd = ${2 * spec.radius}',
        Offset(centre.dx, centre.dy + 14),
      );
    }

    if (spec.showRadius) {
      final radStroke = Paint()
        ..color = radiusColor
        ..strokeWidth = 2;
      canvas.drawLine(centre, Offset(centre.dx + r, centre.dy), radStroke);
      _drawText(
        canvas,
        'r = ${spec.radius}',
        Offset(centre.dx + r / 2, centre.dy - 12),
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset centre) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.spec != spec ||
      old.edge != edge ||
      old.fill != fill ||
      old.radiusColor != radiusColor;
}
