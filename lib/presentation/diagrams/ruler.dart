import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [RulerSpec] as a horizontal ruler: numbered tick marks at
/// every whole unit (with the unit label after the last one), shorter
/// unlabelled ticks at every subdivision, and a coloured "object" bar
/// drawn above the ruler from 0 to the marked length.
///
/// Sizes itself to the available width when constrained.
class Ruler extends StatelessWidget {
  const Ruler({
    required this.spec,
    this.height = 90,
    this.minWidthPerUnit = 38,
    super.key,
  });

  final RulerSpec spec;
  final double height;
  final double minWidthPerUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final natural = spec.totalLength * minWidthPerUnit + 36;
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth < natural ? constraints.maxWidth : natural)
            : natural;
        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _RulerPainter(
              spec: spec,
              barColor: theme.colorScheme.primary,
              edgeColor: theme.colorScheme.onSurface,
              tickColor: theme.colorScheme.onSurface,
              labelStyle:
                  theme.textTheme.labelSmall ??
                  const TextStyle(fontSize: 11),
            ),
          ),
        );
      },
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.spec,
    required this.barColor,
    required this.edgeColor,
    required this.tickColor,
    required this.labelStyle,
  });

  final RulerSpec spec;
  final Color barColor;
  final Color edgeColor;
  final Color tickColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 18.0;
    const barTop = 10.0;
    const barHeight = 18.0;
    const rulerTop = 38.0;
    const rulerHeight = 32.0;

    final usableW = size.width - 2 * padX;
    double xFor(num v) => padX + (v / spec.totalLength) * usableW;

    // Coloured bar above the ruler representing the measured object.
    final markedDisplay = spec.markedLength / spec.subdivisions;
    final barRect = Rect.fromLTRB(
      xFor(0),
      barTop,
      xFor(markedDisplay),
      barTop + barHeight,
    );
    canvas.drawRect(barRect, Paint()..color = barColor);

    // Ruler body.
    final rulerRect = Rect.fromLTRB(
      xFor(0),
      rulerTop,
      xFor(spec.totalLength),
      rulerTop + rulerHeight,
    );
    canvas.drawRect(
      rulerRect,
      Paint()
        ..color = edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.2;

    final totalSubdivs = spec.totalLength * spec.subdivisions;
    for (var i = 0; i <= totalSubdivs; i++) {
      final v = i / spec.subdivisions;
      final x = xFor(v);
      final isWhole = i % spec.subdivisions == 0;
      final tickH = isWhole ? 12.0 : 6.0;
      canvas.drawLine(
        Offset(x, rulerTop),
        Offset(x, rulerTop + tickH),
        tickPaint,
      );
      if (isWhole) {
        _drawLabel(
          canvas,
          '${v.toInt()}',
          Offset(x, rulerTop + tickH + 8),
        );
      }
    }
    // Unit label after the last tick.
    _drawLabel(
      canvas,
      spec.unitLabel,
      Offset(xFor(spec.totalLength) + 12, rulerTop + 4),
      alignLeft: true,
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset pos, {
    bool alignLeft = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignLeft ? pos.dx : pos.dx - tp.width / 2;
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.spec != spec ||
      old.barColor != barColor ||
      old.edgeColor != edgeColor ||
      old.tickColor != tickColor;
}
