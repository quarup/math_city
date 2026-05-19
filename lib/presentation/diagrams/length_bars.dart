import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [LengthBarsSpec] as a stack of horizontal bars whose widths
/// are proportional to each row's measured length, so a kid can compare
/// lengths visually instead of doing the comparison in their head from
/// numeric values in the prompt.
class LengthBars extends StatelessWidget {
  const LengthBars({
    required this.spec,
    this.maxBarWidth = 220,
    this.barHeight = 22,
    this.rowGap = 8,
    super.key,
  });

  final LengthBarsSpec spec;
  final double maxBarWidth;
  final double barHeight;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final valueStyle =
        theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    final fill = theme.colorScheme.primary.withValues(alpha: 0.30);
    final edge = theme.colorScheme.onSurface;

    final maxLength = spec.bars.fold<int>(
      1,
      (m, b) => b.length > m ? b.length : m,
    );
    final maxLabelWidth = _maxLabelTextWidth(context, labelStyle);

    final rows = <Widget>[];
    for (var i = 0; i < spec.bars.length; i++) {
      final bar = spec.bars[i];
      final width = (bar.length / maxLength) * maxBarWidth;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : rowGap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: maxLabelWidth + 8,
                child: Text(
                  bar.label,
                  style: labelStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              Container(
                width: width,
                height: barHeight,
                decoration: BoxDecoration(
                  color: fill,
                  border: Border.all(color: edge, width: 1.2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text('${bar.length} ${spec.unit}', style: valueStyle),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  double _maxLabelTextWidth(BuildContext context, TextStyle style) {
    final dir = Directionality.maybeOf(context) ?? TextDirection.ltr;
    var maxWidth = 0.0;
    for (final b in spec.bars) {
      final tp = TextPainter(
        text: TextSpan(text: b.label, style: style),
        textDirection: dir,
        maxLines: 1,
      )..layout();
      if (tp.width > maxWidth) maxWidth = tp.width;
    }
    return maxWidth;
  }
}
