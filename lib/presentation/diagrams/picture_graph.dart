import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [PictureGraphSpec]: title on top, one row per category
/// (row label on the left + icons stacked horizontally), and a "key"
/// line below the graph when [PictureGraphSpec.scale] > 1.
class PictureGraph extends StatelessWidget {
  const PictureGraph({
    required this.spec,
    super.key,
  });

  final PictureGraphSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 13)).copyWith(
          fontWeight: FontWeight.bold,
        );
    final labelStyle =
        theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    const iconStyle = TextStyle(fontSize: 20);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(spec.title, style: titleStyle),
          const SizedBox(height: 8),
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: List.generate(spec.rowLabels.length, (i) {
              final iconCount = spec.values[i] ~/ spec.scale;
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
                    child: Text(spec.rowLabels[i], style: labelStyle),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      spec.icons[i] * iconCount,
                      style: iconStyle,
                    ),
                  ),
                ],
              );
            }),
          ),
          if (spec.scale > 1) ...[
            const SizedBox(height: 6),
            Text(
              'Each picture = ${spec.scale}',
              style: labelStyle.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
