import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders an [AreaGridSpec] as a rows×cols grid of square cells. Cells
/// in the top `shadedRows` rows are shaded in the row color; cells in the
/// left `shadedCols` columns are shaded in the column color; the top-
/// left `shadedRows × shadedCols` overlap is the deepest "product"
/// color. Used for fraction × fraction (`mult_fractions_proper`) where
/// kids see a/cols horizontally, b/rows vertically, and the product as
/// the overlap rectangle.
///
/// [AreaGridSpec.count] switches to the counting layout instead: exactly
/// `shadedCount` shapes, row-major, with a shorter final row. No empty
/// placeholder cells are drawn, so counting what's on screen always
/// yields the answer.
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

    final count = spec.shadedCount;
    if (count != null) {
      return _CountGrid(
        count: count,
        cols: spec.cols,
        cellSize: cellSize,
        fill: overlapColor,
        borderColor: borderColor,
      );
    }

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

/// The counting layout for [AreaGridSpec.count]: [count] shapes at [cols]
/// per row, left-aligned, with a shorter last row. Cells are fixed-size
/// (not `Expanded`) so a short final row keeps its objects the same size as
/// the rows above instead of stretching them across the full width.
class _CountGrid extends StatelessWidget {
  const _CountGrid({
    required this.count,
    required this.cols,
    required this.cellSize,
    required this.fill,
    required this.borderColor,
  });

  final int count;
  final int cols;
  final double cellSize;
  final Color fill;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final rows = (count + cols - 1) ~/ cols;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(rows, (r) {
        final inThisRow = (count - r * cols).clamp(0, cols);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            inThisRow,
            (_) => Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(color: borderColor, width: 0.8),
              ),
            ),
          ),
        );
      }),
    );
  }
}
