import 'package:flutter/material.dart';
import 'package:math_city/presentation/splash/splash_screen.dart';
import 'package:math_city/presentation/theme/app_theme.dart';

class MathCityApp extends StatelessWidget {
  const MathCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math City',
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
