import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [ScatterPlotSpec] as a coordinate plot tuned for scatter
/// data: light grid, integer tick labels, optional axis labels along
/// the bottom and left, plain dot points (no letter labels), and an
/// optional dashed best-fit line clipped to the visible plot rect.
///
/// Visually distinct from the coordinate-plane widget — the grid is
/// fainter, the axes are heavier, and dots are filled circles without
/// per-point captions.
class ScatterPlot extends StatelessWidget {
  const ScatterPlot({
    required this.spec,
    this.cellSize = 28,
    super.key,
  });

  final ScatterPlotSpec spec;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gutter = 28.0;
    final extraLeft = spec.yAxisLabel == null ? 0.0 : 18.0;
    final extraBottom = spec.xAxisLabel == null ? 0.0 : 18.0;
    final cols = spec.maxX - spec.minX;
    final rows = spec.maxY - spec.minY;
    return LayoutBuilder(
      builder: (context, constraints) {
        var effective = cellSize;
        if (constraints.maxWidth.isFinite) {
          final perCell =
              (constraints.maxWidth - 2 * gutter - extraLeft) / cols;
          if (perCell > 0) effective = math.min(effective, perCell);
        }
        final width = cols * effective;
        final height = rows * effective;
        return SizedBox(
          width: width + 2 * gutter + extraLeft,
          height: height + 2 * gutter + extraBottom,
          child: CustomPaint(
            painter: _ScatterPlotPainter(
              spec: spec,
              cellSize: effective,
              gutter: gutter,
              extraLeft: extraLeft,
              extraBottom: extraBottom,
              gridColor: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.5,
              ),
              axisColor: theme.colorScheme.onSurface,
              pointColor: theme.colorScheme.primary,
              fitLineColor: theme.colorScheme.tertiary,
              labelStyle:
                  theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11),
              axisLabelStyle:
                  (theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12))
                      .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}

class _ScatterPlotPainter extends CustomPainter {
  _ScatterPlotPainter({
    required this.spec,
    required this.cellSize,
    required this.gutter,
    required this.extraLeft,
    required this.extraBottom,
    required this.gridColor,
    required this.axisColor,
    required this.pointColor,
    required this.fitLineColor,
    required this.labelStyle,
    required this.axisLabelStyle,
  });

  final ScatterPlotSpec spec;
  final double cellSize;
  final double gutter;
  final double extraLeft;
  final double extraBottom;
  final Color gridColor;
  final Color axisColor;
  final Color pointColor;
  final Color fitLineColor;
  final TextStyle labelStyle;
  final TextStyle axisLabelStyle;

  Offset _pixel(num x, num y) {
    final px = gutter + extraLeft + (x - spec.minX) * cellSize;
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
      ..strokeWidth = 1.8;

    for (var x = spec.minX; x <= spec.maxX; x++) {
      canvas.drawLine(_pixel(x, spec.minY), _pixel(x, spec.maxY), gridPaint);
    }
    for (var y = spec.minY; y <= spec.maxY; y++) {
      canvas.drawLine(_pixel(spec.minX, y), _pixel(spec.maxX, y), gridPaint);
    }

    // Heavy axes along the bottom and left of the plot rect (not at 0
    // — scatter plots conventionally box the plotting area regardless
    // of where 0 falls).
    canvas
      ..drawLine(
        _pixel(spec.minX, spec.minY),
        _pixel(spec.maxX, spec.minY),
        axisPaint,
      )
      ..drawLine(
        _pixel(spec.minX, spec.minY),
        _pixel(spec.minX, spec.maxY),
        axisPaint,
      );
    // If 0 falls inside the range and isn't already the left/bottom edge,
    // bold those axes too.
    if (spec.minX < 0 && 0 <= spec.maxX) {
      canvas.drawLine(_pixel(0, spec.minY), _pixel(0, spec.maxY), axisPaint);
    }
    if (spec.minY < 0 && 0 <= spec.maxY) {
      canvas.drawLine(_pixel(spec.minX, 0), _pixel(spec.maxX, 0), axisPaint);
    }

    final tickStep = _tickStep();
    for (var x = spec.minX; x <= spec.maxX; x += tickStep) {
      _drawText(
        canvas,
        '$x',
        _pixel(x, spec.minY) + const Offset(0, 10),
        labelStyle,
      );
    }
    for (var y = spec.minY; y <= spec.maxY; y += tickStep) {
      _drawText(
        canvas,
        '$y',
        _pixel(spec.minX, y) + const Offset(-10, 0),
        labelStyle,
      );
    }

    if (spec.xAxisLabel != null) {
      final mid =
          (_pixel(spec.minX, spec.minY) + _pixel(spec.maxX, spec.minY)) / 2;
      _drawText(
        canvas,
        spec.xAxisLabel!,
        mid + Offset(0, 28 + extraBottom * 0.3),
        axisLabelStyle,
      );
    }
    if (spec.yAxisLabel != null) {
      final mid =
          (_pixel(spec.minX, spec.minY) + _pixel(spec.minX, spec.maxY)) / 2;
      canvas
        ..save()
        ..translate(mid.dx - 24, mid.dy)
        ..rotate(-math.pi / 2);
      _drawText(canvas, spec.yAxisLabel!, Offset.zero, axisLabelStyle);
      canvas.restore();
    }

    final fit = spec.lineOfFit;
    if (fit != null) {
      final plotRect = Rect.fromLTRB(
        _pixel(spec.minX, spec.maxY).dx,
        _pixel(spec.minX, spec.maxY).dy,
        _pixel(spec.maxX, spec.minY).dx,
        _pixel(spec.maxX, spec.minY).dy,
      );
      final visible = _clipLineToRect(fit, plotRect);
      if (visible != null) {
        final paint = Paint()
          ..color = fitLineColor
          ..strokeWidth = 2.4;
        _drawDashed(canvas, visible.$1, visible.$2, paint);
      }
    }

    final pointPaint = Paint()..color = pointColor;
    for (final p in spec.points) {
      canvas.drawCircle(_pixel(p.x, p.y), 5, pointPaint);
    }
  }

  int _tickStep() {
    final cols = spec.maxX - spec.minX;
    final rows = spec.maxY - spec.minY;
    final span = math.max(cols, rows);
    if (span <= 8) return 1;
    if (span <= 16) return 2;
    return (span / 8).ceil();
  }

  void _drawText(Canvas canvas, String text, Offset centre, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2),
    );
  }

