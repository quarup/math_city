import 'dart:async';

import 'package:flutter/material.dart';
import 'package:math_city/presentation/home/home_screen.dart';
import 'package:math_city/presentation/theme/app_palette.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_goHome());
  }

  Future<void> _goHome() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        // Hero animates the logo from center → top over this duration; the
        // page itself uses no transition so the logo is the only thing moving.
        transitionDuration: const Duration(milliseconds: 700),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, a, b) => const HomeScreen(playIntro: true),
        transitionsBuilder: (_, a, b, child) => child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.skyGradientStart, palette.skyGradientEnd],
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/images/math_city_bottom.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),
            Center(
              child: Hero(
                tag: 'math-city-logo',
                child: Image.asset(
                  'assets/images/math_city_logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
