import 'package:flutter/material.dart';

/// Game-specific color tokens that don't fit Material's `ColorScheme` slots.
///
/// Use via `Theme.of(context).extension<AppPalette>()!` rather than
/// hardcoding `Color(0xFF...)` literals in widgets.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.skyGradientStart,
    required this.skyGradientEnd,
    required this.coinGold,
    required this.streakOrange,
    required this.successGreen,
    required this.cityHillGreen,
  });

  final Color skyGradientStart;
  final Color skyGradientEnd;
  final Color coinGold;
  final Color streakOrange;
  final Color successGreen;
  final Color cityHillGreen;

  static const light = AppPalette(
    skyGradientStart: Color(0xFF5DB7E8),
    skyGradientEnd: Color(0xFFA4DDC9),
    coinGold: Color(0xFFF0CC30),
    streakOrange: Color(0xFFF2A33A),
    successGreen: Color(0xFF3DA85F),
    cityHillGreen: Color(0xFF5BBF7A),
  );

  @override
  AppPalette copyWith({
    Color? skyGradientStart,
    Color? skyGradientEnd,
    Color? coinGold,
    Color? streakOrange,
    Color? successGreen,
    Color? cityHillGreen,
  }) {
    return AppPalette(
      skyGradientStart: skyGradientStart ?? this.skyGradientStart,
      skyGradientEnd: skyGradientEnd ?? this.skyGradientEnd,
      coinGold: coinGold ?? this.coinGold,
      streakOrange: streakOrange ?? this.streakOrange,
      successGreen: successGreen ?? this.successGreen,
      cityHillGreen: cityHillGreen ?? this.cityHillGreen,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      skyGradientStart:
          Color.lerp(skyGradientStart, other.skyGradientStart, t)!,
      skyGradientEnd: Color.lerp(skyGradientEnd, other.skyGradientEnd, t)!,
      coinGold: Color.lerp(coinGold, other.coinGold, t)!,
      streakOrange: Color.lerp(streakOrange, other.streakOrange, t)!,
      successGreen: Color.lerp(successGreen, other.successGreen, t)!,
      cityHillGreen: Color.lerp(cityHillGreen, other.cityHillGreen, t)!,
    );
  }
}
