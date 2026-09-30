import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:math_city/app.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/presentation/home/tile_patch.dart';
import 'package:math_city/services/debug_harness.dart';
import 'package:math_city/state/player_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debug-only UX-sweep control port. No-op in release builds.
  if (kDebugMode) {
    await DebugHarness.instance.start();
  }

  // The home screen's first frame must already show the icon's house, or
  // the OS launch screen hands over to a blank sky. Loading the tile art
  // here keeps the launch screen up until it is parsed; nothing else is
  // visible before the intro's first second.
  await Future.wait([
    for (final row in TilePatch.kinds)
      for (final kind in row.toSet())
        SvgAssetLoader('assets/images/tiles/$kind.svg').loadBytes(null),
  ]);

  final db = openAppDatabase();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MathCityApp(),
    ),
  );
}
