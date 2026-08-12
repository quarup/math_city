import 'package:flutter/material.dart';
import 'package:math_city/presentation/splash/splash_screen.dart';
import 'package:math_city/presentation/theme/app_theme.dart';
import 'package:math_city/services/debug_harness.dart';

class MathCityApp extends StatelessWidget {
  const MathCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math City',
      theme: AppTheme.light,
      // Lets the kDebugMode-only UX-sweep harness drive navigation from
      // outside the widget tree. Inert when the harness isn't running.
      navigatorKey: DebugHarness.navigatorKey,
      home: const SplashScreen(),
    );
  }
}
