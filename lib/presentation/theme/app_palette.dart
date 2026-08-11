import 'package:flutter/material.dart';

/// Game-specific color tokens that don't fit Material's `ColorScheme` slots.
///
/// Use via `Theme.of(context).extension<AppPalette>()!` rather than
/// hardcoding `Color(0xFF...)` literals in widgets.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.skyGradientStart,
    required this.skyGradientEnd,
    required this.brandTealDeep,
    required this.coinGold,
    required this.coinGoldDeep,
    required this.streakOrange,
    required this.successGreen,
    required this.successGreenSoft,
    required this.successGreenDeep,
    required this.errorRedSoft,
    required this.errorRedDeep,
    required this.cityHillGreen,
  });

  final Color skyGradientStart;
  final Color skyGradientEnd;

  /// Deeper companion to `colorScheme.primary` (the logo teal) for anything
  /// that has to read against the sky gradient or a light surface.
  ///
  /// The logo teal is far too light to carry contrast on this app's light
  /// grounds — as a label on the sky it lands at 1.3:1, and white text on a
  /// teal fill at 2.6:1, both well under WCAG's 4.5:1 for text and 3:1 for
  /// UI shapes. This tone clears both: 3.1:1 as a fill against the sky,
  /// 6.1:1 for white text on it, and 5.0:1 as a label on `surfaceContainer`.
  /// Use it for buttons and labels; keep `primary` for large decorative fills
  /// where contrast isn't load-bearing.
  final Color brandTealDeep;

  /// Star/coin yellow (logo gear inner).
  final Color coinGold;

  /// Deeper companion to [coinGold] for text contrast on light backgrounds.
  final Color coinGoldDeep;

  final Color streakOrange;

  /// Brand success accent (city hills tone).
  final Color successGreen;

  /// Light green tint for "correct answer" surface backgrounds.
  final Color successGreenSoft;

  /// Deep green for emphatic correct-answer text.
  final Color successGreenDeep;

  /// Light red tint for "wrong answer" surface backgrounds.
  final Color errorRedSoft;

  /// Deep red for emphatic wrong-answer text.
  final Color errorRedDeep;

  final Color cityHillGreen;

  static const light = AppPalette(
    skyGradientStart: Color(0xFF5DB7E8),
    skyGradientEnd: Color(0xFFA4DDC9),
    brandTealDeep: Color(0xFF0E6E62),
    coinGold: Color(0xFFF0CC30),
    coinGoldDeep: Color(0xFFB8860B),
    streakOrange: Color(0xFFF2A33A),
    successGreen: Color(0xFF3DA85F),
    successGreenSoft: Color(0xFFE3F4E5),
    successGreenDeep: Color(0xFF2E7D32),
    errorRedSoft: Color(0xFFFCE4E2),
    errorRedDeep: Color(0xFFC62828),
    cityHillGreen: Color(0xFF5BBF7A),
  );

  @override
  AppPalette copyWith({
    Color? skyGradientStart,
    Color? skyGradientEnd,
    Color? brandTealDeep,
    Color? coinGold,
    Color? coinGoldDeep,
    Color? streakOrange,
    Color? successGreen,
    Color? successGreenSoft,
    Color? successGreenDeep,
    Color? errorRedSoft,
    Color? errorRedDeep,
    Color? cityHillGreen,
  }) {
    return AppPalette(
      skyGradientStart: skyGradientStart ?? this.skyGradientStart,
      skyGradientEnd: skyGradientEnd ?? this.skyGradientEnd,
      brandTealDeep: brandTealDeep ?? this.brandTealDeep,
      coinGold: coinGold ?? this.coinGold,
      coinGoldDeep: coinGoldDeep ?? this.coinGoldDeep,
      streakOrange: streakOrange ?? this.streakOrange,
      successGreen: successGreen ?? this.successGreen,
      successGreenSoft: successGreenSoft ?? this.successGreenSoft,
      successGreenDeep: successGreenDeep ?? this.successGreenDeep,
      errorRedSoft: errorRedSoft ?? this.errorRedSoft,
      errorRedDeep: errorRedDeep ?? this.errorRedDeep,
      cityHillGreen: cityHillGreen ?? this.cityHillGreen,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      skyGradientStart: Color.lerp(
        skyGradientStart,
        other.skyGradientStart,
        t,
      )!,
      skyGradientEnd: Color.lerp(skyGradientEnd, other.skyGradientEnd, t)!,
      brandTealDeep: Color.lerp(brandTealDeep, other.brandTealDeep, t)!,
      coinGold: Color.lerp(coinGold, other.coinGold, t)!,
      coinGoldDeep: Color.lerp(coinGoldDeep, other.coinGoldDeep, t)!,
      streakOrange: Color.lerp(streakOrange, other.streakOrange, t)!,
      successGreen: Color.lerp(successGreen, other.successGreen, t)!,
      successGreenSoft: Color.lerp(
        successGreenSoft,
        other.successGreenSoft,
        t,
      )!,
      successGreenDeep: Color.lerp(
        successGreenDeep,
        other.successGreenDeep,
        t,
      )!,
      errorRedSoft: Color.lerp(errorRedSoft, other.errorRedSoft, t)!,
      errorRedDeep: Color.lerp(errorRedDeep, other.errorRedDeep, t)!,
      cityHillGreen: Color.lerp(cityHillGreen, other.cityHillGreen, t)!,
    );
  }
}
