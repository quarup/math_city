import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders an [AreaGridSpec] as a rows×cols grid of square cells. Cells
/// in the top `shadedRows` rows are shaded in the row color; cells in the
/// left `shadedCols` columns are shaded in the column color; the top-
/// left `shadedRows × shadedCols` overlap is the deepest "product"
/// color. Used for fraction × fraction (`mult_fractions_proper`) where
/// kids see a/cols horizontally, b/rows vertically, and the product as
/// the overlap rectangle.
class AreaGrid extends StatelessWidget {
  const AreaGrid({
    required this.spec,
    this.cellSize = 22,
    super.key,
  });

  final AreaGridSpec spec;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overlapColor = theme.colorScheme.primary;
    final colShade = theme.colorScheme.primary.withValues(alpha: 0.4);
    final rowShade = theme.colorScheme.secondary.withValues(alpha: 0.4);
    final emptyColor = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.colorScheme.outline;

    return SizedBox(
      width: cellSize * spec.cols,
      height: cellSize * spec.rows,
      child: Column(
        children: List.generate(spec.rows, (r) {
          final inRow = r < spec.shadedRows;
          return Expanded(
            child: Row(
              children: List.generate(spec.cols, (c) {
                final inCol = c < spec.shadedCols;
                final color = inRow && inCol
                    ? overlapColor
                    : inRow
                    ? rowShade
                    : inCol
                    ? colShade
                    : emptyColor;
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: borderColor, width: 0.8),
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
