import 'package:flutter/material.dart';
import 'package:math_dash/domain/questions/diagram_spec.dart';

/// Renders a [FractionBarSpec]: a horizontal bar with `denominator` equal
/// segments, the first `numerator` of which are shaded.
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
    final emptyColor = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.colorScheme.outline;

    return SizedBox(
      height: height,
      child: Row(
        children: List.generate(spec.denominator, (i) {
          final isShaded = i < spec.numerator;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: i == 0 ? 0 : 1,
              ),
              decoration: BoxDecoration(
                color: isShaded ? shadeColor : emptyColor,
                border: Border.all(color: borderColor, width: 1.5),
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(8) : Radius.zero,
                  right: i == spec.denominator - 1
                      ? const Radius.circular(8)
                      : Radius.zero,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
