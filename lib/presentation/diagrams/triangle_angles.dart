import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [TriangleAnglesSpec] as a triangle with three labelled
/// vertex angles. Vertex positions are computed from the angle measures
/// using the law of sines so the visible triangle reflects the spec's
/// shape (e.g. a 90-45-45 right triangle looks visibly right-angled).
class TriangleAngles extends StatelessWidget {
  const TriangleAngles({
    required this.spec,
    this.size = 220,
    super.key,
  });

  final TriangleAnglesSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TrianglePainter(
          spec: spec,
          edgeColor: theme.colorScheme.onSurface,
          dashColor: theme.colorScheme.tertiary,
          textStyle:
              theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({
    required this.spec,
    required this.edgeColor,
    required this.dashColor,
    required this.textStyle,
  });

  final TriangleAnglesSpec spec;
  final Color edgeColor;
  final Color dashColor;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    // Construct the triangle in math-space: place side AB along the
    // x-axis with A at origin. Side AB has length 1; use the angles at
    // A and B to locate C via the law of sines.
    //
    // For a triangle with angles A, B, C opposite sides a, b, c (with the
    // standard CCSS convention), c = AB. We pick AB = 1, then
    //   AC = sin(B) / sin(C)   (law of sines: AC/sin(B) = AB/sin(C))
    // and C sits at angle A above AB.
    final aRad = spec.angleDegA * math.pi / 180;
    final bRad = spec.angleDegB * math.pi / 180;
    final cRad = spec.angleDegC * math.pi / 180;
    final acLen = math.sin(bRad) / math.sin(cRad);

    // Math-space vertices (y up).
    const aMath = (x: 0.0, y: 0.0);
    const bMath = (x: 1.0, y: 0.0);
    final cMath = (
      x: acLen * math.cos(aRad),
      y: acLen * math.sin(aRad),
    );

    // Fit into the canvas with a margin.
    const margin = 36.0;
    final minX = [aMath.x, bMath.x, cMath.x].reduce(math.min);
    final maxX = [aMath.x, bMath.x, cMath.x].reduce(math.max);
    final minY = [aMath.y, bMath.y, cMath.y].reduce(math.min);
    final maxY = [aMath.y, bMath.y, cMath.y].reduce(math.max);
    final spanX = maxX - minX;
    final spanY = maxY - minY;
    final scale = math.min(
      (size.width - 2 * margin) / spanX,
      (size.height - 2 * margin) / spanY,
    );

    // Convert math-space to canvas-space (y flipped, centered).
    final usedW = spanX * scale;
    final usedH = spanY * scale;
    final offsetX = (size.width - usedW) / 2 - minX * scale;
    final offsetY = (size.height - usedH) / 2 + maxY * scale;

    Offset canvasOf(({double x, double y}) p) =>
        Offset(p.x * scale + offsetX, offsetY - p.y * scale);

    final aPt = canvasOf(aMath);
    final bPt = canvasOf(bMath);
    final cPt = canvasOf(cMath);

    final edgePaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(aPt.dx, aPt.dy)
      ..lineTo(bPt.dx, bPt.dy)
      ..lineTo(cPt.dx, cPt.dy)
      ..close();
    canvas.drawPath(path, edgePaint);

    // Optional exterior-angle marker at C — extend side BC past C with
    // a dashed segment.
    if (spec.showExteriorAtC) {
      final dir = (cPt - bPt) / (cPt - bPt).distance;
      const extLen = 48.0;
      final extEnd = cPt + dir * extLen;
      _drawDashed(canvas, cPt, extEnd, dashColor);
    }

    // Vertex labels (corner letters).
    _drawLabel(canvas, 'A', _offsetLabel(aPt, bPt, cPt, away: aPt, dist: 14));
    _drawLabel(canvas, 'B', _offsetLabel(aPt, bPt, cPt, away: bPt, dist: 14));
    _drawLabel(canvas, 'C', _offsetLabel(aPt, bPt, cPt, away: cPt, dist: 14));

    // Interior angle labels: place inside each vertex, along the
    // bisector of the two incident edges.
    _drawInteriorLabel(canvas, aPt, bPt, cPt, spec.labelA);
    _drawInteriorLabel(canvas, bPt, aPt, cPt, spec.labelB);
    _drawInteriorLabel(canvas, cPt, aPt, bPt, spec.labelC);
  }

  void _drawDashed(Canvas canvas, Offset from, Offset to, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const dash = 6.0;
    const gap = 4.0;
    final total = (to - from).distance;
    final dir = (to - from) / total;
    var t = 0.0;
    while (t < total) {
      final start = from + dir * t;
      final end = from + dir * math.min(t + dash, total);
      canvas.drawLine(start, end, paint);
      t += dash + gap;
    }
  }

  /// Place [label] inside the vertex [v], biased toward the centroid.
  void _drawInteriorLabel(
    Canvas canvas,
    Offset v,
    Offset p,
    Offset q,
    String label,
  ) {
    final centroid = Offset(
      (v.dx + p.dx + q.dx) / 3,
      (v.dy + p.dy + q.dy) / 3,
    );
    final toCentroid = centroid - v;
    final dir = toCentroid / toCentroid.distance;
    final pos = v + dir * 28;
    _drawLabel(canvas, label, pos);
  }

  Offset _offsetLabel(
    Offset a,
    Offset b,
    Offset c, {
    required Offset away,
    required double dist,
  }) {
    final centroid = Offset((a.dx + b.dx + c.dx) / 3, (a.dy + b.dy + c.dy) / 3);
    final away2centroid = centroid - away;
    final away2c = away2centroid / away2centroid.distance;
    return away - away2c * dist;
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
  bool shouldRepaint(_TrianglePainter old) =>
      old.spec != spec ||
      old.edgeColor != edgeColor ||
      old.dashColor != dashColor;
}
