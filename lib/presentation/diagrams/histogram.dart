import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [HistogramSpec] as a row of adjacent (no-gap) bars with
/// numeric bin-boundary labels under each tick mark. Unlike `BarChart`
/// (categorical, gaps between bars), the histogram's continuous x-axis
/// requires bars to touch and tick labels to fall on bin boundaries.
class Histogram extends StatelessWidget {
  const Histogram({
    required this.spec,
    this.barWidth = 44,
    this.plotHeight = 160,
    super.key,
  });

  final HistogramSpec spec;
  final double barWidth;
  final double plotHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const leftGutter = 36.0;
    const rightGutter = 12.0;
    const topGutter = 28.0;
    const bottomGutter = 40.0;
    final naturalWidth = spec.counts.length * barWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        var bw = barWidth;
        if (constraints.maxWidth.isFinite) {
          final avail = constraints.maxWidth - leftGutter - rightGutter;
          if (avail > 0 && naturalWidth > avail) {
            bw = avail / spec.counts.length;
          }
        }
        final plotWidth = spec.counts.length * bw;
        return SizedBox(
          width: plotWidth + leftGutter + rightGutter,
          height: plotHeight + topGutter + bottomGutter,
          child: CustomPaint(
            painter: _HistogramPainter(
              spec: spec,
              barWidth: bw,
              plotHeight: plotHeight,
              leftGutter: leftGutter,
              topGutter: topGutter,
              gridColor: theme.colorScheme.outlineVariant,
              axisColor: theme.colorScheme.onSurface,
              barColor: theme.colorScheme.primary,
              barBorderColor: theme.colorScheme.onPrimary.withValues(
                alpha: 0.3,
              ),
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

class _HistogramPainter extends CustomPainter {
  _HistogramPainter({
    required this.spec,
    required this.barWidth,
    required this.plotHeight,
    required this.leftGutter,
    required this.topGutter,
    required this.gridColor,
    required this.axisColor,
    required this.barColor,
    required this.barBorderColor,
    required this.titleStyle,
    required this.tickStyle,
    required this.axisLabelStyle,
  });

  final HistogramSpec spec;
  final double barWidth;
  final double plotHeight;
  final double leftGutter;
  final double topGutter;
  final Color gridColor;
  final Color axisColor;
  final Color barColor;
  final Color barBorderColor;
  final TextStyle titleStyle;
  final TextStyle tickStyle;
  final TextStyle axisLabelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.6;
    final barPaint = Paint()..color = barColor;
    final borderPaint = Paint()
      ..color = barBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final plotLeft = leftGutter;
    final plotRight = size.width;
    final plotTop = topGutter;
    final plotBottom = topGutter + plotHeight;

    // Title centred over the plot.
    _drawText(
      canvas,
      spec.title,
      Offset((plotLeft + plotRight) / 2, topGutter / 2),
      titleStyle,
    );

    // y-axis gridlines + tick labels at every multiple of scale.
    final ticks = spec.maxY ~/ spec.scale;
    double yFor(num v) => plotBottom - (v / spec.maxY) * plotHeight;
    for (var i = 0; i <= ticks; i++) {
      final value = i * spec.scale;
      final y = yFor(value);
      canvas.drawLine(
        Offset(plotLeft, y),
        Offset(plotRight, y),
        i == 0 ? axisPaint : gridPaint,
      );
      _drawText(canvas, '$value', Offset(plotLeft - 12, y), tickStyle);
    }
    // Bold left axis.
    canvas.drawLine(
      Offset(plotLeft, plotTop),
      Offset(plotLeft, plotBottom),
      axisPaint,
    );

    // Adjacent bars + bin-boundary tick labels.
    for (var i = 0; i < spec.counts.length; i++) {
      final c = spec.counts[i];
      final left = plotLeft + i * barWidth;
      final right = left + barWidth;
      final top = yFor(c);
      if (c > 0) {
        final rect = Rect.fromLTRB(left, top, right, plotBottom);
        canvas
          ..drawRect(rect, barPaint)
          ..drawRect(rect, borderPaint);
      }
      // Tick boundary + label at the LEFT edge of every bin.
      final binLow = spec.binStart + i * spec.binWidth;
      _drawText(canvas, '$binLow', Offset(left, plotBottom + 12), tickStyle);
    }
    // Final right-edge tick label (closes the last bin).
    final lastBinHigh =
        spec.binStart + spec.counts.length * spec.binWidth;
    _drawText(
      canvas,
      '$lastBinHigh',
      Offset(plotLeft + spec.counts.length * barWidth, plotBottom + 12),
      tickStyle,
    );

    // Axis label below the tick numbers.
    _drawText(
      canvas,
      spec.axisLabel,
      Offset((plotLeft + plotRight) / 2, plotBottom + 30),
      axisLabelStyle,
    );
  }

  void _drawText(Canvas canvas, String text, Offset centre, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(barWidth, 64));
    tp.paint(
      canvas,
      Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_HistogramPainter old) =>
      old.spec != spec ||
      old.barWidth != barWidth ||
      old.plotHeight != plotHeight ||
      old.gridColor != gridColor ||
      old.axisColor != axisColor ||
      old.barColor != barColor;
}
