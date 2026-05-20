import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [TwoWayTableSpec] as a bordered grid with header row +
/// header column + body counts. When [TwoWayTableSpec.showTotals] is
/// true, an extra Total row + Total column display row/column sums and
/// the grand total in the corner.
class TwoWayTable extends StatelessWidget {
  const TwoWayTable({required this.spec, super.key});

  final TwoWayTableSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline;
    final headerStyle =
        (theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12)).copyWith(
          fontWeight: FontWeight.bold,
        );
    final cellStyle =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final totalStyle = cellStyle.copyWith(
      fontStyle: FontStyle.italic,
      color: theme.colorScheme.onSurfaceVariant,
    );

    // Compute totals on the fly (used iff spec.showTotals).
    final rowTotals = [
      for (final row in spec.counts) row.reduce((a, b) => a + b),
    ];
    final colTotals = [
      for (var c = 0; c < spec.colLabels.length; c++)
        spec.counts.fold<int>(0, (sum, row) => sum + row[c]),
    ];
    final grandTotal = rowTotals.fold<int>(0, (a, b) => a + b);

    Widget cell(String text, {TextStyle? style, Color? fill}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: fill,
        alignment: Alignment.center,
        child: Text(text, style: style ?? cellStyle),
      );
    }

    final headerFill = theme.colorScheme.surfaceContainerHighest;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(spec.title, style: headerStyle),
        ),
        Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(color: borderColor),
          children: [
            TableRow(
              children: [
                cell('', fill: headerFill),
                for (final col in spec.colLabels)
                  cell(col, style: headerStyle, fill: headerFill),
                if (spec.showTotals)
                  cell('Total', style: headerStyle, fill: headerFill),
              ],
            ),
            for (var r = 0; r < spec.rowLabels.length; r++)
              TableRow(
                children: [
                  cell(
                    spec.rowLabels[r],
                    style: headerStyle,
                    fill: headerFill,
                  ),
                  for (var c = 0; c < spec.colLabels.length; c++)
                    cell('${spec.counts[r][c]}'),
                  if (spec.showTotals)
                    cell('${rowTotals[r]}', style: totalStyle),
                ],
              ),
            if (spec.showTotals)
              TableRow(
                children: [
                  cell('Total', style: headerStyle, fill: headerFill),
                  for (var c = 0; c < spec.colLabels.length; c++)
                    cell('${colTotals[c]}', style: totalStyle),
                  cell('$grandTotal', style: totalStyle),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
