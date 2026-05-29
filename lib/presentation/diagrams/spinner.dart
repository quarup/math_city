import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [SpinnerSpec] as an equal-sector pie chart with a label
/// on each sector and an arrow pointer at the top. Sector colors are
/// looked up from a fixed name → color table so that "red" always
/// renders red etc.
class Spinner extends StatelessWidget {
  const Spinner({
    required this.spec,
    this.size = 200,
    super.key,
  });

  final SpinnerSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpinnerPainter(
          spec: spec,
          edge: theme.colorScheme.onSurface,
          labelStyle:
              (theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11))
                  .copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

// Fixed kid-friendly palette. Color names match the labels the
// probability generators pass into SpinnerSpec.sectors.
const Map<String, Color> _palette = {
  'red': Color(0xFFE53935),
  'blue': Color(0xFF1E88E5),
  'green': Color(0xFF43A047),
  'yellow': Color(0xFFFDD835),
  'purple': Color(0xFF8E24AA),
  'orange': Color(0xFFFB8C00),
  'black': Color(0xFF212121),
  'white': Color(0xFFFAFAFA),
};

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.spec,
    required this.edge,
    required this.labelStyle,
  });

  final SpinnerSpec spec;
  final Color edge;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 16;
    final n = spec.sectors.length;
    final sweep = 2 * math.pi / n;
    final stroke = Paint()
      ..color = edge
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    // Sectors. Start at -π/2 (12 o'clock) so the pointer aligns with
    // the boundary between sector 0 (left) and sector n-1 (right).
    const start = -math.pi / 2;
    for (var i = 0; i < n; i++) {
      final color = _palette[spec.sectors[i].toLowerCase()] ?? Colors.grey;
      final wedge = Path()
        ..moveTo(centre.dx, centre.dy)
        ..arcTo(
          Rect.fromCircle(center: centre, radius: r),
          start + i * sweep,
          sweep,
          false,
        )
        ..close();
      canvas
        ..drawPath(wedge, Paint()..color = color)
        ..drawPath(wedge, stroke);
    }

    // Sector labels — placed at 60% of radius along the wedge midline.
    for (var i = 0; i < n; i++) {
      final mid = start + (i + 0.5) * sweep;
      final lp = Offset(
        centre.dx + math.cos(mid) * r * 0.6,
        centre.dy + math.sin(mid) * r * 0.6,
      );
      // Pick black text on light sectors (yellow / white) for legibility.
      final fillName = spec.sectors[i].toLowerCase();
      final useDark = fillName == 'yellow' || fillName == 'white';
      final tp = TextPainter(
        text: TextSpan(
          text: spec.sectors[i],
          style: labelStyle.copyWith(
            color: useDark ? Colors.black87 : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lp.dx - tp.width / 2, lp.dy - tp.height / 2));
    }

    // Pointer — small triangle at the top.
    final pointer = Path()
      ..moveTo(centre.dx, centre.dy - r - 10)
      ..lineTo(centre.dx - 8, centre.dy - r + 2)
      ..lineTo(centre.dx + 8, centre.dy - r + 2)
      ..close();
    canvas
      ..drawPath(pointer, Paint()..color = edge)
      ..drawPath(pointer, stroke);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.spec != spec || old.edge != edge;
}