  (Offset, Offset)? _clipLineToRect(ScatterPlotLineOfFit line, Rect rect) {
    final p1 = _pixel(line.x1, line.y1);
    final p2 = _pixel(line.x2, line.y2);
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final hits = <Offset>[];

    bool inRect(double x, double y) =>
        x >= rect.left - 0.001 &&
        x <= rect.right + 0.001 &&
        y >= rect.top - 0.001 &&
        y <= rect.bottom + 0.001;

    void tryAdd(Offset o) {
      for (final existing in hits) {
        if ((existing - o).distance < 0.5) return;
      }
      hits.add(o);
    }

    if (dx.abs() > 1e-9) {
      for (final xEdge in <double>[rect.left, rect.right]) {
        final t = (xEdge - p1.dx) / dx;
        final y = p1.dy + t * dy;
        if (inRect(xEdge, y)) tryAdd(Offset(xEdge, y));
      }
    }
    if (dy.abs() > 1e-9) {
      for (final yEdge in <double>[rect.top, rect.bottom]) {
        final t = (yEdge - p1.dy) / dy;
        final x = p1.dx + t * dx;
        if (inRect(x, yEdge)) tryAdd(Offset(x, yEdge));
      }
    }
    if (hits.length < 2) return null;
    return (hits.first, hits[1]);
  }

  void _drawDashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 4.0;
    final total = (b - a).distance;
    if (total < 1) return;
    final dir = Offset((b.dx - a.dx) / total, (b.dy - a.dy) / total);
    var travelled = 0.0;
    var drawing = true;
    while (travelled < total) {
      final step = drawing ? dashLen : gapLen;
      final segEnd = travelled + step > total ? total : travelled + step;
      if (drawing) {
        canvas.drawLine(
          a + dir * travelled,
          a + dir * segEnd,
          paint,
        );
      }
      travelled = segEnd;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_ScatterPlotPainter old) =>
      old.spec != spec ||
      old.cellSize != cellSize ||
      old.gridColor != gridColor ||
      old.axisColor != axisColor ||
      old.pointColor != pointColor ||
      old.fitLineColor != fitLineColor;
}
