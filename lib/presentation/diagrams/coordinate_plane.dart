import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [CoordinatePlaneSpec] as a grid with labelled axes and a set
/// of marked, optionally-lettered points. Used by `plot_*_quadrant`,
/// `read_first_quadrant`, and (later) transformations / graph generators.
///
/// [cellSize] is the *requested* pixel size of each grid cell. The widget
/// shrinks below this value to fit the available width when the parent
/// constraint is narrower than the natural size — important for the
/// `[-8, 8]` grid (17 cells × 24 px = 408 px, which exceeds typical
/// phone widths). It never grows beyond the requested size.
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
    const gutter = 24.0;
    final cols = spec.maxX - spec.minX;
    final rows = spec.maxY - spec.minY;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Auto-shrink cellSize when the parent is narrower than the
        // natural grid size. Never grow beyond the requested cellSize.
        var effective = cellSize;
        if (constraints.maxWidth.isFinite) {
          final perCell = (constraints.maxWidth - 2 * gutter) / cols;
          if (perCell > 0) effective = math.min(effective, perCell);
        }
        final width = cols * effective;
        final height = rows * effective;
        return SizedBox(
          width: width + 2 * gutter,
          height: height + 2 * gutter,
          child: CustomPaint(
            painter: _CoordinatePlanePainter(
              spec: spec,
              cellSize: effective,
              gutter: gutter,
              gridColor: theme.colorScheme.outlineVariant,
              axisColor: theme.colorScheme.onSurface,
              pointColor: theme.colorScheme.primary,
              solidLineColor: theme.colorScheme.primary,
              dashedLineColor: theme.colorScheme.tertiary,
              labelStyle:
                  theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11),
              pointLabelStyle:
                  (theme.textTheme.labelMedium ?? const TextStyle(fontSize: 13))
                      .copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
            ),
          ),
        );
      },
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
    required this.solidLineColor,
    required this.dashedLineColor,
    required this.labelStyle,
    required this.pointLabelStyle,
  });

  final CoordinatePlaneSpec spec;
  final double cellSize;
  final double gutter;
  final Color gridColor;
  final Color axisColor;
  final Color pointColor;
  final Color solidLineColor;
  final Color dashedLineColor;
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

    // Polygons (drawn first, beneath lines and points). Each polygon is
    // auto-closed (last vertex → first).
    for (final poly in spec.polygons) {
      final path = Path();
      for (var i = 0; i < poly.vertices.length; i++) {
        final v = poly.vertices[i];
        final p = _pixel(v.x, v.y);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      switch (poly.style) {
        case CoordinatePlanePolygonStyle.solid:
          final fillPaint = Paint()
            ..color = solidLineColor.withValues(alpha: 0.18)
            ..style = PaintingStyle.fill;
          final strokePaint = Paint()
            ..color = solidLineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas
            ..drawPath(path, fillPaint)
            ..drawPath(path, strokePaint);
        case CoordinatePlanePolygonStyle.dashed:
          // Draw each edge as a dashed segment (no fill).
          final paint = Paint()
            ..color = dashedLineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          for (var i = 0; i < poly.vertices.length; i++) {
            final a = poly.vertices[i];
            final b = poly.vertices[(i + 1) % poly.vertices.length];
            _drawDashed(canvas, _pixel(a.x, a.y), _pixel(b.x, b.y), paint);
          }
      }
    }

    // Lines (drawn beneath points so the dots stay on top). Extrapolate
    // each line to the visible plot rect by intersecting it with all
    // four sides and keeping the two intersections that fall inside.
    final plotRect = Rect.fromLTRB(
      _pixel(spec.minX, spec.maxY).dx,
      _pixel(spec.minX, spec.maxY).dy,
      _pixel(spec.maxX, spec.minY).dx,
      _pixel(spec.maxX, spec.minY).dy,
    );
    for (final line in spec.lines) {
      final visible = _clipLineToRect(line, plotRect);
      if (visible == null) continue;
      final paint = Paint()
        ..color = line.style == CoordinatePlaneLineStyle.solid
            ? solidLineColor
            : dashedLineColor
        ..strokeWidth = 2.4;
      switch (line.style) {
        case CoordinatePlaneLineStyle.solid:
          canvas.drawLine(visible.$1, visible.$2, paint);
        case CoordinatePlaneLineStyle.dashed:
          _drawDashed(canvas, visible.$1, visible.$2, paint);
      }
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

  /// Compute the two endpoints where [line] (an infinite line through
  /// two distinct points) crosses [rect]. Returns null if the line
  /// misses the rect entirely.
  (Offset, Offset)? _clipLineToRect(CoordinatePlaneLine line, Rect rect) {
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
      // De-dup near-corner intersections (a horizontal line through a
      // corner hits both a vertical and a horizontal edge at the same
      // pixel — keep only one).
      for (final existing in hits) {
        if ((existing - o).distance < 0.5) return;
      }
      hits.add(o);
    }

    // Vertical sides: solve x = rect.left and x = rect.right for t.
    if (dx.abs() > 1e-9) {
      for (final xEdge in <double>[rect.left, rect.right]) {
        final t = (xEdge - p1.dx) / dx;
        final y = p1.dy + t * dy;
        if (inRect(xEdge, y)) tryAdd(Offset(xEdge, y));
      }
    }
    // Horizontal sides: solve y = rect.top and y = rect.bottom for t.
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

  /// Draw a dashed segment along the line from [a] to [b].
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
  bool shouldRepaint(_CoordinatePlanePainter old) =>
      old.spec != spec ||
      old.cellSize != cellSize ||
      old.gridColor != gridColor ||
      old.axisColor != axisColor ||
      old.pointColor != pointColor ||
      old.solidLineColor != solidLineColor ||
      old.dashedLineColor != dashedLineColor;
}
