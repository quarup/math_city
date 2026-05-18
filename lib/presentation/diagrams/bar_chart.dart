import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [BarChartSpec] as a vertical bar chart: title up top,
/// y-axis with gridlines every `scale` units on the left, one coloured
/// bar per category, category label below each bar.
///
/// Sizes itself to fit the available width when the parent constraint is
/// narrower than the natural size (same approach as `CoordinatePlane`).
class BarChart extends StatelessWidget {
  const BarChart({
    required this.spec,
    this.barWidth = 36,
    this.barGap = 18,
    this.plotHeight = 160,
    super.key,
  });

  final BarChartSpec spec;
  final double barWidth;
  final double barGap;
  final double plotHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const leftGutter = 36.0;
    const rightGutter = 12.0;
    const topGutter = 28.0;
    const bottomGutter = 30.0;
    final naturalBars = spec.labels.length * barWidth +
        (spec.labels.length + 1) * barGap;
    return LayoutBuilder(
      builder: (context, constraints) {
        var bw = barWidth;
        var gap = barGap;
        if (constraints.maxWidth.isFinite) {
          final availPlot =
              constraints.maxWidth - leftGutter - rightGutter;
          if (availPlot > 0 && naturalBars > availPlot) {
            final scaleFactor = availPlot / naturalBars;
            bw = barWidth * scaleFactor;
            gap = barGap * scaleFactor;
          }
        }
        final plotWidth =
            spec.labels.length * bw + (spec.labels.length + 1) * gap;
        return SizedBox(
          width: plotWidth + leftGutter + rightGutter,
          height: plotHeight + topGutter + bottomGutter,
          child: CustomPaint(
            painter: _BarChartPainter(
              spec: spec,
              barWidth: bw,
              barGap: gap,
              plotHeight: plotHeight,
              leftGutter: leftGutter,
              topGutter: topGutter,
              gridColor: theme.colorScheme.outlineVariant,
              axisColor: theme.colorScheme.onSurface,
              barColor: theme.colorScheme.primary,
              titleStyle:
                  (theme.textTheme.titleSmall ??
                          const TextStyle(fontSize: 13))
                      .copyWith(fontWeight: FontWeight.bold),
              tickStyle:
                  theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11),
              labelStyle:
                  theme.textTheme.labelMedium ??
                  const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.spec,
    required this.barWidth,
    required this.barGap,
    required this.plotHeight,
    required this.leftGutter,
    required this.topGutter,
    required this.gridColor,
    required this.axisColor,
    required this.barColor,
    required this.titleStyle,
    required this.tickStyle,
    required this.labelStyle,
  });

  final BarChartSpec spec;
  final double barWidth;
  final double barGap;
  final double plotHeight;
  final double leftGutter;
  final double topGutter;
  final Color gridColor;
  final Color axisColor;
  final Color barColor;
  final TextStyle titleStyle;
  final TextStyle tickStyle;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.6;
    final barPaint = Paint()..color = barColor;

    final plotLeft = leftGutter;
    final plotRight = size.width;
    final plotTop = topGutter;
    final plotBottom = topGutter + plotHeight;

    // Title centred over the plot area.
    _drawText(
      canvas,
      spec.title,
      Offset((plotLeft + plotRight) / 2, topGutter / 2),
      titleStyle,
    );

    // Horizontal gridlines at every multiple of scale up to maxY, plus
    // labels on the left for each tick.
    final ticks = spec.maxY ~/ spec.scale;
    double yFor(num v) =>
        plotBottom - (v / spec.maxY) * plotHeight;
    for (var i = 0; i <= ticks; i++) {
      final value = i * spec.scale;
      final y = yFor(value);
      canvas.drawLine(
        Offset(plotLeft, y),
        Offset(plotRight, y),
        i == 0 ? axisPaint : gridPaint,
      );
      _drawText(
        canvas,
        '$value',
        Offset(plotLeft - 12, y),
        tickStyle,
      );
    }
    // Bold left axis.
    canvas.drawLine(
      Offset(plotLeft, plotTop),
      Offset(plotLeft, plotBottom),
      axisPaint,
    );

    // Bars + category labels.
    for (var i = 0; i < spec.labels.length; i++) {
      final v = spec.values[i];
      final left = plotLeft + barGap + i * (barWidth + barGap);
      final top = yFor(v);
      if (v > 0) {
        canvas.drawRect(
          Rect.fromLTRB(left, top, left + barWidth, plotBottom),
          barPaint,
        );
      }
      // Category label centred under the bar.
      _drawText(
        canvas,
        spec.labels[i],
        Offset(left + barWidth / 2, plotBottom + 14),
        labelStyle,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset centre, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(barWidth + barGap, 48));
    tp.paint(
      canvas,
      Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.spec != spec ||
      old.barWidth != barWidth ||
      old.barGap != barGap ||
      old.plotHeight != plotHeight ||
      old.gridColor != gridColor ||
      old.axisColor != axisColor ||
      old.barColor != barColor;
}
