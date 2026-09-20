import 'package:flutter/material.dart';
import 'package:math_city/presentation/widgets/coin_icon.dart';

/// The construction-site HUD (city_builder.md §8.4): a bar plus
/// `paid / price 🪙` — the absolute, fixed total the player is working
/// toward. No percentage, no stage label; the site's art carries the stage.
///
/// [compact] is the AppBar form used over the wheel and the question
/// screens: a dark pill with the numbers and a thin bar underneath.
class SiteProgressBar extends StatelessWidget {
  const SiteProgressBar({
    required this.paid,
    required this.price,
    this.name,
    this.compact = false,
    super.key,
  });

  final int paid;
  final int price;

  /// What is being built, shown above the bar in the full form.
  final String? name;
  final bool compact;

  double get _fraction => price == 0 ? 1 : (paid / price).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (compact) {
      const textStyle = TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      );
      // AppBar actions get unbounded width, and a progress bar has no
      // intrinsic width of its own — size the pill to its text row.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CoinIcon(size: 16),
                  const SizedBox(width: 4),
                  Text('$paid / $price', style: textStyle),
                ],
              ),
              const SizedBox(height: 3),
              _Bar(fraction: _fraction, height: 4, theme: theme),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (name != null)
              Expanded(
                child: Text(
                  name!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Spacer(),
            const CoinIcon(size: 16),
            const SizedBox(width: 4),
            Text(
              '$paid / $price',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _Bar(fraction: _fraction, height: 10, theme: theme),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.height,
    required this.theme,
  });

  final double fraction;
  final double height;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: SizedBox(
      height: height,
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: height,
        backgroundColor: Colors.black.withValues(alpha: 0.15),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF9D648)),
      ),
    ),
  );
}
