import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [NumberLineSpec] with tick marks, labels, marked points,
/// and optional hop arcs.
class NumberLine extends StatelessWidget {
  const NumberLine({
    required this.spec,
    this.height = 100,
    super.key,
  });

  final NumberLineSpec spec;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _NumberLinePainter(
          spec: spec,
          lineColor: theme.colorScheme.onSurface,
          markColor: theme.colorScheme.primary,
          hopColor: theme.colorScheme.tertiary,
          textStyle: theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _NumberLinePainter extends CustomPainter {
  _NumberLinePainter({
    required this.spec,
    required this.lineColor,
    required this.markColor,
    required this.hopColor,
    required this.textStyle,
  });

  final NumberLineSpec spec;
  final Color lineColor;
  final Color markColor;
  final Color hopColor;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 24.0;
    final usableW = size.width - 2 * padX;
    final lineY = size.height * 0.65;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(padX, lineY),
      Offset(size.width - padX, lineY),
      linePaint,
    );

    double xFor(num v) {
      final t = (v - spec.min) / (spec.max - spec.min);
      return padX + t * usableW;
    }

    // Ticks at every division; labels only at whole-number values, thinned
    // so neighbouring labels never overprint. Fractional ticks stay bare —
    // rounding them ("0.3" under a mark at 1/3) prints a false value, and
    // labelling every tick lets the answer be read off the axis instead of
    // counted.
    final wholeTicks = <int>[];
    for (var i = 0; i <= spec.divisions; i++) {
      final v = spec.min + (spec.max - spec.min) * i / spec.divisions;
      final x = xFor(v);
      canvas.drawLine(
        Offset(x, lineY - 6),
        Offset(x, lineY + 6),
        linePaint,
      );
      if ((v - v.round()).abs() < 1e-9) wholeTicks.add(i);
    }
    if (wholeTicks.isNotEmpty) {
      double num2x(int i) =>
          xFor(spec.min + (spec.max - spec.min) * i / spec.divisions);
      // Widest label ("-10" is wider than "8") + breathing room decides
      // how many whole-number labels fit.
      var maxLabelW = 0.0;
      for (final i in wholeTicks) {
        final v = spec.min + (spec.max - spec.min) * i / spec.divisions;
        maxLabelW = math.max(maxLabelW, _measure(_formatValue(v)).width);
      }
      final minGap = maxLabelW + 8;
      final wholeSpacing = wholeTicks.length > 1
          ? num2x(wholeTicks[1]) - num2x(wholeTicks[0])
          : double.infinity;
      var step = 1;
      for (final s in const [1, 2, 5, 10, 20, 25, 50, 100]) {
        step = s;
        if (wholeSpacing * s >= minGap) break;
      }
      for (var k = 0; k < wholeTicks.length; k++) {
        final i = wholeTicks[k];
        final v = spec.min + (spec.max - spec.min) * i / spec.divisions;
        if (v.round() % step != 0) continue;
        _drawLabel(canvas, _formatValue(v), Offset(num2x(i), lineY + 18));
      }
    }

    // Marked points
    final markPaint = Paint()..color = markColor;
    for (final p in spec.markedPoints) {
      canvas.drawCircle(Offset(xFor(p), lineY), 6, markPaint);
    }

    // Hops (arcs)
    final hopPaint = Paint()
      ..color = hopColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final hop in spec.hops) {
      final fromX = xFor(hop.from);
      final toX = xFor(hop.to);
      final cx = (fromX + toX) / 2;
      final radius = (toX - fromX).abs() / 2;
      final rect = Rect.fromCircle(
        center: Offset(cx, lineY),
        radius: radius,
      );
      canvas.drawArc(rect, math.pi, math.pi, false, hopPaint);
      if (hop.label != null) {
        _drawLabel(
          canvas,
          hop.label!,
          Offset(cx, lineY - radius - 8),
        );
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center) {
    final tp = _measure(text);
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  TextPainter _measure(String text) => TextPainter(
    text: TextSpan(text: text, style: textStyle),
    textDirection: TextDirection.ltr,
  )..layout();

  static String _formatValue(num v) {
    if (v is int || v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(_NumberLinePainter old) =>
      old.spec != spec ||
      old.lineColor != lineColor ||
      old.markColor != markColor ||
      old.hopColor != hopColor;
}
