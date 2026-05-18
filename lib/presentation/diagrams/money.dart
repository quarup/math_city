import 'package:flutter/material.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';

/// Renders a [MoneySpec] as a left-to-right row of coins (circles) and
/// bills (rounded rectangles), each labelled with its face value. The
/// art is deliberately schematic — labelled shapes, not photo-realistic
/// coin renders — so no third-party art assets are needed (license-safe
/// per `curriculum.md` §6.2).
class Money extends StatelessWidget {
  const Money({required this.spec, super.key});

  final MoneySpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: spec.items
            .map((d) => _MoneyChip(denom: d, theme: theme))
            .toList(),
      ),
    );
  }
}

class _MoneyChip extends StatelessWidget {
  const _MoneyChip({required this.denom, required this.theme});

  final MoneyDenom denom;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isCoin = denom.isCoin;
    final coinColor = _coinColor(denom, theme);
    final billColor = theme.colorScheme.tertiaryContainer;
    final labelStyle =
        (theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12))
            .copyWith(fontWeight: FontWeight.bold);

    if (isCoin) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: coinColor,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.outline, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(denom.label, style: labelStyle),
      );
    }
    return Container(
      width: 64,
      height: 36,
      decoration: BoxDecoration(
        color: billColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outline, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(denom.label, style: labelStyle),
    );
  }

  Color _coinColor(MoneyDenom d, ThemeData theme) => switch (d) {
    // Color hints kids would recognise: penny copper, nickel/dime/quarter
    // shades of grey, rendered through the theme's surface palette to stay
    // readable in dark mode.
    MoneyDenom.penny => const Color(0xFFD79667),
    MoneyDenom.nickel => const Color(0xFFB7B7B7),
    MoneyDenom.dime => const Color(0xFFC8C8C8),
    MoneyDenom.quarter => const Color(0xFFA8A8A8),
    _ => theme.colorScheme.surfaceContainerHighest,
  };
}
