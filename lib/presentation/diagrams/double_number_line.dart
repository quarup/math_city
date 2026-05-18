import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [DoubleNumberLineSpec] as two horizontal number lines
/// stacked vertically with corresponding tick positions. Top and
/// bottom share the same horizontal ticks so the kid sees the i-th
/// tick on each line as one proportional pair.
class DoubleNumberLine extends StatelessWidget {
  const DoubleNumberLine({
    required this.spec,
    this.height = 110,
    this.minWidth = 240,
    super.key,
  });

  final DoubleNumberLineSpec spec;
  final double height;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    assert(
      spec.topValues.length == spec.bottomValues.length,
      'top and bottom values must align (same length)',
    );
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(minWidth, double.infinity)
            : minWidth;
        return SizedBox(
          width: w,
          height: height,
          child: CustomPaint(
            painter: _DoubleNumberLinePainter(
              spec: spec,
              edge: theme.colorScheme.onSurface,
              labelStyle: theme.textTheme.labelSmall ??
                  const TextStyle(fontSize: 11),
              titleStyle: theme.textTheme.labelMedium ??
                  const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}

class _DoubleNumberLinePainter extends CustomPainter {
  _DoubleNumberLinePainter({
    required this.spec,
    required this.edge,
    required this.labelStyle,
    required this.titleStyle,
  });

  final DoubleNumberLineSpec spec;
  final Color edge;
  final TextStyle labelStyle;
  final TextStyle titleStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 24.0;
    final usableW = size.width - 2 * padX;
    final stroke = Paint()
      ..color = edge
      ..strokeWidth = 1.4;

    final n = spec.topValues.length;
    double xAt(int i) => padX + (i / (n - 1)) * usableW;

    final topY = (spec.topLabel != null) ? 30.0 : 24.0;
    final botY = size.height - ((spec.bottomLabel != null) ? 30.0 : 24.0);

    // Axes.
    canvas
      ..drawLine(Offset(padX, topY), Offset(size.width - padX, topY), stroke)
      ..drawLine(Offset(padX, botY), Offset(size.width - padX, botY), stroke);

    // Ticks + labels.
    for (var i = 0; i < n; i++) {
      final x = xAt(i);
      canvas
        ..drawLine(Offset(x, topY - 5), Offset(x, topY + 5), stroke)
        ..drawLine(Offset(x, botY - 5), Offset(x, botY + 5), stroke);
      _drawText(canvas, '${spec.topValues[i]}', Offset(x, topY - 14),
          labelStyle);
      _drawText(canvas, '${spec.bottomValues[i]}', Offset(x, botY + 14),
          labelStyle);
    }

    if (spec.topLabel != null) {
      _drawText(canvas, spec.topLabel!, Offset(padX, topY - 28), titleStyle,
          alignLeft: true);
    }
    if (spec.bottomLabel != null) {
      _drawText(canvas, spec.bottomLabel!, Offset(padX, botY + 28),
          titleStyle,
          alignLeft: true);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    TextStyle style, {
    bool alignLeft = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignLeft ? pos.dx : pos.dx - tp.width / 2;
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DoubleNumberLinePainter old) =>
      old.spec != spec || old.edge != edge;
}
