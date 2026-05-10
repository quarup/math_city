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
      // Realign container tones to the teal primary so cards/chips
      // don't drift toward orange-derived peach.
      primaryContainer: const Color(0xFFCFEEE8),
      onPrimaryContainer: const Color(0xFF0E3F39),
      // Light cool-gray surface family — neutral, pairs cleanly with the
      // sky-blue gradients used on the home/splash screens.
      surface: const Color(0xFFF7F8FA),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF0F2F5),
      surfaceContainer: const Color(0xFFE5E9ED),
      surfaceContainerHigh: const Color(0xFFDADFE3),
      surfaceContainerHighest: const Color(0xFFCFD4D8),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: const [AppPalette.light],
      appBarTheme: AppBarTheme(
        // Softer than primary — primary stays saturated for buttons; the
        // AppBar reads as a calmer header.
        backgroundColor: const Color(0xFF6FCBB7),
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      chipTheme: ChipThemeData(
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
