import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [ShapeSpec] as an outline figure. 2D polygons use a fixed
/// canonical orientation (the triangle apex on top, the rectangle wider
/// than tall, the trapezoid with the longer base down) so kids can
/// distinguish kinds at a glance. 3D solids are drawn as light wireframe
/// schematics — enough to recognize "cube" vs. "cylinder" but not
/// pretending to be photorealistic.
class Shape extends StatelessWidget {
  const Shape({
    required this.spec,
    this.size = 160,
    super.key,
  });

  final ShapeSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShapePainter(
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

class _ShapePainter extends CustomPainter {
  _ShapePainter({
    required this.spec,
    required this.edgeColor,
    required this.fillColor,
    required this.labelStyle,
  });

  final ShapeSpec spec;
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
    final box = Rect.fromLTWH(
      pad,
      pad,
      size.width - 2 * pad,
      size.height - 2 * pad,
    );

    switch (spec.kind) {
      case ShapeKind.circle:
        _drawCircle(canvas, box, fill, stroke);
      case ShapeKind.triangleRight:
        _drawTriangleRight(canvas, box, fill, stroke);
      case ShapeKind.triangleEquilateral:
        _drawTriangleEquilateral(canvas, box, fill, stroke);
      case ShapeKind.triangleIsosceles:
        _drawTriangleIsosceles(canvas, box, fill, stroke);
      case ShapeKind.triangleScalene:
        _drawTriangleScalene(canvas, box, fill, stroke);
      case ShapeKind.square:
        _drawSquare(canvas, box, fill, stroke);
      case ShapeKind.rectangle:
        _drawRectangle(canvas, box, fill, stroke);
      case ShapeKind.parallelogram:
        _drawParallelogram(canvas, box, fill, stroke);
      case ShapeKind.rhombus:
        _drawRhombus(canvas, box, fill, stroke);
      case ShapeKind.trapezoid:
        _drawTrapezoid(canvas, box, fill, stroke);
      case ShapeKind.pentagon:
        _drawRegular(canvas, box, fill, stroke, 5, rotateDeg: -90);
      case ShapeKind.hexagon:
        _drawRegular(canvas, box, fill, stroke, 6, rotateDeg: -90);
      case ShapeKind.octagon:
        _drawRegular(canvas, box, fill, stroke, 8, rotateDeg: -90 - 360 / 16);
      case ShapeKind.cube:
        _drawCube(canvas, box, fill, stroke);
      case ShapeKind.sphere:
        _drawSphere(canvas, box, fill, stroke);
      case ShapeKind.cylinder:
        _drawCylinder(canvas, box, fill, stroke);
      case ShapeKind.cone:
        _drawCone(canvas, box, fill, stroke);
    }

    if (spec.label != null) {
      _drawLabel(canvas, spec.label!, Offset(size.width / 2, size.height - 6));
    }
  }

  // ── 2D ────────────────────────────────────────────────────────────────

  void _drawCircle(Canvas c, Rect box, Paint fill, Paint stroke) {
    final r = box.shortestSide / 2;
    c
      ..drawCircle(box.center, r, fill)
      ..drawCircle(box.center, r, stroke);
  }

  void _drawTriangleRight(Canvas c, Rect box, Paint fill, Paint stroke) {
    // Right angle at the bottom-left.
    final p = Path()
      ..moveTo(box.left, box.bottom)
      ..lineTo(box.right, box.bottom)
      ..lineTo(box.left, box.top)
      ..close();
    c
      ..drawPath(p, fill)
      ..drawPath(p, stroke);
    if (spec.showRightAngleMark) {
      const m = 14.0;
      final s = Path()
        ..moveTo(box.left + m, box.bottom)
        ..lineTo(box.left + m, box.bottom - m)
        ..lineTo(box.left, box.bottom - m);
      c.drawPath(s, stroke);
    }
  }

  void _drawTriangleEquilateral(Canvas c, Rect box, Paint fill, Paint stroke) {
    // Apex on top. Base width fills the box; height = base · √3/2.
    final base = box.width;
    final height = base * math.sqrt(3) / 2;
    final dy = (box.height - height) / 2;
    final p = Path()
      ..moveTo(box.left, box.bottom - dy)
      ..lineTo(box.right, box.bottom - dy)
      ..lineTo(box.center.dx, box.bottom - dy - height)
      ..close();
    c
      ..drawPath(p, fill)
      ..drawPath(p, stroke);
  }

  void _drawTriangleIsosceles(Canvas c, Rect box, Paint fill, Paint stroke) {
    // Taller than equilateral so kids see "narrow isosceles".
    final p = Path()
      ..moveTo(box.left + box.width * 0.15, box.bottom)
      ..lineTo(box.right - box.width * 0.15, box.bottom)
      ..lineTo(box.center.dx, box.top)
      ..close();
    c
      ..drawPath(p, fill)
      ..drawPath(p, stroke);
  }

  void _drawTriangleScalene(Canvas c, Rect box, Paint fill, Paint stroke) {
    final p = Path()
      ..moveTo(box.left, box.bottom)
      ..lineTo(box.right - 4, box.bottom - box.height * 0.2)
      ..lineTo(box.left + box.width * 0.3, box.top)
      ..close();
    c
      ..drawPath(p, fill)
      ..drawPath(p, stroke);
  }

  void _drawSquare(Canvas c, Rect box, Paint fill, Paint stroke) {
    // Force aspect ratio 1:1 so kids see a true square.
    final side = box.shortestSide;
    final sq = Rect.fromCenter(center: box.center, width: side, height: side);
    c
      ..drawRect(sq, fill)
      ..drawRect(sq, stroke);
  }

  void _drawRectangle(Canvas c, Rect box, Paint fill, Paint stroke) {
    // Force visibly wider than tall (3:2 inside the box).
    final w = box.width;
    final h = w * 0.6;
    final r = Rect.fromCenter(center: box.center, width: w, height: h);
    c
      ..drawRect(r, fill)
      ..drawRect(r, stroke);
  }

  void _drawParallelogram(Canvas c, Rect box, Paint fill, Paint stroke) {
    final slant = box.width * 0.18;
    final p = Path()
      ..moveTo(box.left + slant, box.top)
      ..lineTo(box.right, box.top)
      ..lineTo(box.right - slant, box.bottom)
      ..lineTo(box.left, box.bottom)
      ..close();
    c
      ..drawPath(p, fill)
      ..drawPath(p, stroke);
  }

  void _drawRhombus(Canvas c, Rect box, Paint fill, Paint stroke) {
    final p = Path()
      ..moveTo(box.center.dx, box.top)
      ..lineTo(box.right, box.center.dy)
      ..lineTo(box.center.dx, box.bottom)
      ..lineTo(box.left, box.center.dy)
      ..close();
    c
      ..drawPath(p, fill)
      ..drawPath(p, stroke);
  }

  void _drawTrapezoid(Canvas c, Rect box, Paint fill, Paint stroke) {
    // Longer base on the bottom.
    final inset = box.width * 0.2;
    final p = Path()
      ..moveTo(box.left + inset, box.top)
      ..lineTo(box.right - inset, box.top)
      ..lineTo(box.right, box.bottom)
      ..lineTo(box.left, box.bottom)
      ..close();
    c
      ..drawPath(p, fill)
      ..drawPath(p, stroke);
  }

  void _drawRegular(
    Canvas c,
    Rect box,
    Paint fill,
    Paint stroke,
    int n, {
    required double rotateDeg,
  }) {
    final r = box.shortestSide / 2;
    final cx = box.center.dx;
    final cy = box.center.dy;
    final p = Path();
    for (var i = 0; i < n; i++) {
      final t = (rotateDeg + i * 360 / n) * math.pi / 180;
      final x = cx + r * math.cos(t);
      final y = cy + r * math.sin(t);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    c
      ..drawPath(p, fill)
      ..drawPath(p, stroke);
  }

  // ── 3D — schematic ─────────────────────────────────────────────────────

  void _drawCube(Canvas c, Rect box, Paint fill, Paint stroke) {
    final s = box.shortestSide * 0.66;
    final off = s * 0.32;
    final tl = Offset(
      box.center.dx - s / 2 - off / 2,
      box.center.dy - s / 2 + off / 2,
    );
    final tr = tl + Offset(s, 0);
    final bl = tl + Offset(0, s);
    final br = tl + Offset(s, s);
    final tlBack = tl + Offset(off, -off);
    final trBack = tr + Offset(off, -off);
    final brBack = br + Offset(off, -off);

    // Front face.
    final front = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();
    c
      ..drawPath(front, fill)
      ..drawPath(front, stroke);

    // Top face.
    final top = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tlBack.dx, tlBack.dy)
      ..lineTo(trBack.dx, trBack.dy)
      ..lineTo(tr.dx, tr.dy)
      ..close();
    c
      ..drawPath(top, fill)
      ..drawPath(top, stroke);

    // Right face.
    final right = Path()
      ..moveTo(tr.dx, tr.dy)
      ..lineTo(trBack.dx, trBack.dy)
      ..lineTo(brBack.dx, brBack.dy)
      ..lineTo(br.dx, br.dy)
      ..close();
    c
      ..drawPath(right, fill)
      ..drawPath(right, stroke);
  }

  void _drawSphere(Canvas c, Rect box, Paint fill, Paint stroke) {
    final r = box.shortestSide / 2;
    c
      ..drawCircle(box.center, r, fill)
      ..drawCircle(box.center, r, stroke);
    // Equator ellipse (dashed look approximated as a thin line).
    final ellipse = Rect.fromCenter(
      center: box.center,
      width: r * 2,
      height: r * 0.6,
    );
    c.drawArc(ellipse, 0, 2 * math.pi, false, stroke);
  }

  void _drawCylinder(Canvas c, Rect box, Paint fill, Paint stroke) {
    final w = box.width * 0.66;
    final h = box.height * 0.85;
    final topY = box.center.dy - h / 2;
    final botY = box.center.dy + h / 2;
    final left = box.center.dx - w / 2;
    final right = box.center.dx + w / 2;
    final ellipseH = w * 0.28;

    // Body fill.
    final body = Path()
      ..moveTo(left, topY)
      ..lineTo(left, botY)
      ..lineTo(right, botY)
      ..lineTo(right, topY)
      ..close();

    // Body fill + side walls.
    c
      ..drawPath(body, fill)
      ..drawLine(Offset(left, topY), Offset(left, botY), stroke)
      ..drawLine(Offset(right, topY), Offset(right, botY), stroke);

    // Top ellipse (full).
    final topEllipse = Rect.fromCenter(
      center: Offset(box.center.dx, topY),
      width: w,
      height: ellipseH,
    );
    c
      ..drawOval(topEllipse, fill)
      ..drawOval(topEllipse, stroke);

    // Bottom ellipse (front half — solid; back half — same stroke for
    // schematic clarity).
    final botEllipse = Rect.fromCenter(
      center: Offset(box.center.dx, botY),
      width: w,
      height: ellipseH,
    );
    c.drawArc(botEllipse, 0, math.pi, false, stroke);
  }

  void _drawCone(Canvas c, Rect box, Paint fill, Paint stroke) {
    final w = box.width * 0.72;
    final h = box.height * 0.86;
    final apex = Offset(box.center.dx, box.center.dy - h / 2);
    final baseY = box.center.dy + h / 2;
    final left = Offset(box.center.dx - w / 2, baseY);
    final right = Offset(box.center.dx + w / 2, baseY);
    final ellipseH = w * 0.28;

    // Triangular fill.
    final body = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    c
      ..drawPath(body, fill)
      ..drawLine(apex, left, stroke)
      ..drawLine(apex, right, stroke);

    // Base ellipse.
    final baseEllipse = Rect.fromCenter(
      center: Offset(box.center.dx, baseY),
      width: w,
      height: ellipseH,
    );
    c
      ..drawOval(baseEllipse, fill)
      ..drawOval(baseEllipse, stroke);
  }

  // ── helpers ────────────────────────────────────────────────────────────

  void _drawLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height));
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.spec != spec ||
      old.edgeColor != edgeColor ||
      old.fillColor != fillColor;
}
