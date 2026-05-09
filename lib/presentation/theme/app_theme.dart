import 'package:flutter/material.dart';
import 'package:math_city/presentation/theme/app_palette.dart';

/// Central theme for Math City. Pulls accent colors from the logo art so the
/// UI feels of a piece with the splash and home illustrations.
abstract final class AppTheme {
  // Logo-derived accents.
  static const _logoTeal = Color(0xFF2EB5A0); // "MATH" letters
  static const _logoOrange = Color(0xFFF2A33A); // "CITY" letters / gear
  static const _logoYellow = Color(0xFFF0CC30); // gear inner

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _logoOrange,
    ).copyWith(
      primary: _logoTeal,
      secondary: _logoOrange,
      tertiary: _logoYellow,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: const [AppPalette.light],
    );
  }
}
