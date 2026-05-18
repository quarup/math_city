import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [DotPlotSpec] as a horizontal axis (with one tick per integer
/// from `minX` to `maxX`) and a vertical stack of dots above each tick
/// representing the count of that value in the data.
///
/// Sizes itself to fit the available width when the parent constraint is
/// narrower than the natural width.
class DotPlot extends StatelessWidget {
  const DotPlot({
    required this.spec,
    this.tickSpacing = 36,
    this.dotRadius = 6,
    super.key,
  });

  final DotPlotSpec spec;
  final double tickSpacing;
  final double dotRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const leftGutter = 16.0;
    const rightGutter = 16.0;
    const topGutter = 28.0;
    const bottomGutter = 44.0;

    final ticks = spec.maxX - spec.minX + 1;
    final naturalWidth = (ticks - 1) * tickSpacing;

    // Tallest dot stack — determines plot height.
    final counts = <int, int>{};
    for (final v in spec.values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    final tallestStack = counts.values.fold<int>(0, math.max);
    final dotGap = dotRadius * 2.2;
    final plotHeight = math.max(tallestStack * dotGap, dotGap);

    return LayoutBuilder(
      builder: (context, constraints) {
        var ts = tickSpacing;
        if (constraints.maxWidth.isFinite) {
          final avail = constraints.maxWidth - leftGutter - rightGutter;
          if (avail > 0 && naturalWidth > avail) {
            ts = avail / (ticks - 1);
          }
        }
        final usableW = (ticks - 1) * ts;
        return SizedBox(
          width: usableW + leftGutter + rightGutter,
          height: plotHeight + topGutter + bottomGutter,
          child: CustomPaint(
            painter: _DotPlotPainter(
              spec: spec,
              counts: counts,
              tickSpacing: ts,
              dotRadius: dotRadius,
              dotGap: dotGap,
              plotHeight: plotHeight,
              leftGutter: leftGutter,
              topGutter: topGutter,
              axisColor: theme.colorScheme.onSurface,
              dotColor: theme.colorScheme.primary,
              titleStyle:
                  (theme.textTheme.titleSmall ??
                          const TextStyle(fontSize: 13))
                      .copyWith(fontWeight: FontWeight.bold),
              tickStyle:
                  theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11),
              axisLabelStyle:
                  theme.textTheme.labelMedium ??
                  const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}

class _DotPlotPainter extends CustomPainter {
  _DotPlotPainter({
    required this.spec,
    required this.counts,
    required this.tickSpacing,
    required this.dotRadius,
    required this.dotGap,
    required this.plotHeight,
    required this.leftGutter,
    required this.topGutter,
    required this.axisColor,
    required this.dotColor,
    required this.titleStyle,
    required this.tickStyle,
    required this.axisLabelStyle,
  });

  final DotPlotSpec spec;
  final Map<int, int> counts;
  final double tickSpacing;
  final double dotRadius;
  final double dotGap;
  final double plotHeight;
  final double leftGutter;
  final double topGutter;
  final Color axisColor;
  final Color dotColor;
  final TextStyle titleStyle;
  final TextStyle tickStyle;
  final TextStyle axisLabelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.6;
    final dotPaint = Paint()..color = dotColor;

    final axisY = topGutter + plotHeight;
    final ticks = spec.maxX - spec.minX + 1;

    // Title centred over the plot.
    _drawText(
      canvas,
      spec.title,
      Offset(size.width / 2, topGutter / 2),
      titleStyle,
    );

    // Horizontal axis with tick marks at every integer.
    canvas.drawLine(
      Offset(leftGutter, axisY),
      Offset(leftGutter + (ticks - 1) * tickSpacing, axisY),
      axisPaint,
    );

    double xFor(int v) => leftGutter + (v - spec.minX) * tickSpacing;

    for (var v = spec.minX; v <= spec.maxX; v++) {
      final x = xFor(v);
      canvas.drawLine(
        Offset(x, axisY - 4),
        Offset(x, axisY + 4),
        axisPaint,
      );
      _drawText(canvas, '$v', Offset(x, axisY + 14), tickStyle);
    }

    // Axis label below the tick numbers.
    _drawText(
      canvas,
      spec.axisLabel,
      Offset(size.width / 2, axisY + 32),
      axisLabelStyle,
    );

    // Dots: stack `count` dots vertically above each integer with `count > 0`.
    counts.forEach((v, count) {
      final x = xFor(v);
      for (var i = 0; i < count; i++) {
        final cy = axisY - dotRadius - i * dotGap - 2;
        canvas.drawCircle(Offset(x, cy), dotRadius, dotPaint);
      }
    });
  }

  void _drawText(Canvas canvas, String text, Offset centre, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout();
    tp.paint(
      canvas,
      Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_DotPlotPainter old) =>
      old.spec != spec ||
      old.tickSpacing != tickSpacing ||
      old.dotRadius != dotRadius ||
      old.dotGap != dotGap ||
      old.plotHeight != plotHeight ||
      old.axisColor != axisColor ||
      old.dotColor != dotColor;
}
