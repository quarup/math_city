import 'package:flutter/material.dart';
import 'package:math_city/presentation/home/home_screen.dart';
import 'package:math_city/presentation/navigation/route_observer.dart';
import 'package:math_city/presentation/theme/app_theme.dart';
import 'package:math_city/presentation/widgets/on_side.dart';
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
      navigatorObservers: [routeObserver],
      // A phone on its side runs without the status bar.
      builder: (context, child) =>
          SystemBarsForOrientation(child: child ?? const SizedBox.shrink()),
      // Cold start: the home screen plays the launch intro from the frame
      // the OS launch screen leaves behind (see HomeScreen.playIntro).
      home: const HomeScreen(playIntro: true),
    );
  }
}
