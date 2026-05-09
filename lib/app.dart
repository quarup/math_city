import 'package:flutter/material.dart';
import 'package:math_city/presentation/home/home_screen.dart';

class MathCityApp extends StatelessWidget {
  const MathCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math City',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
