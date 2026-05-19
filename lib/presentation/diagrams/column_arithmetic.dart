import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [ColumnArithmeticSpec] as a stacked column-arithmetic
/// layout: operands right-aligned, operator symbol left of the last
/// operand, horizontal rule, then the result. Small carry/borrow
/// annotations sit above each column when [ColumnArithmeticSpec.carries]
/// has a non-zero entry for that column.
///
/// Intended for the explanation screen after a wrong answer to a
/// multi-digit ± question — the kid sees the column-by-column
/// regrouping that produced the right answer.
class ColumnArithmetic extends StatelessWidget {
  const ColumnArithmetic({required this.spec, super.key});

  final ColumnArithmeticSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: 24,
      height: 1.1,
      color: theme.colorScheme.onSurface,
    );
    final carryStyle = monoStyle.copyWith(
      fontSize: 12,
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );

    final maxDigits = [
      ...spec.operands,
      spec.result,
    ].map((v) => v.toString().length).reduce((a, b) => a > b ? a : b);
    final columnCount = maxDigits + 1; // +1 column for the operator gutter
    final opChar = spec.op == ColumnArithmeticOp.add ? '+' : '−';

    Widget cell(String text, TextStyle style) => SizedBox(
      width: 24,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );

    List<Widget> rowFor(String text, {String? leadOp}) {
      final padded = text.padLeft(maxDigits);
      return [
        cell(leadOp ?? '', monoStyle),
        for (final c in padded.split('')) cell(c, monoStyle),
      ];
    }

    // Carry row: align with the column above. Index 0 is the ones
    // place, which sits at the right-most cell. The carry annotation
    // for column i is drawn over column (i + 1) from the right (i.e.
    // it's the carry coming *into* the column to its left).
    List<Widget> carryRow() {
      final carries = List<int>.filled(maxDigits, 0);
      for (var i = 0; i < spec.carries.length && i < maxDigits; i++) {
        carries[i] = spec.carries[i];
      }
      final cells = <Widget>[cell('', carryStyle)]; // operator gutter
      // Column-from-left k → place-value (maxDigits - 1 - k). The carry
      // annotation drawn above column k is the carry produced by column
      // (k + 1), i.e. carries[maxDigits - k - 2].
      for (var k = 0; k < maxDigits; k++) {
        final sourceCol = maxDigits - k - 2;
        final v = (sourceCol >= 0 && sourceCol < carries.length)
            ? carries[sourceCol]
            : 0;
        cells.add(cell(v == 0 ? '' : '$v', carryStyle));
      }
      return cells;
    }

    final showCarries = spec.carries.any((c) => c != 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCarries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: carryRow(),
            ),
          // Top operands.
          for (var i = 0; i < spec.operands.length - 1; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: rowFor('${spec.operands[i]}'),
            ),
          // Last operand with operator symbol in the gutter.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: rowFor(
              '${spec.operands.last}',
              leadOp: opChar,
            ),
          ),
          // Horizontal rule under the operands.
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            height: 2,
            width: columnCount * 24.0,
            color: theme.colorScheme.onSurface,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: rowFor('${spec.result}'),
          ),
        ],
      ),
    );
  }
}
