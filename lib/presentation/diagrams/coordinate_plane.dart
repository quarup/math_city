import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [CoordinatePlaneSpec] as a grid with labelled axes and a set
/// of marked, optionally-lettered points. Used by `plot_*_quadrant`,
/// `read_first_quadrant`, and (later) transformations / graph generators.
class CoordinatePlane extends StatelessWidget {
  const CoordinatePlane({
    required this.spec,
    this.cellSize = 24,
    super.key,
  });

  final CoordinatePlaneSpec spec;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = (spec.maxX - spec.minX) * cellSize;
    final height = (spec.maxY - spec.minY) * cellSize;
    // Reserve a fixed gutter for axis labels (numbers along the axes).
    const gutter = 24.0;
    return SizedBox(
      width: width + 2 * gutter,
      height: height + 2 * gutter,
      child: CustomPaint(
        painter: _CoordinatePlanePainter(
          spec: spec,
          cellSize: cellSize,
          gutter: gutter,
          gridColor: theme.colorScheme.outlineVariant,
          axisColor: theme.colorScheme.onSurface,
          pointColor: theme.colorScheme.primary,
          labelStyle:
              theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11),
          pointLabelStyle: (theme.textTheme.labelMedium ??
                  const TextStyle(fontSize: 13))
              .copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
        ),
      ),
    );
  }
}

class _CoordinatePlanePainter extends CustomPainter {
  _CoordinatePlanePainter({
    required this.spec,
    required this.cellSize,
    required this.gutter,
    required this.gridColor,
    required this.axisColor,
    required this.pointColor,
    required this.labelStyle,
    required this.pointLabelStyle,
  });

  final CoordinatePlaneSpec spec;
  final double cellSize;
  final double gutter;
  final Color gridColor;
  final Color axisColor;
  final Color pointColor;
  final TextStyle labelStyle;
  final TextStyle pointLabelStyle;

  // Pixel coordinate of a grid (x, y) value. (minX, minY) sits at the
  // bottom-left of the drawable area; y is flipped because Flutter's
  // y axis points down.
  Offset _pixel(num x, num y) {
    final px = gutter + (x - spec.minX) * cellSize;
    final py = gutter + (spec.maxY - y) * cellSize;
    return Offset(px, py);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.6;

    // Grid lines parallel to the y axis (vertical), one per integer x.
    for (var x = spec.minX; x <= spec.maxX; x++) {
      canvas.drawLine(_pixel(x, spec.minY), _pixel(x, spec.maxY), gridPaint);
    }
    // Grid lines parallel to the x axis (horizontal), one per integer y.
    for (var y = spec.minY; y <= spec.maxY; y++) {
      canvas.drawLine(_pixel(spec.minX, y), _pixel(spec.maxX, y), gridPaint);
    }
    // Bold the axes whenever 0 falls inside the visible range.
    if (spec.minX <= 0 && 0 <= spec.maxX) {
      canvas.drawLine(_pixel(0, spec.minY), _pixel(0, spec.maxY), axisPaint);
    }
    if (spec.minY <= 0 && 0 <= spec.maxY) {
      canvas.drawLine(_pixel(spec.minX, 0), _pixel(spec.maxX, 0), axisPaint);
    }

    // Tick labels along x and y. Place x-labels below the bottom edge and
    // y-labels left of the left edge. Skip 0 on each axis to avoid label
    // collisions at the origin.
    for (var x = spec.minX; x <= spec.maxX; x++) {
      if (x == 0) continue;
      _drawLabel(
        canvas,
        '$x',
        _pixel(x, spec.minY) + const Offset(0, 10),
      );
    }
    for (var y = spec.minY; y <= spec.maxY; y++) {
      if (y == 0) continue;
      _drawLabel(
        canvas,
        '$y',
        _pixel(spec.minX, y) + const Offset(-10, 0),
      );
    }
    // Origin label "0" sits in the corner where both axes meet.
    if (spec.minX <= 0 && 0 <= spec.maxX && spec.minY <= 0 && 0 <= spec.maxY) {
      _drawLabel(canvas, '0', _pixel(0, 0) + const Offset(-8, 8));
    }

    // Marked points. Draw the dot first; if the point has a label, render
    // it just above-right of the dot so it never overlaps the dot itself.
    final pointPaint = Paint()..color = pointColor;
    for (final p in spec.points) {
      final centre = _pixel(p.x, p.y);
      canvas.drawCircle(centre, 5, pointPaint);
      if (p.label != null) {
        _drawTextStyled(
          canvas,
          p.label!,
          centre + const Offset(8, -12),
          pointLabelStyle,
          alignLeft: true,
        );
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset centre) {
    _drawTextStyled(canvas, text, centre, labelStyle);
  }

  void _drawTextStyled(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    bool alignLeft = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignLeft ? anchor.dx : anchor.dx - tp.width / 2;
    final dy = anchor.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_CoordinatePlanePainter old) =>
      old.spec != spec ||
      old.cellSize != cellSize ||
      old.gridColor != gridColor ||
      old.axisColor != axisColor ||
      old.pointColor != pointColor;
}
