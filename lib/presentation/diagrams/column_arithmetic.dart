import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [ColumnArithmeticSpec] as a stacked column-arithmetic
/// layout: operands right-aligned, operator symbol left of the last
/// operand, horizontal rule, then the result. Small carry/borrow
/// annotations sit above each column when [ColumnArithmeticSpec.carries]
/// has a non-zero entry for that column.
///
/// Used both as the question itself for multi-digit ± (result null, so
/// the answer row shows `?`) and on the explanation screen afterwards,
/// where the filled-in result and the carry marks show the
/// column-by-column regrouping.
class ColumnArithmetic extends StatelessWidget {
  const ColumnArithmetic({required this.spec, super.key});

  final ColumnArithmeticSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A question column is the focal point of its screen; the explanation
    // one sits underneath the worked steps, so it stays smaller.
    final isQuestion = spec.result == null;
    final digitSize = isQuestion ? 34.0 : 24.0;
    // Just wider than a monospace digit — enough that the columns read as
    // columns, tight enough that "10" still reads as ten rather than as a
    // 1 next to a 0.
    final cellWidth = digitSize * 0.68;
    final monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: digitSize,
      height: 1.1,
      color: theme.colorScheme.onSurface,
    );
    final carryStyle = monoStyle.copyWith(
      fontSize: digitSize / 2,
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );

    final result = spec.result;
    final maxDigits = [
      ...spec.operands,
      ?result,
    ].map((v) => v.toString().length).reduce((a, b) => a > b ? a : b);
    final columnCount = maxDigits + 1; // +1 column for the operator gutter
    final opChar = spec.op == ColumnArithmeticOp.add ? '+' : '−';

    Widget cell(String text, TextStyle style) => SizedBox(
      width: cellWidth,
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
            width: columnCount * cellWidth,
            color: theme.colorScheme.onSurface,
          ),
          if (result != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: rowFor('$result'),
            )
          else
            // Blank space under the rule, the way a worksheet leaves it.
            // A `?` here reads as a fifth digit sitting in the column, and
            // in keypad mode it collides with the `?` in the answer field.
            // The row is still reserved so the figure doesn't stop dead at
            // the rule.
            SizedBox(height: digitSize * 1.1),
        ],
      ),
    );
  }
}
