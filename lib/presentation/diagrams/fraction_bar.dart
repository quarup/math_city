import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [FractionBarSpec]: a horizontal bar with `denominator` equal
/// segments, the first `numerator` of which are shaded.
///
/// With [FractionBarSpec.subdivideShaded] set, each shaded segment is
/// split into that many sub-pieces with the first highlighted — the
/// "split 1/n into m parts" picture for fraction ÷ whole. With
/// [FractionBarSpec.bars] > 1 the bar repeats vertically — the "m wholes
/// cut into n pieces each" picture for whole ÷ unit-fraction.
class FractionBar extends StatelessWidget {
  const FractionBar({
    required this.spec,
    this.height = 56,
    super.key,
  });

  final FractionBarSpec spec;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadeColor = theme.colorScheme.primary;
    final highlightColor = theme.colorScheme.tertiary;
    final emptyColor = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.colorScheme.outline;

    // Stacked bars stay compact so several wholes fit on screen.
    final barHeight = spec.bars > 1 ? 36.0 : height;

    Widget cell(int i, {required bool shaded}) {
      final sub = spec.subdivideShaded;
      final child = (shaded && sub != null)
          ? Row(
              children: List.generate(sub, (j) {
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      // First sub-piece pops: it is the answer 1/(n·m).
                      color: j == 0
                          ? highlightColor
                          : shadeColor.withValues(alpha: 0.35),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                  ),
                );
              }),
            )
          : null;
      return Expanded(
        child: Container(
          margin: EdgeInsets.only(left: i == 0 ? 0 : 1),
          decoration: BoxDecoration(
            color: child != null ? null : (shaded ? shadeColor : emptyColor),
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.horizontal(
              left: i == 0 ? const Radius.circular(8) : Radius.zero,
              right: i == spec.denominator - 1
                  ? const Radius.circular(8)
                  : Radius.zero,
            ),
          ),
          child: child,
        ),
      );
    }

    Widget bar() => SizedBox(
      height: barHeight,
      child: Row(
        children: [
          for (var i = 0; i < spec.denominator; i++)
            cell(i, shaded: i < spec.numerator),
        ],
      ),
    );

    if (spec.bars == 1) return bar();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var b = 0; b < spec.bars; b++)
          Padding(
            padding: EdgeInsets.only(top: b == 0 ? 0 : 6),
            child: bar(),
          ),
      ],
    );
  }
}
