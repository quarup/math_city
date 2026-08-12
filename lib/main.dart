import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/app.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/services/debug_harness.dart';
import 'package:math_city/state/player_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debug-only UX-sweep control port. No-op in release builds.
  if (kDebugMode) {
    await DebugHarness.instance.start();
  }

  final db = openAppDatabase();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MathCityApp(),
    ),
  );
}
