import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [BoxPlotSpec] as one or more box-and-whisker plots stacked
/// vertically above a shared horizontal axis. Each row shows:
///   - left-side row label (e.g. "A" / "B"),
///   - whisker line min → Q1,
///   - filled box from Q1 to Q3 with a vertical median line,
///   - whisker line Q3 → max,
///   - small vertical end caps at min and max.
class BoxPlot extends StatelessWidget {
  const BoxPlot({
    required this.spec,
    this.unitPx = 24,
    this.rowHeight = 56,
    super.key,
  });

  final BoxPlotSpec spec;
  final double unitPx;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const leftGutter = 36.0;
    const rightGutter = 16.0;
    const topGutter = 28.0;
    const bottomGutter = 40.0;
    final spanUnits = spec.maxX - spec.minX;
    final naturalWidth = spanUnits * unitPx;

    return LayoutBuilder(
      builder: (context, constraints) {
        var px = unitPx;
        if (constraints.maxWidth.isFinite) {
          final avail = constraints.maxWidth - leftGutter - rightGutter;
          if (avail > 0 && naturalWidth > avail) {
            px = avail / spanUnits;
          }
        }
        final plotWidth = spanUnits * px;
        final plotHeight = spec.summaries.length * rowHeight;
        return SizedBox(
          width: plotWidth + leftGutter + rightGutter,
          height: plotHeight + topGutter + bottomGutter,
          child: CustomPaint(
            painter: _BoxPlotPainter(
              spec: spec,
              unitPx: px,
              rowHeight: rowHeight,
              leftGutter: leftGutter,
              topGutter: topGutter,
              axisColor: theme.colorScheme.onSurface,
              boxFillColor: theme.colorScheme.primary.withValues(alpha: 0.35),
              boxBorderColor: theme.colorScheme.primary,
              medianColor: theme.colorScheme.tertiary,
              titleStyle:
                  (theme.textTheme.titleSmall ??
                          const TextStyle(fontSize: 13))
                      .copyWith(fontWeight: FontWeight.bold),
              tickStyle:
                  theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11),
              rowLabelStyle:
                  (theme.textTheme.labelMedium ??
                          const TextStyle(fontSize: 12))
                      .copyWith(fontWeight: FontWeight.bold),
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

class _BoxPlotPainter extends CustomPainter {
  _BoxPlotPainter({
    required this.spec,
    required this.unitPx,
    required this.rowHeight,
    required this.leftGutter,
    required this.topGutter,
    required this.axisColor,
    required this.boxFillColor,
    required this.boxBorderColor,
    required this.medianColor,
    required this.titleStyle,
    required this.tickStyle,
    required this.rowLabelStyle,
    required this.axisLabelStyle,
  });

  final BoxPlotSpec spec;
  final double unitPx;
  final double rowHeight;
  final double leftGutter;
  final double topGutter;
  final Color axisColor;
  final Color boxFillColor;
  final Color boxBorderColor;
  final Color medianColor;
  final TextStyle titleStyle;
  final TextStyle tickStyle;
  final TextStyle rowLabelStyle;
  final TextStyle axisLabelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.6;
    final whiskerPaint = Paint()
      ..color = boxBorderColor
      ..strokeWidth = 1.4;
    final boxFillPaint = Paint()..color = boxFillColor;
    final boxBorderPaint = Paint()
      ..color = boxBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final medianPaint = Paint()
      ..color = medianColor
      ..strokeWidth = 2.4;

    final plotLeft = leftGutter;
    final plotRight = size.width;
    final plotTop = topGutter;
    final plotBottom = topGutter + spec.summaries.length * rowHeight;

    // Title centred over the plot.
    _drawText(
      canvas,
      spec.title,
      Offset((plotLeft + plotRight) / 2, topGutter / 2),
      titleStyle,
    );

    double xFor(num v) =>
        plotLeft + (v - spec.minX) * unitPx;

    // Each row: row label on the left, then box plot.
    for (var i = 0; i < spec.summaries.length; i++) {
      final s = spec.summaries[i];
      final rowMid = plotTop + (i + 0.5) * rowHeight;
      final boxTop = rowMid - rowHeight * 0.30;
      final boxBottom = rowMid + rowHeight * 0.30;
      final capTop = rowMid - rowHeight * 0.18;
      final capBottom = rowMid + rowHeight * 0.18;

      // Row label left of the plot.
      if (s.label.isNotEmpty) {
        _drawText(
          canvas,
          s.label,
          Offset(plotLeft - 18, rowMid),
          rowLabelStyle,
        );
      }

      // Whiskers (min → Q1 and Q3 → max).
      canvas
        ..drawLine(
          Offset(xFor(s.min), rowMid),
          Offset(xFor(s.q1), rowMid),
          whiskerPaint,
        )
        ..drawLine(
          Offset(xFor(s.q3), rowMid),
          Offset(xFor(s.max), rowMid),
          whiskerPaint,
        )
        // End caps.
        ..drawLine(
          Offset(xFor(s.min), capTop),
          Offset(xFor(s.min), capBottom),
          whiskerPaint,
        )
        ..drawLine(
          Offset(xFor(s.max), capTop),
          Offset(xFor(s.max), capBottom),
          whiskerPaint,
        );

      // Box.
      final boxRect = Rect.fromLTRB(
        xFor(s.q1),
        boxTop,
        xFor(s.q3),
        boxBottom,
      );
      canvas
        ..drawRect(boxRect, boxFillPaint)
        ..drawRect(boxRect, boxBorderPaint)
        // Median line inside the box.
        ..drawLine(
          Offset(xFor(s.median), boxTop),
          Offset(xFor(s.median), boxBottom),
          medianPaint,
        );
    }

    // Horizontal axis at the bottom of the plot area.
    canvas.drawLine(
      Offset(plotLeft, plotBottom),
      Offset(plotRight - (size.width - plotRight), plotBottom),
      axisPaint,
    );

    // Tick marks + labels at every multiple of tickStep inside [minX, maxX].
    final firstTick = _ceilToStep(spec.minX, spec.tickStep);
    for (var v = firstTick; v <= spec.maxX; v += spec.tickStep) {
      final x = xFor(v);
      canvas.drawLine(
        Offset(x, plotBottom - 4),
        Offset(x, plotBottom + 4),
        axisPaint,
      );
      _drawText(canvas, '$v', Offset(x, plotBottom + 14), tickStyle);
    }

    // Axis label below tick numbers.
    _drawText(
      canvas,
      spec.axisLabel,
      Offset((plotLeft + plotRight) / 2, plotBottom + 30),
      axisLabelStyle,
    );
  }

  static int _ceilToStep(int n, int step) {
    if (n % step == 0) return n;
    final r = n % step;
    return n + (step - r);
  }

  void _drawText(Canvas canvas, String text, Offset centre, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(unitPx * 4, 64));
    tp.paint(
      canvas,
      Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_BoxPlotPainter old) =>
      old.spec != spec ||
      old.unitPx != unitPx ||
      old.rowHeight != rowHeight ||
      old.axisColor != axisColor ||
      old.boxFillColor != boxFillColor ||
      old.boxBorderColor != boxBorderColor ||
      old.medianColor != medianColor;
}
