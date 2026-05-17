import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [PercentGridSpec] as a 10×10 grid of cells with the first
/// [PercentGridSpec.shadedCount] cells filled in row-major order.
/// Used for `percent_intro` to make the meaning "N out of 100" visually
/// concrete.
class PercentGrid extends StatelessWidget {
  const PercentGrid({required this.spec, this.cellSize = 18, super.key});

  static const _gridSide = 10;

  final PercentGridSpec spec;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadedColor = theme.colorScheme.primary;
    final emptyColor = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.colorScheme.outline;

    return SizedBox(
      width: cellSize * _gridSide,
      height: cellSize * _gridSide,
      child: Column(
        children: List.generate(_gridSide, (r) {
          return Expanded(
            child: Row(
              children: List.generate(_gridSide, (c) {
                final index = r * _gridSide + c;
                final shaded = index < spec.shadedCount;
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: shaded ? shadedColor : emptyColor,
                      border: Border.all(color: borderColor, width: 0.6),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
