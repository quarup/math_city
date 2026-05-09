import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/app.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/state/player_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = openAppDatabase();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MathCityApp(),
    ),
  );
}
