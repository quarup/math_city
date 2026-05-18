import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [LineFigureSpec] as a schematic one-dimensional figure:
/// a single line / ray / segment (with arrows or dots to indicate the
/// kind), or a pair of two lines in a parallel / perpendicular /
/// intersecting arrangement.
class LineFigure extends StatelessWidget {
  const LineFigure({
    required this.spec,
    this.size = 200,
    super.key,
  });

  final LineFigureSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size * 0.7,
      child: CustomPaint(
        painter: _LineFigurePainter(
          spec: spec,
          color: theme.colorScheme.primary,
          dotColor: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _LineFigurePainter extends CustomPainter {
  _LineFigurePainter({
    required this.spec,
    required this.color,
    required this.dotColor,
  });

  final LineFigureSpec spec;
  final Color color;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    const pad = 14.0;
    final mid = Offset(size.width / 2, size.height / 2);

    switch (spec.kind) {
      case LineFigureKind.line:
        _drawSingle(
          canvas,
          stroke,
          Offset(pad, mid.dy),
          Offset(size.width - pad, mid.dy),
          arrowLeft: true,
          arrowRight: true,
        );
      case LineFigureKind.ray:
        _drawSingle(
          canvas,
          stroke,
          Offset(pad + 6, mid.dy),
          Offset(size.width - pad, mid.dy),
          dotLeft: true,
          arrowRight: true,
        );
      case LineFigureKind.segment:
        _drawSingle(
          canvas,
          stroke,
          Offset(pad + 6, mid.dy),
          Offset(size.width - pad - 6, mid.dy),
          dotLeft: true,
          dotRight: true,
        );
      case LineFigureKind.parallelLines:
        // Two horizontal lines at different heights — both lines, arrows
        // on both ends.
        _drawSingle(
          canvas,
          stroke,
          Offset(pad, mid.dy - 24),
          Offset(size.width - pad, mid.dy - 24),
          arrowLeft: true,
          arrowRight: true,
        );
        _drawSingle(
          canvas,
          stroke,
          Offset(pad, mid.dy + 24),
          Offset(size.width - pad, mid.dy + 24),
          arrowLeft: true,
          arrowRight: true,
        );
      case LineFigureKind.perpendicularLines:
        // Horizontal + vertical line, intersecting at the centre.
        _drawSingle(
          canvas,
          stroke,
          Offset(pad, mid.dy),
          Offset(size.width - pad, mid.dy),
          arrowLeft: true,
          arrowRight: true,
        );
        _drawSingle(
          canvas,
          stroke,
          Offset(mid.dx, pad),
          Offset(mid.dx, size.height - pad),
          arrowLeft: true,
          arrowRight: true,
        );
        // Small right-angle marker at the intersection.
        const m = 10.0;
        final marker = Path()
          ..moveTo(mid.dx + m, mid.dy)
          ..lineTo(mid.dx + m, mid.dy - m)
          ..lineTo(mid.dx, mid.dy - m);
        canvas.drawPath(marker, stroke);
      case LineFigureKind.intersectingLines:
        // Two lines crossing at a non-right angle.
        _drawSingle(
          canvas,
          stroke,
          Offset(pad, mid.dy - 22),
          Offset(size.width - pad, mid.dy + 22),
          arrowLeft: true,
          arrowRight: true,
        );
        _drawSingle(
          canvas,
          stroke,
          Offset(pad, mid.dy + 22),
          Offset(size.width - pad, mid.dy - 22),
          arrowLeft: true,
          arrowRight: true,
        );
    }
  }

  /// Draws one straight segment from [a] to [b], optionally with
  /// arrowheads / dots at each end.
  void _drawSingle(
    Canvas canvas,
    Paint stroke,
    Offset a,
    Offset b, {
    bool arrowLeft = false,
    bool arrowRight = false,
    bool dotLeft = false,
    bool dotRight = false,
  }) {
    canvas.drawLine(a, b, stroke);
    if (arrowLeft) _arrow(canvas, stroke, b: a, a: b);
    if (arrowRight) _arrow(canvas, stroke, b: b, a: a);
    final dotPaint = Paint()..color = dotColor;
    if (dotLeft) canvas.drawCircle(a, 3.4, dotPaint);
    if (dotRight) canvas.drawCircle(b, 3.4, dotPaint);
  }

  /// Draws a small arrowhead at [b] pointing in the direction
  /// `(b - a)`. Two short lines forming the V.
  void _arrow(Canvas canvas, Paint stroke,
      {required Offset a, required Offset b}) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final angle = math.atan2(dy, dx);
    const len = 9.0;
    const spread = 0.5; // radians
    final p1 = Offset(
      b.dx - len * math.cos(angle - spread),
      b.dy - len * math.sin(angle - spread),
    );
    final p2 = Offset(
      b.dx - len * math.cos(angle + spread),
      b.dy - len * math.sin(angle + spread),
    );
    canvas
      ..drawLine(b, p1, stroke)
      ..drawLine(b, p2, stroke);
  }

  @override
  bool shouldRepaint(_LineFigurePainter old) =>
      old.spec != spec || old.color != color || old.dotColor != dotColor;
}
