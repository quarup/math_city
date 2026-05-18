import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [Net3DSpec] as an unfolded cube net in the canonical
/// "T" / "plus" cross layout: 4 squares in a horizontal row, with the
/// top and bottom faces sticking up and down from the second square
/// in the row. Total 6 connected squares.
///
///        ┌───┐
///        │ T │
///    ┌───┼───┼───┬───┐
///    │ L │ F │ R │ B │
///    └───┼───┼───┴───┘
///        │ Bm│
///        └───┘
class Net3D extends StatelessWidget {
  const Net3D({
    required this.spec,
    this.cellPixels = 38,
    super.key,
  });

  final Net3DSpec spec;
  final double cellPixels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: cellPixels * 4 + 16,
      height: cellPixels * 3 + 16,
      child: CustomPaint(
        painter: _Net3DPainter(
          spec: spec,
          edge: theme.colorScheme.onSurface,
          fill: theme.colorScheme.primary.withValues(alpha: 0.14),
          labelStyle:
              theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12),
          cellPixels: cellPixels,
        ),
      ),
    );
  }
}

class _Net3DPainter extends CustomPainter {
  _Net3DPainter({
    required this.spec,
    required this.edge,
    required this.fill,
    required this.labelStyle,
    required this.cellPixels,
  });

  final Net3DSpec spec;
  final Color edge;
  final Color fill;
  final TextStyle labelStyle;
  final double cellPixels;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = edge
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()..color = fill;

    const padX = 8.0;
    const padY = 8.0;
    final c = cellPixels;

    // 6 face rectangles. Centre-row at y = padY + c (so top sticks
    // above and bottom hangs below).
    final faces = <Rect>[
      // Top face — above column 1.
      Rect.fromLTWH(padX + c, padY, c, c),
      // Centre row: L, F, R, B (B = back).
      Rect.fromLTWH(padX, padY + c, c, c),
      Rect.fromLTWH(padX + c, padY + c, c, c),
      Rect.fromLTWH(padX + 2 * c, padY + c, c, c),
      Rect.fromLTWH(padX + 3 * c, padY + c, c, c),
      // Bottom face — below column 1.
      Rect.fromLTWH(padX + c, padY + 2 * c, c, c),
    ];

    for (final r in faces) {
      canvas
        ..drawRect(r, fillPaint)
        ..drawRect(r, stroke);
    }

    // Label one face with the edge length so the kid sees the scale.
    _drawText(
      canvas,
      '${spec.edgeLength}',
      Offset(padX + c + c / 2, padY + c + c / 2),
    );
  }

  void _drawText(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_Net3DPainter old) =>
      old.spec != spec ||
      old.edge != edge ||
      old.fill != fill ||
      old.cellPixels != cellPixels;
}
